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
#include "redpitaya/rp.h"
#include <sys/socket.h> /* for socket(), connect(), send(), and recv() */
#include <arpa/inet.h>  /* for sockaddr_in and inet_addr() */
#include <sys/types.h> 
#include <netinet/in.h>
#include <pthread.h>
#include <sched.h>

#include "../lib/rp-daq-lib.h"

uint64_t numSamplesPerFrame = 0;
uint64_t numFramesInMemoryBuffer = 0;
uint64_t buff_size = 0;

uint32_t adc_buff_size = 2*1024*1024; // 2MSamples = 8 MB

volatile int64_t currentFrameTotal;
volatile int64_t data_read, data_read_total;
volatile int64_t oldFrameTotal;
volatile int64_t channel;

uint32_t *buffer = NULL;
float *ffValues = NULL;
float *ffRead = NULL;

float amplitudeTx[] = {0.0, 0.0};
float phaseTx[] = {0.0, 0.0};

bool rxEnabled;
int mmapfd;

pthread_t pAcq;
 
struct paramsType {
  int decimation;
  int numSamplesPerPeriod;
  int numSamplesPerTxPeriod;
  int numPeriodsPerFrame;
  int numPatches;
  int numFFChannels;
  bool txEnabled;
  bool ffEnabled;
  bool ffLinear;
  bool isMaster; // not used yet
  bool isHighGainChA;
  bool isHighGainChB;
  bool pad1;
  bool pad2;
};

volatile struct paramsType params;

// TK: I don't know why we need the factor of two, but this is how pavels code works
uint32_t getWP() { return (*((uint32_t *)(adc_sts + 0)))*2; }

uint32_t getSizeFromStartEndPos(uint32_t start_pos, uint32_t end_pos) {
    end_pos   = end_pos   % adc_buff_size;
    start_pos = start_pos % adc_buff_size;
    if (end_pos < start_pos)
        end_pos += adc_buff_size;
    return end_pos - start_pos + 1;
}


void read_data(uint32_t wp, uint32_t size, uint32_t* buffer)
{
  if(wp+size <= adc_buff_size) 
  {
    memcpy(buffer, ram + sizeof(uint32_t)*wp, size*sizeof(uint32_t));
  } else
  {
    uint32_t size1 = adc_buff_size - wp;
    uint32_t size2 = size - size1;

    memcpy(buffer, ram + sizeof(uint32_t)*wp, size1*sizeof(uint32_t));
    memcpy(buffer+size1, ram, size2*sizeof(uint32_t));
  }
}

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

  struct sched_param p;
  p.sched_priority = sched_get_priority_max(SCHED_FIFO);
  pthread_t this_thread = pthread_self();
  int ret = pthread_setschedparam(this_thread, SCHED_FIFO, &p);
  if (ret != 0) {
     printf("Unsuccessful in setting thread realtime prio");
     return;     
  }

  wp_old = getWP();

    while(rxEnabled)
    {
      wp = getWP();

     uint32_t size = getSizeFromStartEndPos(wp_old, wp)-1;
     //printf("____ %d %d %d \n", size, wp_old, wp);
     if(size > 512*1024) {
       printf("I think we lost a step %d %d %d \n", size, wp_old, wp);
     }

     // limit size to be read to period length
     size = MIN(size, params.numSamplesPerPeriod);

     if (size > 0) {
       if(data_read + size <= buff_size) { 
         read_data(wp_old, size, buffer + data_read);
         
         data_read += size;
         data_read_total += size;
         wp_old = (wp_old + size) % adc_buff_size;
       } else {
         printf("OVERFLOW %lld %d  %lld\n", data_read, size, buff_size);
         uint32_t size1 = buff_size - data_read; 
         uint32_t size2 = size - size1; 
        
         read_data(wp_old, size1, buffer + data_read);
         data_read = 0;
         data_read_total += size1;
         
         wp_old = (wp_old + size1) % adc_buff_size;
         
         read_data(wp_old, size2, buffer + data_read);
         data_read += size2;
         data_read_total += size2;
         wp_old = (wp_old + size2) % adc_buff_size;
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
  printf("amplitudeTx New: %f %f \n", amplitudeTx[0], amplitudeTx[1]);
  printf("phaseTx New: %f %f\n", phaseTx[0], phaseTx[1]);
  
  //rp_GenAmp(RP_CH_1, amplitudeTx);
  //rp_GenWaveform(RP_CH_1, RP_WAVEFORM_ARBITRARY);
  //fillTxBuff();
  //rp_GenArbWaveform(RP_CH_1, txBuff, numSamplesInTxBuff);

  setAmplitude(8192 * amplitudeTx[0], 0, 0);
  setAmplitude(0, 0, 1);
  setAmplitude(0, 0, 2);
  setAmplitude(0, 0, 3);

  //setAmplitude(0x0f11, 0, 0);

  setFrequency(125e6 / (params.numSamplesPerTxPeriod*params.decimation), 0, 0);
  //setFrequency(125e6 / (params.numSamplesPerTxPeriod*params.decimation), 0, 1);
  //setFrequency(125e6 / (params.numSamplesPerTxPeriod*params.decimation), 1, 0);

  /*setModulusFactor(1, 0, 0);
  setModulusFactor(1, 0, 1);
  setModulusFactor(1, 0, 2);
  setModulusFactor(1, 0, 3);
  */
  setPhase((phaseTx[0]+180)/360, 0, 0);
  setPhase((phaseTx[0]+180)/360, 0, 1);
  setPhase((phaseTx[1]+180)/360, 1, 0);
}

void stopTx()
{
  setAmplitude(0, 0, 0);
  setAmplitude(0, 1, 0);
}

// globals used for network communication
int sockfd, newsockfd, portno;
socklen_t clilen;
char tcp_buffer[256];
struct sockaddr_in serv_addr, cli_addr;
int n;
 
void init_socket()
{
  sockfd = socket(AF_INET, SOCK_STREAM, 0);
  if (sockfd < 0) 
     error("ERROR opening socket");
  int enable = 1;
  if (setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR, &enable, sizeof(int)) < 0)
    error("setsockopt(SO_REUSEADDR) failed");

  bzero((char *) &serv_addr, sizeof(serv_addr));
  portno = 7777;
  serv_addr.sin_family = AF_INET;
  serv_addr.sin_addr.s_addr = INADDR_ANY;
  serv_addr.sin_port = htons(portno);
  if (bind(sockfd, (struct sockaddr *) &serv_addr,
              sizeof(serv_addr)) < 0) 
              error("ERROR on binding");

}

void wait_for_connections()
{
  listen(sockfd,5);
  clilen = sizeof(cli_addr);
  newsockfd = accept(sockfd, 
                 (struct sockaddr *) &cli_addr, 
                 &clilen);
  if (newsockfd < 0) 
        error("ERROR on accept");

  printf("Params type has %d bytes \n", sizeof(struct paramsType));

  n = read(newsockfd,&params,sizeof(struct paramsType));
  if (n < 0) error("ERROR reading from socket");
 
  numSamplesPerFrame = params.numSamplesPerPeriod * params.numPeriodsPerFrame; 
  numFramesInMemoryBuffer = 64*1024*1024 / numSamplesPerFrame;
                             
  setDecimation(params.decimation);
  
  printf("Decimation: %d\n", params.decimation);
  printf("Num Samples Per Period: %d\n", params.numSamplesPerPeriod);
  printf("Num Samples Per Tx Period: %d\n", params.numSamplesPerTxPeriod);
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
  
  if(params.ffEnabled) 
  {
    ffValues = (float *)malloc(params.numFFChannels* params.numPatches * sizeof(float));
    n = read(newsockfd,ffValues,params.numFFChannels* params.numPatches * sizeof(float));
    for(int i=0;i<params.numFFChannels* params.numPatches; i++) printf(" %f ",ffValues[i]);
    printf("\n");
    if (n < 0) error("ERROR reading from socket");
  }
}

void send_data_to_host(int64_t frame, int64_t numframes)
{
  int64_t frameInBuff = frame % numFramesInMemoryBuffer;

  if(numframes+frameInBuff < numFramesInMemoryBuffer)
  {
    n = write(newsockfd, buffer+frameInBuff*numSamplesPerFrame, 
                  numSamplesPerFrame * numframes * sizeof(uint32_t));
    if (n < 0) error("ERROR writing to socket"); 
  } else {
      int64_t frames1 = numFramesInMemoryBuffer - frameInBuff;
      int64_t frames2 = numframes - frames1;
      n = write(newsockfd, buffer+frameInBuff*numSamplesPerFrame,
                  numSamplesPerFrame * frames1 *sizeof(uint32_t));
      if (n < 0) error("ERROR writing to socket");
      n = write(newsockfd, buffer,
                  numSamplesPerFrame * frames2 * sizeof(uint32_t));
      if (n < 0) error("ERROR writing to socket");
  }
}

void updateTx();

void* communication_thread(void* ch)
{
  while(true)
  {
    //printf("SERVER: Wait for new command \n");
    n = read(newsockfd,tcp_buffer,4);
    if (n < 0) error("ERROR reading from socket");

    int command = ((int32_t*)tcp_buffer)[0];
    //printf("Command: %d\n", command);

    switch(command) {
      case 1: // get current frame number
        ((int64_t*)tcp_buffer)[0] = currentFrameTotal-1; // -1 because we want full frames
        //printf(" current frame = %lld \n", ((int64_t*)buffer)[0]);
        n = write(newsockfd, tcp_buffer, sizeof(int64_t));
        if (n < 0) error("ERROR writing to socket");
      break;
      case 2: // get frame data
        n = read(newsockfd,tcp_buffer,255);
        if (n < 0) error("ERROR reading from socket");

        int64_t frame = ((int64_t*)tcp_buffer)[0];
        int64_t numframes = ((int64_t*)tcp_buffer)[1];
        printf("Frame to read: %lld\n", frame);
        send_data_to_host(frame,numframes);
      break;
      case 3: // get new tx params
        n = read(newsockfd,tcp_buffer,4*sizeof(double));
        if (n < 0) error("ERROR reading from socket");
        amplitudeTx[0] = ((double*)tcp_buffer)[0];
        amplitudeTx[1] = ((double*)tcp_buffer)[1];
        phaseTx[0] = ((double*)tcp_buffer)[2];
        phaseTx[1] = ((double*)tcp_buffer)[3];
        printf("New Tx: %f %f %f %f\n", amplitudeTx[0], phaseTx[0], amplitudeTx[1], phaseTx[1]);
        updateTx();
      break;
      case 4: // set slow DAC value
        n = read(newsockfd,tcp_buffer,sizeof(int64_t));
        if (n < 0) error("ERROR writing to socket");
        channel = ((int64_t*)tcp_buffer)[0];
        n = read(newsockfd,tcp_buffer,sizeof(float));
        if (n < 0) error("ERROR writing to socket");
        float val = ((float*)tcp_buffer)[0];
        setPDMNextValueVolt(val, channel);
      break;
      case 5: // get slow ADC value
        n = read(newsockfd,tcp_buffer,sizeof(int64_t));
        if (n < 0) error("ERROR writing to socket");
        channel = ((int64_t*)tcp_buffer)[0];
        ((float*)tcp_buffer)[0] = getXADCValueVolt(channel);
        n = write(newsockfd, tcp_buffer, sizeof(float));
        if (n < 0) error("ERROR writing to socket");
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
       return NULL;
      default: ;
    }
  }

  return NULL;
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

int main ()
{
  init();
  setDACMode(DAC_MODE_RASTERIZED);
  //setDACMode(DAC_MODE_STANDARD);
  setDecimation(32);


  while(true)
  {
    printf("New connection \n");

    init_socket();
    wait_for_connections();

    data_read = 0;
    data_read_total = 0;
        
    initBuffers();
    //if(params.txEnabled) {
    //  startTx();
    //}
    //startRx();
    
    //pthread_t pCom;
    //pthread_create(&pCom, NULL, communication_thread, NULL);
    
    communication_thread(NULL);

    //pthread_join(pCom, NULL);
    //printf("Com Thread finished \n");

    stopTx();
    //if(params.txEnabled) {
    //  stopTx();
    //}
    //stopRx();

    releaseBuffers();

  }
  return 0;
}  



