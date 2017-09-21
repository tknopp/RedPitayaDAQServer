/*
command to compile:
gcc -O3 adc-test-server.c -o adc-test-server
*/

#include <stdint.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>

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

#include "../ConfigTool/rp-instrument-lib.h"

uint64_t numSamplesPerFrame = 0;
uint64_t numFramesInMemoryBuffer = 0;
uint64_t buff_size = 0;

uint32_t adc_buff_size = 1024*1024;

int64_t currentFrameTotal;
int64_t data_read, data_read_total;

uint32_t *buffer = NULL;
float *ffValues = NULL;
float *ffRead = NULL;

int64_t decimation = 16;

float amplitudeTx[] = {0.0, 0.0};
float phaseTx[] = {0.0, 0.0};

bool rxEnabled;
int mmapfd;

struct paramsType {
  int numSamplesPerPeriod;
  int numSamplesPerTxPeriod;
  int numPeriodsPerFrame;
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

struct paramsType params;


uint32_t getWP() { return *((uint32_t *)(adc_sts + 0)); }

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
 
  wp_old = getWP();

    while(rxEnabled)
    {
      wp = getWP();

     uint32_t size = getSizeFromStartEndPos(wp_old, wp)-1;
     //printf("____ %d %d %d \n", size, wp_old, wp);
     if(size > 512*1024) {
       printf("I think we lost a step %d %d %d \n", size, wp_old, wp);
     }

     if (size > 0) {
       if(data_read + size <= buff_size) { 
         read_data(wp_old, size, buffer + data_read);
         
         data_read += size;
         data_read_total += size;
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
       }


       currentFrameTotal = data_read_total / numSamplesPerFrame;
       //currentPeriodTotal = data_read_total / params.numSamplesPerPeriod;
       
       //printf("++++ data_read: %lld data_read_total: %lld total_frame %lld\n", 
       //                    data_read, data_read_total, currentFrameTotal);

       wp_old = wp;
       //oldFrameTotal = currentFrameTotal;
       //oldPeriodTotal = currentPeriodTotal;
   
         
        //usleep(1000);
    }
  } 

}

void updateTx() {
  printf("amplitudeTx New: %f %f \n", amplitudeTx[0], amplitudeTx[1]);
  printf("phaseTx New: %f %f\n", phaseTx[0], phaseTx[1]);
  
  //rp_GenAmp(RP_CH_1, amplitudeTx);
  //rp_GenWaveform(RP_CH_1, RP_WAVEFORM_ARBITRARY);
  //fillTxBuff();
  //rp_GenArbWaveform(RP_CH_1, txBuff, numSamplesInTxBuff);

  setAmplitude(8192 * amplitudeTx[0], 0, 0);
  setAmplitude(8192 * amplitudeTx[1], 1, 0);

  //setAmplitude(0x0f11, 0, 0);

  //setFrequency(125e6 / 4800, 0, 0);
  //setFrequency(125e6 / 4800, 0, 1);
  //setFrequency(125e6 / 4800, 1, 0);
  setFrequency(125e6 / (256*16), 0, 0);
  setFrequency(125e6 / (256*16), 0, 1);
  setFrequency(125e6 / (256*16), 1, 0);
  setPhase((phaseTx[0]+180)/360, 0, 0);
  setPhase((phaseTx[0]+180)/360, 0, 1);
  setPhase((phaseTx[1]+180)/360, 1, 0);
}

void stopTx()
{
  setAmplitude(0, 0, 0);
  setAmplitude(0, 0, 0);
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
  numFramesInMemoryBuffer = 64*1024*1024 / numSamplesPerFrame / 2;
                             
  printf("Num Samples Per Period: %d\n", params.numSamplesPerPeriod);
  printf("Num Samples Per Tx Period: %d\n", params.numSamplesPerTxPeriod);
  printf("Num Periods Per Frame: %d\n", params.numPeriodsPerFrame);
  printf("Num Samples Per Frame: %d\n", numSamplesPerFrame);
  printf("Num Frames In Memory Buffer: %lld\n", numFramesInMemoryBuffer);
  printf("Num FF Channels: %d\n", params.numFFChannels);
  printf("txEnabled: %d\n", params.txEnabled);
  printf("ffEnabled: %d\n", params.ffEnabled);
  printf("isMaster: %d\n", params.isMaster);
  printf("isHighGainChA: %d\n", params.isHighGainChA);
  printf("isHighGainChB: %d\n", params.isHighGainChB);
  
  if(params.ffEnabled) 
  {
    ffValues = (float *)malloc(params.numFFChannels* params.numPeriodsPerFrame * sizeof(float));
    n = read(newsockfd,ffValues,params.numFFChannels* params.numPeriodsPerFrame * sizeof(float));
    for(int i=0;i<params.numFFChannels* params.numPeriodsPerFrame; i++) printf(" %f ",ffValues[i]);
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
    printf("Command: %d\n", command);

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

    rxEnabled = true;
    
    pthread_t pAcq;
    pthread_create(&pAcq, NULL, acquisition_thread, NULL);
    
    pthread_t pCom;
    pthread_create(&pCom, NULL, communication_thread, NULL);
    
    pthread_join(pAcq, NULL);
    printf("Acq Thread finished \n");
    pthread_join(pCom, NULL);
    printf("Com Thread finished \n");

    stopTx();
    //if(params.txEnabled) {
    //  stopTx();
    //}
    //stopRx();

    releaseBuffers();

  }
  return 0;
}  



