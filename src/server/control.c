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

static uint64_t wp;
static uint64_t wpPDMStart;
static uint64_t currentSlowDACStepTotal;
static uint64_t currentSlowDACStep;
static uint64_t currentRotationTotal;
static uint64_t oldSlowDACStepTotal;

static int64_t rotationRampUpStarted=-1; 
static int64_t slowDACStepRampUpStarted=-1; 
static int enableSlowDACLocal=0;
static int rampingTotalSteps=-1;
static int rampingSteps=-1;
static int rampingTotalRotations=-1;

static int lookahead=110;
static int lookprehead=5;


static float getSlowDACVal(int step, int i) {
	float val = 0.0;

	int rotation = step / numSlowDACStepsPerRotation + rotationRampUpStarted;
	
	// Within regular LUT
	if(rotationSlowDACEnabled <= rotation < rotationSlowDACEnabled + numSlowDACRotationsEnabled) {
		val = slowDACLUT[(step % numSlowDACStepsPerRotation)*numSlowDACChan+i];
	}
	// Ramp up phase
	else if(rotationRampUpStarted <= rotation < rotationSlowDACEnabled) {
		int64_t currRampUpStep = step;
		int64_t totalStepsInRampUpRotations = numSlowDACStepsPerRotation*rampingTotalRotations;
		int64_t stepAfterRampUp = totalStepsInRampUpRotations -  
			(rampingTotalSteps - rampingSteps);
		if( currRampUpStep < totalStepsInRampUpRotations - rampingTotalSteps ) { // Before ramp up
			val = 0.0;
		} else if ( currRampUpStep < stepAfterRampUp ) { // Within ramp up
			int64_t currRampUpStep = currRampUpStep - (totalStepsInRampUpRotations - rampingTotalSteps);

			val = slowDACLUT[ (stepAfterRampUp % numSlowDACStepsPerRotation) *numSlowDACChan+i] *
				(0.9640+tanh(-2.0 + (currRampUpStep / ((float)rampingSteps-1))*4.0))/1.92806;
		}
	}
	// Ramp down phase
	else if(rotation >= rotationSlowDACEnabled + numSlowDACRotationsEnabled) {
		int64_t totalStepsFromRampUp = numSlowDACStepsPerRotation *
			(rampingTotalRotations+numSlowDACRotationsEnabled);
		int64_t currRampDownStep = step - totalStepsFromRampUp;

		if( currRampDownStep > rampingTotalSteps ) { // After ramp down
			val = 0.0;
		} else if ( currRampDownStep > (rampingTotalSteps - rampingSteps) ) { // Within ramp down
			int64_t currRampDownStep = currRampDownStep - (rampingTotalSteps - rampingSteps);

			val = slowDACLUT[ (currRampDownStep % numSlowDACStepsPerRotation) *numSlowDACChan+i] *
				(0.9640+tanh(-2.0 + ((rampingSteps-currRampDownStep-1) / ((float)rampingSteps-1))*4.0))/1.92806;
		}
	}
	return val;
}


static void initSlowDAC() {
	// Compute Ramping timing
	double bandwidth = 125e6 / getDecimation();
	double period = (numSamplesPerSlowDACStep * numSlowDACStepsPerRotation) / bandwidth;
	rampingTotalRotations = ceil(slowDACRampUpTime / period);
	rampingTotalSteps = ceil(slowDACRampUpTime / (numSamplesPerSlowDACStep / bandwidth) );
	rampingSteps = ceil(slowDACRampUpTime*slowDACFractionRampUp / ( numSamplesPerSlowDACStep / bandwidth) );
	rotationRampUpStarted = currentRotationTotal + 1;
	int64_t numSlowDACStepsUntilEnd = numSlowDACStepsPerRotation - currentSlowDACStep;
	slowDACStepRampUpStarted = currentSlowDACStepTotal + numSlowDACStepsUntilEnd;
	
	// Enable and acknowledge SlowDAC
	enableSlowDACLocal = true;
	rotationSlowDACEnabled = currentRotationTotal + rampingTotalRotations + 1;
	enableSlowDACAck = true;	
	// 3 in the following line is a magic number
	wpPDMStart = ((currentSlowDACStepTotal + numSlowDACStepsUntilEnd) % PDM_BUFF_SIZE);

	for(int d=0; d<2; d++) {
		for(int c=0; c<4; c++) {
			setAmplitude(fastDACNextAmplitude[c+4*d],d,c);
		}
	}

	for(int d=0; d<numSlowDACChan; d++) {
		setEnableDACAll(1,d);
	}

	//Reset Lost Steps Flag
	err.lostSteps = 0;
}

static void setNextLUTValues() {
	for (int i=0; i< numSlowDACChan; i++) {
		//lookahead
		for(int y=lookprehead; y<lookahead; y++) {
			uint64_t localStep = (currentSlowDACStepTotal - slowDACStepRampUpStarted + y); 
			uint64_t currPDMIndex = (wpPDMStart + localStep) % PDM_BUFF_SIZE;
			float val = getSlowDACVal(localStep, i); 

			int status = setPDMValueVolt(val, i, currPDMIndex);

			if (status != 0) {
				printf("Could not set AO[%d] voltage.\n", i);
			}


			if (enableDACLUT != NULL) {
				int rotation = localStep / numSlowDACStepsPerRotation + rotationRampUpStarted;
				// Within regular LUT
				bool val = false;
				if(rotationSlowDACEnabled <= rotation < rotationSlowDACEnabled + numSlowDACRotationsEnabled) {
					val = enableDACLUT[(localStep % numSlowDACStepsPerRotation)*numSlowDACChan+i];
				}
				setEnableDAC(val, i, currPDMIndex);
			}
		}
	}
}

static void handleLostSlowDACSteps(uint64_t oldSlowDACStep, uint64_t currentSlowDACStep) {
	LOG_WARN("WARNING: We lost a slow DAC step! oldSlowDACStep %lld newSlowDACStep %lld size=%lld\n", 
			oldSlowDACStep, currentSlowDACStep, currentSlowDACStep-oldSlowDACStep);
	err.lostSteps = 1;
	numSlowDACLostSteps += 1;
}

void* controlThread(void* ch) { 
	rotationRampUpStarted=-1; 
	slowDACStepRampUpStarted=-1; 
	enableSlowDACLocal=0;
	rampingTotalSteps=-1;
	rampingSteps=-1;
	rampingTotalRotations=-1;
	lookahead=110;
	lookprehead=5;
	//Performance related variables
	int64_t deltaControl = 0;
	int64_t deltaSet = 0;
	float alpha = 0.7;

	LOG_INFO("Starting control thread");
	getprio(pthread_self());

	while(controlThreadRunning) {
		// Reset everything in order to provide a fresh start
		// everytime the acquisition is started
		//TODO Possibly extend this check to see if DAC is properly setup by client, there where some checks later in the code iirc
		if(rxEnabled && numSlowDACChan > 0) {
			LOG_INFO("SLOW_DAQ: Start sending...");
			oldSlowDACStepTotal = 0;
			err.lostSteps = 0;

			while(rxEnabled) {
				wp = getTotalWritePointer();
				currentSlowDACStepTotal =  wp / numSamplesPerSlowDACStep;

				if (currentSlowDACStepTotal > oldSlowDACStepTotal) {
					currentRotationTotal = wp / (numSamplesPerSlowDACStep * numSlowDACStepsPerRotation);
					currentSlowDACStep = currentSlowDACStepTotal % numSlowDACStepsPerRotation;

					// Handle global-enableSlowDAC
					if (!enableSlowDAC) {
						// TODO Same reset as other case, in an if clause with enableSlowDACLocal == true?
						enableSlowDACLocal = false;
					}
					//TODO currentSlowDACStep > numSlowDACSteps - lookprehead -1, behaviour for numSlowDACStepsPerRotation < 6?
					else if(enableSlowDAC && !enableSlowDACAck && (( currentSlowDACStep > numSlowDACStepsPerRotation-lookprehead-1 ) || (numSlowDACStepsPerRotation == 1)) ) {
						// we are now lookprehead subperiods or less before the next rotation
						initSlowDAC();
						deltaControl = 0;
						deltaSet = 0;
						avgDeltaControl = 0;
						avgDeltaSet = 0;
						minDeltaControl = 0xFF;
						maxDeltaSet = 0x00;
					}
					
					// Handle local-enableSlowDAC
					if (enableSlowDACLocal) {

						if(currentSlowDACStepTotal > oldSlowDACStepTotal + (lookahead-lookprehead) && numSlowDACStepsPerRotation > 1) {
							handleLostSlowDACSteps(oldSlowDACStepTotal, currentSlowDACStepTotal);
						}

						if(numSlowDACRotationsEnabled > 0 && rotationSlowDACEnabled > 0 
								&& (currentRotationTotal >= numSlowDACRotationsEnabled + rotationSlowDACEnabled + rampingTotalRotations)) {
							// We now have measured enough rotations and switch of the slow DAC
							enableSlowDAC = false;
							stopTx();
							rotationSlowDACEnabled = -1;
							rotationRampUpStarted = -1;
							slowDACStepRampUpStarted = -1;
						}
						else {
							setNextLUTValues();
							
							//Compute Perf. data
							deltaControl = oldSlowDACStepTotal + lookahead - currentSlowDACStepTotal;
							deltaSet = (getTotalWritePointer() / numSamplesPerSlowDACStep) - currentSlowDACStepTotal; 
							

							avgDeltaControl = alpha * deltaControl + (1-alpha) * avgDeltaControl;
							avgDeltaSet = alpha * deltaSet + (1-alpha) * avgDeltaSet;
							
							if (deltaControl < minDeltaControl) {
								minDeltaControl = (deltaControl < 0) ? 0 : deltaControl;
							}
							if (deltaSet > maxDeltaSet) {
								maxDeltaSet = (deltaSet > 0xFF) ? 0xFF : deltaSet;
							}

						//	printf("dc: %lld, udc: %lld, ds: %lld\n", deltaControl, avgDeltaControl, deltaSet);	
						}

					}
				}
				oldSlowDACStepTotal = currentSlowDACStepTotal;
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

