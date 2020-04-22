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

#include <scpi/scpi.h>

#include "../lib/rp-daq-lib.h"
#include "../server/daq_server_scpi.h"


float getSlowDACVal(int subPeriod, int i, 
		    int rampingTotalFrames,
		    int rampingTotalPeriods,
		    int rampingPeriods,
		    int frameRampUpStarted,
		    int frameSlowDACEnabled,
		    int numSlowDACFramesEnabled) 
{
  float val = 0.0;

  int period = subPeriod / getNumSubPeriodsPerPeriod();
  int frame = subPeriod / getNumSubPeriodsPerFrame() + frameRampUpStarted;

  // Within regular LUT
  if(frameSlowDACEnabled <= frame < frameSlowDACEnabled - numSlowDACFramesEnabled)
  {
    val = slowDACLUT[(period % numPeriodsPerFrame)*numSlowDACChan+i];
  }

  // Ramp up phase
  if(frameRampUpStarted <= frame < frameSlowDACEnabled) 
  {
    int64_t currRampUpPeriod = period;
    int64_t totalPeriodsInRampUpFrames = numPeriodsPerFrame*rampingTotalFrames;
    int64_t stepAfterRampUp = totalPeriodsInRampUpFrames -  
				                     (rampingTotalPeriods - rampingPeriods);
    if( currRampUpPeriod < totalPeriodsInRampUpFrames - rampingTotalPeriods )
    { // Before ramp up
      val = 0.0;
    } else if ( currRampUpPeriod < stepAfterRampUp )
    { // Within ramp up
      int64_t currRampUpStep = currRampUpPeriod - 
                   (totalPeriodsInRampUpFrames - rampingTotalPeriods);
                
       val = slowDACLUT[ (stepAfterRampUp % numPeriodsPerFrame) *numSlowDACChan+i] *
	(0.9640+tanh(-2.0 + (currRampUpStep / ((float)rampingPeriods-1))*4.0))/1.92806;
     }
   }

   // Ramp down phase
   if(frame >= frameSlowDACEnabled + numSlowDACFramesEnabled) 
   {
      int64_t totalPeriodsFromRampUp = numPeriodsPerFrame*(rampingTotalFrames+numSlowDACFramesEnabled);
      int64_t currRampDownPeriod = period - totalPeriodsFromRampUp;
		
      if( currRampDownPeriod > rampingTotalPeriods )
      { // After ramp down
        val = 0.0;
      } else if ( currRampDownPeriod > (rampingTotalPeriods - rampingPeriods) )
      { // Within ramp down
        int64_t currRampDownStep = currRampDownPeriod - 
	                   (rampingTotalPeriods - rampingPeriods);
                  
	val = slowDACLUT[ (currRampDownPeriod % numPeriodsPerFrame) *numSlowDACChan+i] *
	(0.9640+tanh(-2.0 + ((rampingPeriods-currRampDownStep-1) / ((float)rampingPeriods-1))*4.0))/1.92806;
      }
    }
  return val;
}


void* controlThread(void* ch) 
{ 
  uint32_t wp, wp_old;
  uint64_t wpPDM, wpPDMOld, wpPDMStart;
  // Its very important to have a local copy of currentPeriodTotal and currentFrameTotal
  // since we do not want to interfere with the values written by the data acquisition thread
  int64_t currentPeriodTotal;
  int64_t currentSubPeriodTotal;
  int64_t currentFrameTotal;
  int64_t oldPeriodTotal;
  int64_t oldSubPeriodTotal;
  bool firstCycle;

  int64_t data_read_total;
  int64_t numSamplesPerFrame; 
  int64_t frameRampUpStarted=-1; 
  int64_t subPeriodRampUpStarted=-1; 
  int enableSlowDACLocal=0;
  int rampingTotalPeriods=-1;
  int rampingPeriods=-1;
  int rampingTotalFrames=-1;
  int lookahead=110;
  int lookprehead=5;

  printf("Starting control thread\n");
  getprio(pthread_self());

  while(controlThreadRunning) {
    // Reset everything in order to provide a fresh start
    // everytime the acquisition is started
    if(rxEnabled && numSlowDACChan > 0) {
      printf("SLOW_DAQ: Start sending...\n");
      data_read_total = 0; 
      oldPeriodTotal = 0;
      oldSubPeriodTotal = 0;

      numSamplesPerFrame = numSamplesPerPeriod * numPeriodsPerFrame; 

      wp_old = startWP;

      /*while(getTriggerStatus() == 0 && rxEnabled)
      {
        printf("Waiting for external trigger SlowDAC thread! \n");
        fflush(stdout);
        usleep(100);
      }*/

      printf("SLOW_DAQ: Trigger received, start sending\n");		

      while(rxEnabled) 
      {
	wpPDMOld = getPDMWritePointer(); 
        wp = getWritePointer();
	wpPDM = getPDMWritePointer(); 

        uint32_t size = getWritePointerDistance(wp_old, wp)-1;

        if (size > 0) 
        {
          data_read_total += size;
          wp_old = (wp_old + size) % ADC_BUFF_SIZE;

          currentSubPeriodTotal = data_read_total / getNumSamplesPerSubPeriod();
          currentPeriodTotal = data_read_total / numSamplesPerPeriod;
          currentFrameTotal = data_read_total / numSamplesPerFrame;

          if(currentSubPeriodTotal > oldSubPeriodTotal + (lookahead-lookprehead) && numPeriodsPerFrame > 1) 
          {
            printf("\033[1;31m");
            printf("WARNING: We lost a slow DAC step! oldSubPeriod %lld newSubPeriod %lld size=%lld\n", 
                oldSubPeriodTotal, currentSubPeriodTotal, currentSubPeriodTotal-oldSubPeriodTotal);
            printf("\033[0m");
	    numSlowDACLostSteps += 1;
          }
          if(currentSubPeriodTotal > oldSubPeriodTotal) 
          {
            int currSlowDACStep = currentPeriodTotal % numPeriodsPerFrame;
            int currSubSlowDACStep = currentSubPeriodTotal % getNumSubPeriodsPerFrame();

            if(enableSlowDACLocal && numSlowDACFramesEnabled>0 && frameSlowDACEnabled >0)
	    {
	      if(currentFrameTotal >= numSlowDACFramesEnabled + frameSlowDACEnabled + rampingTotalFrames)
	      { // We now have measured enough frames and switch of the slow DAC
                enableSlowDAC = false;
                for(int i=0; i<4; i++)
		{
		  setPDMAllValuesVolt(0.0, i);
		}
		frameSlowDACEnabled = -1;
		frameRampUpStarted = -1;
		subPeriodRampUpStarted = -1;
	      }
	    }

            if(enableSlowDAC && !enableSlowDACAck && (wpPDMOld == wpPDM) && (
			    ( currSubSlowDACStep > getNumSubPeriodsPerFrame()-lookprehead-3 ) || 
			     (numPeriodsPerFrame == 1) )) 
            {
	      // we are now 10 subperiods or less before the next frame
              double bandwidth = 125e6 / getDecimation();
              double period = numSamplesPerFrame / bandwidth;
              rampingTotalFrames = ceil(slowDACRampUpTime / period);
              rampingTotalPeriods = ceil(slowDACRampUpTime / (numSamplesPerPeriod / bandwidth) );
              rampingPeriods = ceil(slowDACRampUpTime*slowDACFractionRampUp 
			           / (numSamplesPerPeriod / bandwidth) );

              //printf("rampUpFrames = %d, rampUpPeriods = %d \n", rampUpTotalFrames,rampUpPeriods);

	      frameRampUpStarted = currentFrameTotal+1;
	      int64_t numSubPeriodsUntilEnd = getNumSubPeriodsPerFrame() - currSubSlowDACStep;
	      subPeriodRampUpStarted = currentSubPeriodTotal + numSubPeriodsUntilEnd;
	      enableSlowDACLocal = true;
	      frameSlowDACEnabled = currentFrameTotal + rampingTotalFrames + 1;
	      enableSlowDACAck = true;
	      //wpPDMStart = (wpPDM + numSubPeriodsUntilEnd) % PDM_BUFF_SIZE;
	      // 3 in the following line is a magic number
	      wpPDMStart = ((currentSubPeriodTotal + numSubPeriodsUntilEnd) % PDM_BUFF_SIZE) ;
	    }

            if(!enableSlowDAC) 
            {
              enableSlowDACLocal = false;
	    }
            
            for (int i=0; i< numSlowDACChan; i++) 
            {
	      for(int y=lookprehead; y<lookahead; y++) // lookahead
	      {
		int64_t localPeriod = (currentSubPeriodTotal-subPeriodRampUpStarted+y) / getNumSubPeriodsPerPeriod(); 
		//int64_t localPeriod = (currentSubPeriodTotal+y) / getNumSubPeriodsPerPeriod(); 
                float val = getSlowDACVal(localPeriod, i, 
		                 rampingTotalFrames, rampingTotalPeriods, rampingPeriods,
		                 frameRampUpStarted, frameSlowDACEnabled,
		                 numSlowDACFramesEnabled); 

                //printf("Set ff channel %d in cycle %d to value %f totalper %lld.\n", 
                //            i, currFFStep,val, currentPeriodTotal);

                //printf("localPEriod %lld curSubPer %lld subPerStarted %lld.\n",localPeriod,currentSubPeriodTotal,subPeriodRampUpStarted); 
                
		int status = 0;          
                if(enableSlowDACLocal)
	        {
 		  int64_t currSubPeriod = currentSubPeriodTotal - subPeriodRampUpStarted;
	  	  int64_t currPDMIndex = (wpPDMStart + currSubPeriod + y) % PDM_BUFF_SIZE;
                  status = setPDMValueVolt(val, i, currPDMIndex);
	        }

                if (status != 0) 
                {
                  printf("Could not set AO[%d] voltage.\n", i);
                }
	      }
            }
          }
          oldPeriodTotal = currentPeriodTotal;
          oldSubPeriodTotal = currentSubPeriodTotal;
        } else 
        {
          printf("Counter not increased %d %d \n", wp_old, wp);
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

