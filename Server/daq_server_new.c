/*
command to compile:
gcc -O3 adc-test-server.c -o adc-test-server
*/

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>


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


uint64_t numSamplesPerPeriod = 312;
uint64_t numPeriods = 1;
uint64_t numSamplesPerFrame = 312;
uint64_t numFramesInMemoryBuffer = 100000;
uint64_t buff_size;

int64_t currentFrameTotal;
int64_t data_read, data_read_total;

uint32_t *buffer=NULL;

volatile uint32_t *slcr, *axi_hp0;
volatile void *cfg, *sts, *ram, *buf;

bool rxEnabled;

int mmapfd;

uint32_t getWP() { return *((uint32_t *)(sts + 0)); }

uint32_t adc_buff_size = 1024*1024;

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

/*  printf("Params type has %d bytes \n", sizeof(struct paramsType));

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
  */
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

void init()
{
  printf("Open memory\n");
  if((mmapfd = open("/dev/mem", O_RDWR)) < 0)
  {
    perror("open");
    return 1;
  }

  printf("Map memory\n");
  slcr = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0xF8000000);
  axi_hp0 = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0xF8008000);
  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40000000);
  sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40001000);
  ram = mmap(NULL, 2048*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x1E000000);
  buf = mmap(NULL, 2048*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);

  /* set HP0 bus width to 64 bits */
  printf("Set bus properties\n");
  slcr[2] = 0xDF0D;
  slcr[144] = 0;
  axi_hp0[0] &= ~1;
  axi_hp0[5] &= ~1;
}

void initBuffers()
{
  buff_size = numSamplesPerFrame*numFramesInMemoryBuffer;
  buffer = (uint32_t*)malloc(buff_size * sizeof(uint32_t) );
  memset(buffer,0, buff_size * sizeof(uint32_t));
}

void releaseBuffers()
{
  free(buffer);
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

    //if(params.txEnabled) {
    //  stopTx();
    //}
    //stopRx();

    releaseBuffers();

  }
  return 0;
}  



