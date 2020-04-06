/*-
 * The following copyright notice is for some parts of the file.
 * The code parts that are covered by this copyright notice have been
 * taken from the examples for the project 'scpi-parser'
 * (https://github.com/j123b567/scpi-parser) and have been modified to suit
 * the needs of the REDPitayaDAQServer project.
 *
 * Copyright (c) 2012-2013 Jan Breuer,
 *
 * All Rights Reserved
 *
 * Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 * 1. Redistributions of source code must retain the above copyright notice,
 *    this list of conditions and the following disclaimer.
 * 2. Redistributions in binary form must reproduce the above copyright
 *    notice, this list of conditions and the following disclaimer in the
 *    documentation and/or other materials provided with the distribution.
 *
 * THIS SOFTWARE IS PROVIDED BY THE AUTHORS ``AS IS'' AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 * WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
 * DISCLAIMED. IN NO EVENT SHALL THE AUTHORS OR CONTRIBUTORS BE LIABLE
 * FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 * CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 * SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 * BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 * OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 * IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

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
#include "../server/scpi_commands.h"

int numSamplesPerPeriod = 5000;
int numPeriodsPerFrame = 20;
int numSlowDACChan = 0;
int numSlowADCChan = 0;
int numSlowDACFramesEnabled = 0;
int numSlowDACLostSteps = 0;
int enableSlowDAC = 0;
int enableSlowDACAck = true;
int64_t frameSlowDACEnabled = -1;
int64_t startWP = -1;

int64_t channel;

bool initialized = false;
bool rxEnabled = false;
bool buffInitialized = false;
bool acquisitionThreadRunning = false;
bool commThreadRunning = false;

float *slowDACLUT = NULL;
bool slowDACInterpolation = false;
double slowDACRampUpTime = 0.4;
double slowDACFractionRampUp = 0.8;
float *slowADCBuffer = NULL;

pthread_t pSlowDAC;
pthread_t pComm;

int datasockfd;
int clifd;
struct sockaddr_in cliaddr;
socklen_t clilen;

static void getprio( pthread_t id ) {
  int policy;
  struct sched_param param;
  //printf("\t->Thread %ld: ", id);
  if((pthread_getschedparam(id, &policy, &param)) == 0  ) {
    printf("Scheduler: ");
    switch( policy ) {
      case SCHED_OTHER :  printf("SCHED_OTHER; "); break;
      case SCHED_FIFO  :  printf("SCHED_FIFO; ");  break;
      case SCHED_RR    :  printf("SCHED_RR; ");    break;
      default          :  printf("Unknown; ");  break;
    }
    printf("Priority: %d\n", param.sched_priority);
  }
}

size_t SCPI_Write(scpi_t * context, const char * data, size_t len) {
  (void) context;

  if (context->user_context != NULL) {
    int fd = *(int *) (context->user_context);
    return write(fd, data, len);
  }
  return 0;
}

scpi_result_t SCPI_Flush(scpi_t * context) {
  (void) context;

  return SCPI_RES_OK;
}

int SCPI_Error(scpi_t * context, int_fast16_t err) {
  (void) context;
  /* BEEP */
  fprintf(stderr, "**ERROR: %d, \"%s\"\r\n", (int16_t) err, SCPI_ErrorTranslate(err));
  return 0;
}

scpi_result_t SCPI_Control(scpi_t * context, scpi_ctrl_name_t ctrl, scpi_reg_val_t val) {
  (void) context;

  if (SCPI_CTRL_SRQ == ctrl) {
    fprintf(stderr, "**SRQ: 0x%X (%d)\r\n", val, val);
  } else {
    fprintf(stderr, "**CTRL %02x: 0x%X (%d)\r\n", ctrl, val, val);
  }
  return SCPI_RES_OK;
}

scpi_result_t SCPI_Reset(scpi_t * context) {
  (void) context;

  fprintf(stderr, "**Reset\r\n");
  return SCPI_RES_OK;
}

scpi_result_t SCPI_SystemCommTcpipControlQ(scpi_t * context) {
  (void) context;

  return SCPI_RES_ERR;
}

scpi_interface_t scpi_interface = {
  .error = SCPI_Error,
  .write = SCPI_Write,
  .control = SCPI_Control,
  .flush = SCPI_Flush,
  .reset = SCPI_Reset,
};

char scpi_input_buffer[SCPI_INPUT_BUFFER_LENGTH];
scpi_error_t scpi_error_queue_data[SCPI_ERROR_QUEUE_SIZE];

scpi_t scpi_context;

int createServer(int port) {
  int fd;
  int rc;
  int on = 1;
  struct sockaddr_in servaddr;

  /* Configure TCP Server */
  memset(&servaddr, 0, sizeof (servaddr));
  servaddr.sin_family = AF_INET;
  servaddr.sin_addr.s_addr = htonl(INADDR_ANY);
  servaddr.sin_port = htons(port);

  /* Create socket */
  fd = socket(AF_INET, SOCK_STREAM, 0);
  if (fd < 0) {
    perror("socket() failed");
    exit(-1);
  }

  /* Set address reuse enable */
  rc = setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, (char *) &on, sizeof (on));
  if (rc < 0) {
    perror("setsockopt() failed");
    close(fd);
    exit(-1);
  }

  /* Set non blocking */
  rc = ioctl(fd, FIONBIO, (char *) &on);
  if (rc < 0) {
    perror("ioctl() failed");
    close(fd);
    exit(-1);
  }

  /* Bind to socket */
  rc = bind(fd, (struct sockaddr *) &servaddr, sizeof (servaddr));
  if (rc < 0) {
    perror("bind() failed");
    close(fd);
    exit(-1);
  }

  /* Listen on socket */
  listen(fd, 1);
  if (rc < 0) {
    perror("listen() failed");
    close(fd);
    exit(-1);
  }

  return fd;
}

int waitServer(int fd) {
  fd_set fds;
  struct timeval timeout;
  int rc;
  int max_fd;

  FD_ZERO(&fds);
  max_fd = fd;
  FD_SET(fd, &fds);

  timeout.tv_sec = 0;
  timeout.tv_usec = 100;

  rc = select(max_fd + 1, &fds, NULL, NULL, &timeout);

  return rc;
}

uint64_t getNumSamplesPerFrame() {
  return numSamplesPerPeriod * numPeriodsPerFrame;
}

uint64_t getNumSamplesPerSubPeriod() {
  return 4800 / getDecimation();
}

uint64_t getNumSubPeriodsPerPeriod() {
  return numSamplesPerPeriod / getNumSamplesPerSubPeriod();
}

uint64_t getNumSubPeriodsPerFrame() {
  return getNumSubPeriodsPerPeriod() * numPeriodsPerFrame;
}

uint64_t getCurrentFrameTotal() {
  uint64_t currWP = getTotalWritePointer();
  uint64_t currFrame = (currWP - startWP) / getNumSamplesPerFrame();
  return currFrame;
}

uint64_t getCurrentPeriodTotal() {
  return (getTotalWritePointer()-startWP) / numSamplesPerPeriod; 
}



static void writeDataChunked(int fd, const void *buf, size_t count);
static void writeDataChunked(int fd, const void *buf, size_t count) 
{
    int n;
    size_t chunkSize = 100000;
    size_t ptr = 0;
    size_t size;
    while(ptr < count)
    {
      size = MIN(count-ptr, chunkSize);

      n = write(fd, buf + ptr, size);
    
      if (n < 0) 
      {
        printf("Error in sendToHost()\n");
        perror("ERROR writing to socket"); 
      }
      ptr += size;
      usleep(100);
    }
}

void sendDataToHost(uint64_t wpTotal, uint64_t size) {
    uint32_t wp = getInternalWritePointer(wpTotal);
    if(wp+size <= ADC_BUFF_SIZE) 
    {
       writeDataChunked(newdatasockfd, ram + sizeof(uint32_t)*wp, size*sizeof(uint32_t)); 
    } else {                                                                                                  
       uint32_t size1 = ADC_BUFF_SIZE - wp;                                                              
       uint32_t size2 = size - size1;                                                                    
         
       writeDataChunked(newdatasockfd, ram + sizeof(uint32_t)*wp, size1*sizeof(uint32_t));
       writeDataChunked(newdatasockfd, ram, size2*sizeof(uint32_t));
    }                                                                                                         
}  

void sendFramesToHost(int64_t frame, int64_t numFrames) 
{
  int64_t wpTotal = startWP + frame*getNumSamplesPerFrame();
  int64_t size = numFrames*getNumSamplesPerFrame();
  sendDataToHost(wpTotal, size);
}

void sendPeriodsToHost(int64_t frame, int64_t numPeriods) 
{
  int64_t wpTotal = startWP + frame*numSamplesPerPeriod;
  int64_t size = numPeriods*numSamplesPerPeriod;
  sendDataToHost(wpTotal, size);
}

void sendSlowFramesToHost(int64_t frame, int64_t numFrames) {
}

void initBuffer() 
{
  buffInitialized = true;
}

void releaseBuffer() 
{
  buffInitialized = false;
}



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





void* slowDACThread(void* ch) 
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
  int lookahead=32;
  int lookprehead=5;

  printf("Starting slowDAC thread\n");
  getprio(pthread_self());

  // Loop until the acquisition is started
  while(acquisitionThreadRunning) {
    // Reset everything in order to provide a fresh start
    // everytime the acquisition is started
    if(rxEnabled && numSlowDACChan > 0) {
      printf("Start sending...\n");
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

      printf("Trigger received, start sending\n");		

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

            if(enableSlowDAC && !enableSlowDACAck && (wpPDMOld == wpPDM) &&
			    ( currSubSlowDACStep > getNumSubPeriodsPerFrame()-lookprehead-3 )) 
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
	      wpPDMStart = ((currentSubPeriodTotal + numSubPeriodsUntilEnd-3) % PDM_BUFF_SIZE) ;
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

  printf("Slow daq thread finished\n");
}

void joinSlowDACThread()
{
  acquisitionThreadRunning = false;
  rxEnabled = false;
  buffInitialized = false;
  pthread_join(pSlowDAC, NULL);
}

void* communicationThread(void* p) 
{ 
  int clifd = (int)p;
  int rc;
  char smbuffer[10];

  while(true) {
    //printf("Comm thread loop\n");
    if(!commThreadRunning)
    {
      stopTx();
      //setMasterTrigger(OFF);
      joinSlowDACThread();
      break;
    }
    rc = waitServer(clifd);
    if (rc < 0) { /* failed */
      perror("  recv() failed");
      break;
    }
    if (rc == 0) { /* timeout */
      SCPI_Input(&scpi_context, NULL, 0);
    }
    if (rc > 0) { /* something to read */
      rc = recv(clifd, smbuffer, sizeof (smbuffer), 0);
      if (rc < 0) {
        if (errno != EWOULDBLOCK) {
          perror("  recv() failed");
          break;
        }
      } else if (rc == 0) {
        printf("Connection closed\r\n");
        stopTx();
        //setMasterTrigger(OFF);
        joinSlowDACThread();
        commThreadRunning = false;
        break;
      } else {
        SCPI_Input(&scpi_context, smbuffer, rc);
      }
    }
    usleep(1000);
  }
  printf("Comm almost done\n");

  close(clifd);
  if(newdatasockfd > 0) {
    close(newdatasockfd);
    newdatasockfd = 0;
  }

  printf("Comm thread done\n");
  return NULL;
}

void createThreads()
{
  acquisitionThreadRunning = true;
  commThreadRunning = true;

  struct sched_param scheduleSlowDAC;
  pthread_attr_t attrSlowDAC;

  scheduleSlowDAC.sched_priority = 1; //SCHED_RR goes from 1 -99
  pthread_attr_init(&attrSlowDAC);
  pthread_attr_setinheritsched(&attrSlowDAC, PTHREAD_EXPLICIT_SCHED);
  pthread_attr_setschedpolicy(&attrSlowDAC, SCHED_RR);
  if( pthread_attr_setschedparam(&attrSlowDAC, &scheduleSlowDAC) != 0) printf("Failed to set sched param on slow dac thread");
  pthread_create(&pSlowDAC, &attrSlowDAC, slowDACThread, NULL);

  struct sched_param scheduleComm;
  pthread_attr_t attrComm;

  scheduleComm.sched_priority = 1; //SCHED_RR goes from 1 -99
  pthread_attr_init(&attrComm);
  pthread_attr_setinheritsched(&attrComm, PTHREAD_EXPLICIT_SCHED);
  pthread_attr_setschedpolicy(&attrComm, SCHED_RR);
  if( pthread_attr_setschedparam(&attrComm, &scheduleComm) != 0) printf("Failed to set sched param on communication thread");
  pthread_create(&pComm, &attrComm, communicationThread, (void*)clifd);
  //pthread_detach(pComm);

  return;
}

/*
 *
 */
int main(int argc, char** argv) {
  (void) argc;
  (void) argv;
  int rc;

  int listenfd;

  // Start socket for sending the data
  datasockfd = createServer(5026);
  newdatasockfd = 0;

  rxEnabled = false;
  buffInitialized = false;

  // Set priority of this thread
  struct sched_param p;
    p.sched_priority = 99; 
    pthread_t this_thread = pthread_self();
    int ret = pthread_setschedparam(this_thread, SCHED_RR, &p);
    if (ret != 0) {
      printf("Unsuccessful in setting thread realtime prio.\n");
      return 1;     
    }

  getprio(pthread_self());

  /* User_context will be pointer to socket */
  scpi_context.user_context = NULL;

  SCPI_Init(&scpi_context,
      scpi_commands,
      &scpi_interface,
      scpi_units_def,
      SCPI_IDN1, SCPI_IDN2, SCPI_IDN3, SCPI_IDN4,
      scpi_input_buffer, SCPI_INPUT_BUFFER_LENGTH,
      scpi_error_queue_data, SCPI_ERROR_QUEUE_SIZE);

  listenfd = createServer(5025);

  while (true) 
  {
    printf("\033[0m");
    printf("Waiting for new connection\n");
    clilen = sizeof (cliaddr);
    int clifdTmp = accept(listenfd, (struct sockaddr *) &cliaddr, &clilen);

    if (clifdTmp >= 0) 
    {
      printf("Connection established %s\r\n", inet_ntoa(cliaddr.sin_addr));
      clifd = clifdTmp;

      scpi_context.user_context = &clifd;

      // if comm thread still running -> join it
      if(commThreadRunning)
      {
        commThreadRunning = false;
        pthread_join(pComm, NULL);
      }

      if(acquisitionThreadRunning)
      {
        joinSlowDACThread();
      }

      createThreads();
    }
    sleep(1.0);
  }

  // Exit gracefully
  acquisitionThreadRunning = false;
  stopTx();
  //setMasterTrigger(OFF);
  pthread_join(pSlowDAC, NULL);
  releaseBuffer();

  return (EXIT_SUCCESS);
}


