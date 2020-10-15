#include <stdint.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/param.h>
#include <inttypes.h>

#include <stdio.h>
#include <math.h>
#include <string.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/socket.h>
#include <arpa/inet.h>
#include <sys/types.h> 
#include <sys/select.h>
#include <netinet/in.h>
#include <pthread.h>
#include <sched.h>
#include <errno.h>
#include "logger.h"

#include <scpi/scpi.h>

#include "../lib/rp-daq-lib.h"
#include "../server/daq_server_scpi.h"	

static uint64_t wp, wp_old;
static uint64_t wpPDM, wpPDMOld, wpPDMStart;
// Its very important to have a local copy of currentPeriodTotal and currentFrameTotal
// since we do not want to interfere with the values written by the data acquisition thread
static uint64_t currentPeriodTotal;
static uint64_t currentSlowDACPeriodTotal;
static uint64_t currentSlowDACStep;
static uint64_t currentFrameTotal;
static uint64_t oldSlowDACPeriodTotal;

static int64_t frameRampUpStarted=-1; 
static int64_t slowDACPeriodRampUpStarted=-1; 
static int enableSlowDACLocal=0;
static int rampingTotalPeriods=-1;
static int rampingPeriods=-1;
static int rampingTotalFrames=-1;

static int lookahead=110;
static int lookprehead=5;

void initSlowDAC() {
	// Compute Ramping timing
	double bandwidth = 125e6 / getDecimation();
	double period = getNumSamplesPerFrame() / bandwidth;
	rampingTotalFrames = ceil(slowDACRampUpTime / period);
	rampingTotalPeriods = ceil(slowDACRampUpTime / (getNumSamplesPerSlowDACPeriod() / bandwidth) );
	rampingPeriods = ceil(slowDACRampUpTime*slowDACFractionRampUp / ( getNumSamplesPerSlowDACPeriod() / bandwidth) );
	frameRampUpStarted = currentFrameTotal+1;
	int64_t numSlowDACPeriodsUntilEnd = numSlowDACPeriodsPerFrame - currentSlowDACStep;
	slowDACPeriodRampUpStarted = currentSlowDACPeriodTotal + numSlowDACPeriodsUntilEnd;
	
	// Enable and acknowledge SlowDAC
	enableSlowDACLocal = true;
	frameSlowDACEnabled = currentFrameTotal + rampingTotalFrames + 1;
	enableSlowDACAck = true;	
	// 3 in the following line is a magic number
	wpPDMStart = ((currentSlowDACPeriodTotal + numSlowDACPeriodsUntilEnd) % PDM_BUFF_SIZE);

	for(int d=0; d<2; d++) {
		for(int c=0; c<4; c++) {
			setAmplitude(fastDACNextAmplitude[c+4*d],d,c);
		}
	}

	for(int d=0; d<numSlowDACChan; d++) {
		setEnableDACAll(1,d);
	}
}

float getSlowDACVal(int period, int i, 
		int rampingTotalFrames,
		int rampingTotalPeriods,
		int rampingPeriods,
		int frameRampUpStarted,
		int frameSlowDACEnabled,
		int numSlowDACFramesEnabled) {
	float val = 0.0;

	int frame = period / numSlowDACPeriodsPerFrame + frameRampUpStarted;

	// Within regular LUT
	if(frameSlowDACEnabled <= frame < frameSlowDACEnabled + numSlowDACFramesEnabled) {
		val = slowDACLUT[(period % numSlowDACPeriodsPerFrame)*numSlowDACChan+i];
	}

	// Ramp up phase
	if(frameRampUpStarted <= frame < frameSlowDACEnabled) {
		int64_t currRampUpPeriod = period;
		int64_t totalPeriodsInRampUpFrames = numSlowDACPeriodsPerFrame*rampingTotalFrames;
		int64_t stepAfterRampUp = totalPeriodsInRampUpFrames -  
			(rampingTotalPeriods - rampingPeriods);
		if( currRampUpPeriod < totalPeriodsInRampUpFrames - rampingTotalPeriods ) { // Before ramp up
			val = 0.0;
		} else if ( currRampUpPeriod < stepAfterRampUp ) { // Within ramp up
			int64_t currRampUpStep = currRampUpPeriod - 
				(totalPeriodsInRampUpFrames - rampingTotalPeriods);

			val = slowDACLUT[ (stepAfterRampUp % numSlowDACPeriodsPerFrame) *numSlowDACChan+i] *
				(0.9640+tanh(-2.0 + (currRampUpStep / ((float)rampingPeriods-1))*4.0))/1.92806;
		}
	}

	// Ramp down phase
	if(frame >= frameSlowDACEnabled + numSlowDACFramesEnabled) {
		int64_t totalPeriodsFromRampUp = numSlowDACPeriodsPerFrame *
			(rampingTotalFrames+numSlowDACFramesEnabled);
		int64_t currRampDownPeriod = period - totalPeriodsFromRampUp;

		if( currRampDownPeriod > rampingTotalPeriods ) { // After ramp down
			val = 0.0;
		} else if ( currRampDownPeriod > (rampingTotalPeriods - rampingPeriods) ) { // Within ramp down
			int64_t currRampDownStep = currRampDownPeriod - 
				(rampingTotalPeriods - rampingPeriods);

			val = slowDACLUT[ (currRampDownPeriod % numSlowDACPeriodsPerFrame) *numSlowDACChan+i] *
				(0.9640+tanh(-2.0 + ((rampingPeriods-currRampDownStep-1) / ((float)rampingPeriods-1))*4.0))/1.92806;
		}
	}
	return val;
}

void* controlThread(void* ch) { 
	frameRampUpStarted=-1; 
	slowDACPeriodRampUpStarted=-1; 
	enableSlowDACLocal=0;
	rampingTotalPeriods=-1;
	rampingPeriods=-1;
	rampingTotalFrames=-1;
	lookahead=110;
	lookprehead=5;

	LOG_INFO("Starting control thread");
	getprio(pthread_self());

	while(controlThreadRunning) {
		// Reset everything in order to provide a fresh start
		// everytime the acquisition is started
		if(rxEnabled && numSlowDACChan > 0) {
			LOG_INFO("SLOW_DAQ: Start sending...");
			oldSlowDACPeriodTotal = 0;
			err.lostSteps = 0;
			wp_old = startWP;

			/*while(getTriggerStatus() == 0 && rxEnabled)
			  {
			  printf("Waiting for external trigger SlowDAC thread! \n");
			  fflush(stdout);
			  usleep(100);
			  }*/

			//LOG_INFO("SLOW_DAQ: Trigger received, start sending");		

			while(rxEnabled) {
				wpPDMOld = getPDMWritePointer(); 
				wp = getTotalWritePointer();
				wpPDM = getPDMWritePointer(); 
				uint64_t size = wp - wp_old;

				if (size > 0) {
					wp_old = wp;

					currentSlowDACPeriodTotal = wp / getNumSamplesPerSlowDACPeriod();
					currentPeriodTotal = wp / numSamplesPerPeriod;
					currentFrameTotal = wp / getNumSamplesPerFrame();

					if(currentSlowDACPeriodTotal > oldSlowDACPeriodTotal + (lookahead-lookprehead) && 
							numPeriodsPerFrame > 1) {
						LOG_WARN("WARNING: We lost a slow DAC step! oldSlowDACPeriod %lld newSlowDACPeriod %lld size=%lld\n", 
								oldSlowDACPeriodTotal, currentSlowDACPeriodTotal, currentSlowDACPeriodTotal-oldSlowDACPeriodTotal);
						err.lostSteps = 1;
						numSlowDACLostSteps += 1;
					}

					if(currentSlowDACPeriodTotal > oldSlowDACPeriodTotal) {
						currentSlowDACStep = currentSlowDACPeriodTotal % numSlowDACPeriodsPerFrame;

						if(enableSlowDACLocal && numSlowDACFramesEnabled > 0 && frameSlowDACEnabled > 0 
								&& (currentFrameTotal >= numSlowDACFramesEnabled + frameSlowDACEnabled + rampingTotalFrames)) {
							// We now have measured enough frames and switch of the slow DAC
							enableSlowDAC = false;
							stopTx();
							frameSlowDACEnabled = -1;
							frameRampUpStarted = -1;
							slowDACPeriodRampUpStarted = -1;
						}

						if(enableSlowDAC && !enableSlowDACAck && (wpPDMOld == wpPDM) && (
									( currentSlowDACStep > numSlowDACPeriodsPerFrame-lookprehead-1 ) || 
									(numPeriodsPerFrame == 1) )) {
							// we are now lookprehead subperiods or less before the next frame
							initSlowDAC();
						}

						if(!enableSlowDAC) {
							enableSlowDACLocal = false;
						}

						for (int i=0; i< numSlowDACChan; i++) {
							//lookahead
							for(int y=lookprehead; y<lookahead; y++) {
								int64_t localPeriod = (currentSlowDACPeriodTotal - slowDACPeriodRampUpStarted + y); 
								float val = getSlowDACVal(localPeriod, i, 
										rampingTotalFrames, rampingTotalPeriods, rampingPeriods,
										frameRampUpStarted, frameSlowDACEnabled,
										numSlowDACFramesEnabled); 

								//printf("localPEriod %lld curSubPer %lld subPerStarted %lld.\n",localPeriod,currentSubPeriodTotal,subPeriodRampUpStarted); 

								int status = 0;          
								if(enableSlowDACLocal) {
									int64_t currPDMIndex = (wpPDMStart + localPeriod) % PDM_BUFF_SIZE;
									status = setPDMValueVolt(val, i, currPDMIndex);
								}

								if (status != 0) {
									printf("Could not set AO[%d] voltage.\n", i);
								}


								if (enableDACLUT != NULL) {
									int frame = localPeriod / numSlowDACPeriodsPerFrame + frameRampUpStarted;
									// Within regular LUT
									bool val = false;
									if(frameSlowDACEnabled <= frame < frameSlowDACEnabled + numSlowDACFramesEnabled) {
										val = enableDACLUT[(localPeriod % numSlowDACPeriodsPerFrame)*numSlowDACChan+i];
									}
									int64_t currPDMIndex = (wpPDMStart + localPeriod) % PDM_BUFF_SIZE;
									setEnableDAC(val, i, currPDMIndex);
								}
							}
						}
					}
					oldSlowDACPeriodTotal = currentSlowDACPeriodTotal;
				} else {
					//printf("Counter not increased %d %d \n", wp_old, wp);
					usleep(2);
				}
				usleep(20);
			}
		}
		// Wait for the acquisition to start
		usleep(40);
	}

	printf("Control thread finished\n");
}

void joinControlThread()
{
	controlThreadRunning = false;
	rxEnabled = false;
	pthread_join(pControl, NULL);
}

