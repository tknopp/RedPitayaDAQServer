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
#include <netinet/in.h>
#include <pthread.h>
#include <sched.h>

#include "../lib/rp-daq-lib.h"

uint64_t numSamplesPerFrame = 0;
uint64_t numFramesInMemoryBuffer = 0;
uint64_t buff_size = 0;

volatile int64_t currentFrameTotal;
volatile int64_t data_read, data_read_total;
volatile int64_t oldFrameTotal;
volatile int64_t channel;

uint32_t *buffer = NULL;
float *ffValues = NULL;
float *ffRead = NULL;

float amplitudeTxA[] = {0.0, 0.0, 0.0, 0.0};
float amplitudeTxB[] = {0.0, 0.0, 0.0, 0.0};
float phaseTxA[] = {0.0, 0.0, 0.0, 0.0};
float phaseTxB[] = {0.0, 0.0, 0.0, 0.0};

bool rxEnabled;
int mmapfd;
bool isFirstConnection;

pthread_t pAcq;
 
struct paramsType {
  int decimation;
  int numSamplesPerPeriod;
  int numPeriodsPerFrame;
  int numPatches;
  int numFFChannels;
  int modulus1;
  int modulus2;
  int modulus3;
  int modulus4;
  bool txEnabled;
  bool ffEnabled;
  bool ffLinear;
  bool isMaster; // not used yet
  bool isHighGainChA;
  bool isHighGainChB;
  bool pad1;
  bool pad2;
};

struct paramsType params;

void* acquisition_thread(void* ch)
{ 
  uint32_t wp, wp_old;
  currentFrameTotal = 0;
  data_read_total = 0; 
  data_read = 0; 
  oldFrameTotal = -1;
  int64_t currentPeriodTotal;
  int64_t currentPatchTotal;
  int64_t oldPeriodTotal=-1; 
  int64_t oldPatchTotal=-1; 

  printf("starting acq thread\n");
  setMasterTrigger(MASTER_TRIGGER_ON);

  struct sched_param p;
  p.sched_priority = sched_get_priority_max(SCHED_FIFO);
  pthread_t this_thread = pthread_self();
  int ret = pthread_setschedparam(this_thread, SCHED_FIFO, &p);
  if (ret != 0) {
     printf("Unsuccessful in setting thread realtime prio");
     return NULL;     
  }

  wp_old = 0; 

  while(getTriggerStatus() == 0)
  {
    printf("Waiting for external trigger!"); 
    usleep(40);
  }

  bool firstCycle = true;

  while(rxEnabled)
  {
     wp = getWritePointer();

     uint32_t size = getWritePointerDistance(wp_old, wp)-1;
     //printf("____ %d %d %d \n", size, wp_old, wp);
     if(size > 512*1024) {
       printf("I think we lost a step %d %d %d \n", size, wp_old, wp);
     }

     if(firstCycle) {
       firstCycle = false;
     } else {
       // limit size to be read to period length
       size = MIN(size, params.numSamplesPerPeriod);
     }

     if (size > 0) {
       if(data_read + size <= buff_size) { 
         readADCData(wp_old, size, buffer + data_read);
         
         data_read += size;
         data_read_total += size;
         wp_old = (wp_old + size) % ADC_BUFF_SIZE;
       } else {
         printf("OVERFLOW %lld %d  %lld\n", data_read, size, buff_size);
         uint32_t size1 = buff_size - data_read; 
         uint32_t size2 = size - size1; 
        
         readADCData(wp_old, size1, buffer + data_read);
         data_read = 0;
         data_read_total += size1;
         
         wp_old = (wp_old + size1) % ADC_BUFF_SIZE;
         
         readADCData(wp_old, size2, buffer + data_read);
         data_read += size2;
         data_read_total += size2;
         wp_old = (wp_old + size2) % ADC_BUFF_SIZE;
       }


       int64_t numSamplesPerPatch = numSamplesPerFrame / params.numPatches;
       currentFrameTotal = data_read_total / numSamplesPerFrame;
       currentPeriodTotal = data_read_total / (params.numSamplesPerPeriod);
       currentPatchTotal = data_read_total / numSamplesPerPatch;
       
       //printf("++++ data_read: %lld data_read_total: %lld total_frame %lld\n", 
       //                    data_read, data_read_total, currentFrameTotal);

       if (params.ffEnabled) {
         //  printf("!!! oldPeriod %lld newPeriod %lld size=%d\n", 
         //          oldPeriodTotal, currentPeriodTotal, size);
         if(currentPatchTotal > oldPatchTotal + 1) {
           printf("WARNING: We lost an ff step! oldFr %lld newFr %lld size=%d\n", 
                   oldPatchTotal, currentPatchTotal, size);
         }
         if(true) { //currentPatchTotal > oldPatchTotal || params.ffLinear) {
           float factor = ((float)data_read_total - currentPatchTotal*numSamplesPerPatch )/
                         numSamplesPerPatch;
           int currFFStep = currentPatchTotal % params.numPatches;
           //printf("++++ currFrame: %lld\n",  currFFStep);
           for (int i=0; i< params.numFFChannels; i++) {
             float val;
             if(params.ffLinear) {
               val = (1-factor)*ffValues[currFFStep*params.numFFChannels+i] +
                     factor*ffValues[((currFFStep+1) % params.numPatches)*params.numFFChannels+i];
             } else {
               val = ffValues[currFFStep*params.numFFChannels+i];
             }
             //printf("Set ff channel %d in cycle %d to value %f totalper %lld.\n", 
             //            i, currFFStep,val, currentPeriodTotal);
             
             // For debugging it can be very helpful to write something into the ADC buffer
             // buffer[data_read-1] = 7000;
             int status = setPDMNextValueVolt(val, 0);             
             status = setPDMNextValueVolt(0.0, 1);             
             status = setPDMNextValueVolt(0.0, 2);             
             status = setPDMNextValueVolt(0.0, 3);             

             //uint64_t curr = getPDMRegisterValue();

             //uint64_t st;
             //do {
             //    st = getPDMStatusValue();
              //   printf("____ %"PRIu64"  %"PRIu64"  \n",curr,st);
             //}
             //while(st != curr);
 
             if (status != 0) {
                 printf("Could not set AO[%d] voltage.\n", i);
             }
           }
         }
       }

       oldFrameTotal = currentFrameTotal;
       oldPeriodTotal = currentPeriodTotal;
       oldPatchTotal = currentPatchTotal;
    } else {
      //printf("Counter not increased %d %d \n", wp_old, wp);
      usleep(40);    
    }
  } 
  printf("acq thread finished\n");
}

void updateTx() {
  printf("Set AmplitudeTxA: %f %f %f %f \n", amplitudeTxA[0], amplitudeTxA[1], amplitudeTxA[2],amplitudeTxA[3]);
  printf("Set AmplitudeTxB: %f %f %f %f \n", amplitudeTxB[0], amplitudeTxB[1], amplitudeTxB[2],amplitudeTxB[3]);
  printf("Set PhaseTxA: %f %f %f %f\n", phaseTxA[0], phaseTxA[1], phaseTxA[2], phaseTxA[3]);
  printf("Set PhaseTxB: %f %f %f %f\n", phaseTxB[0], phaseTxB[1], phaseTxB[2], phaseTxB[3]);

  for(int d=0; d<4; d++) {
    setAmplitude(8192 * amplitudeTxA[d], 0, d);
    setAmplitude(8192 * amplitudeTxB[d], 1, d);
    
    setPhase((phaseTxA[d]+180)/360, 0, d);
    setPhase((phaseTxB[d]+180)/360, 1, d);
  }

  
}

void stopTx()
{
  setAmplitude(0, 0, 0);
  setAmplitude(0, 1, 0);
}

// globals used for network communication
int sockfd, newsockfd;

void init_daq();

void wait_for_connections()
{
  int n;
  struct sockaddr_in cli_addr;
  socklen_t clilen;
  listen(sockfd,5);
  clilen = sizeof(cli_addr);
  newsockfd = accept(sockfd, 
                 (struct sockaddr *) &cli_addr, 
                 &clilen);
  if (newsockfd < 0) 
    perror("ERROR on accept");

  printf("Params type has %d bytes \n", sizeof(struct paramsType));

  n = read(newsockfd,&params,sizeof(struct paramsType));
  if (n < 0) perror("ERROR reading from socket");
 
  numSamplesPerFrame = params.numSamplesPerPeriod * params.numPeriodsPerFrame; 
  numFramesInMemoryBuffer = 64*1024*1024 / numSamplesPerFrame;
                             
  init_daq();

  reconfigureDACModulus(params.modulus1, 0, 0);
  reconfigureDACModulus(params.modulus2, 0, 1);
  reconfigureDACModulus(params.modulus3, 0, 2);
  reconfigureDACModulus(params.modulus4, 0, 3);
  reconfigureDACModulus(params.modulus1, 1, 0);
  reconfigureDACModulus(params.modulus2, 1, 1);
  reconfigureDACModulus(params.modulus3, 1, 2);
  reconfigureDACModulus(params.modulus4, 1, 3);
 
  for(int d=0; d<4; d++) {
    setModulusFactor(1, 0, d);
    setModulusFactor(1, 1, d);
  }
 
  printf("Decimation: %d\n", params.decimation);
  printf("Num Samples Per Period: %d\n", params.numSamplesPerPeriod);
  printf("Num Periods Per Frame: %d\n", params.numPeriodsPerFrame);
  printf("Num Patches: %d\n", params.numPatches);
  printf("Num Samples Per Frame: %lld\n", numSamplesPerFrame);
  printf("Num Frames In Memory Buffer: %lld\n", numFramesInMemoryBuffer);
  printf("Num FF Channels: %d\n", params.numFFChannels);
  printf("txEnabled: %d\n", params.txEnabled);
  printf("ffEnabled: %d\n", params.ffEnabled);
  printf("isMaster: %d\n", params.isMaster);
  printf("isHighGainChA: %d\n", params.isHighGainChA);
  printf("isHighGainChB: %d\n", params.isHighGainChB);
 
  printf("getPeripheralAResetN(): %d\n", getPeripheralAResetN());
  printf("getFourierSynthAResetN(): %d\n", getFourierSynthAResetN());
  printf("getPDMAResetN(): %d\n", getPDMAResetN());
  printf("getWriteToRAMAResetN(): %d\n", getWriteToRAMAResetN());
  printf("getXADCAResetN(): %d\n", getXADCAResetN());
  printf("getTriggerStatus(): %d\n", getTriggerStatus());
  printf("getWatchdogStatus(): %d\n", getWatchdogStatus());
  printf("getInstantResetStatus(): %d\n", getInstantResetStatus());
  printf("getDecimation(): %d", getDecimation());
 
  if(params.ffEnabled) 
  {
    ffValues = (float *)malloc(params.numFFChannels* params.numPatches * sizeof(float));
    n = read(newsockfd,ffValues,params.numFFChannels* params.numPatches * sizeof(float));
    for(int i=0;i<params.numFFChannels* params.numPatches; i++) printf(" %f ",ffValues[i]);
    printf("\n");
    if (n < 0) perror("ERROR reading from socket");
  }
}

void send_data_to_host(int64_t frame, int64_t numframes)
{
  int n;
  int64_t frameInBuff = frame % numFramesInMemoryBuffer;

  if(numframes+frameInBuff < numFramesInMemoryBuffer)
  {
    n = write(newsockfd, buffer+frameInBuff*numSamplesPerFrame, 
                  numSamplesPerFrame * numframes * sizeof(uint32_t));
    if (n < 0) perror("ERROR writing to socket"); 
  } else {
      int64_t frames1 = numFramesInMemoryBuffer - frameInBuff;
      int64_t frames2 = numframes - frames1;
      n = write(newsockfd, buffer+frameInBuff*numSamplesPerFrame,
                  numSamplesPerFrame * frames1 *sizeof(uint32_t));
      if (n < 0) perror("ERROR writing to socket");
      n = write(newsockfd, buffer,
                  numSamplesPerFrame * frames2 * sizeof(uint32_t));
      if (n < 0) perror("ERROR writing to socket");
  }
}

void updateTx();

void communication_thread()
{
  int n;
  char tcp_buffer[256];
  while(true)
  {
    //printf("SERVER: Wait for new command \n");
    n = read(newsockfd,tcp_buffer,4);
    if (n < 0) perror("ERROR reading from socket");

    int command = ((int32_t*)tcp_buffer)[0];
    //printf("Command: %d\n", command);

    switch(command) {
      case 1: // get current frame number
        ((int64_t*)tcp_buffer)[0] = currentFrameTotal-1; // -1 because we want full frames
        //printf(" current frame = %lld \n", ((int64_t*)buffer)[0]);
        n = write(newsockfd, tcp_buffer, sizeof(int64_t));
        if (n < 0) perror("ERROR writing to socket");
      break;
      case 2: // get frame data
        n = read(newsockfd,tcp_buffer,255);
        if (n < 0) perror("ERROR reading from socket");

        int64_t frame = ((int64_t*)tcp_buffer)[0];
        int64_t numframes = ((int64_t*)tcp_buffer)[1];
        printf("Frame to read: %lld\n", frame);
        send_data_to_host(frame,numframes);
      break;
      case 3: // get new tx params
        n = read(newsockfd,amplitudeTxA,4*sizeof(float));
        if (n < 0) perror("ERROR reading from socket");
        n = read(newsockfd,amplitudeTxB,4*sizeof(float));
        if (n < 0) perror("ERROR reading from socket");
        n = read(newsockfd,phaseTxA,4*sizeof(float));
        if (n < 0) perror("ERROR reading from socket");
        n = read(newsockfd,phaseTxB,4*sizeof(float));
        if (n < 0) perror("ERROR reading from socket");
        
        updateTx();
      break;
      case 4: // set slow DAC value
        n = read(newsockfd,tcp_buffer,sizeof(int64_t));
        if (n < 0) perror("ERROR writing to socket");
        channel = ((int64_t*)tcp_buffer)[0];
        n = read(newsockfd,tcp_buffer,sizeof(float));
        if (n < 0) perror("ERROR writing to socket");
        float val = ((float*)tcp_buffer)[0];
        setPDMNextValueVolt(val, channel);
      break;
      case 5: // get slow ADC value
        n = read(newsockfd,tcp_buffer,sizeof(int64_t));
        if (n < 0) perror("ERROR writing to socket");
        channel = ((int64_t*)tcp_buffer)[0];
        ((float*)tcp_buffer)[0] = getXADCValueVolt(channel);
        n = write(newsockfd, tcp_buffer, sizeof(float));
        if (n < 0) perror("ERROR writing to socket");
      break;
      case 6: // start acquisition
        data_read = 0;
        data_read_total = 0;
        rxEnabled = true;
        pthread_create(&pAcq, NULL, acquisition_thread, NULL);
      break;
      case 7: // stop acquisition
        rxEnabled = false;
        pthread_join(pAcq, NULL);
        printf("Acq Thread finished \n"); 
      break;
      case 9: 
       close(newsockfd);
       close(sockfd);
       rxEnabled = false;
       return;
      default: ;
    }
  }

  return;
}


static void initBuffers()
{
  buff_size = numSamplesPerFrame*numFramesInMemoryBuffer;
  buffer = (uint32_t*)malloc(buff_size * sizeof(uint32_t) );
  memset(buffer,0, buff_size * sizeof(uint32_t));
}

static void releaseBuffers()
{
  free(buffer);
  if(ffValues != NULL)
  {
    free(ffValues);
  }
}

void init_daq()
{
  if(isFirstConnection)
  {
    if(params.isMaster) {
      setMaster();
    } else {
      setSlave();
    }
    init();
    setDACMode(DAC_MODE_RASTERIZED);
    isFirstConnection = false;
    setWatchdogMode(WATCHDOG_OFF);  
  }
  setDecimation(params.decimation);  

  setMasterTrigger(MASTER_TRIGGER_OFF);
  setRAMWriterMode(ADC_MODE_TRIGGERED);
}

int main ()
{
  isFirstConnection = true;

  while(true)
  {
    printf("New connection \n");

    sockfd = initSocket(7777);
    wait_for_connections();

    data_read = 0;
    data_read_total = 0;
        
    initBuffers();

    communication_thread();

    stopTx();

    releaseBuffers();
  }
  return 0;
}  



