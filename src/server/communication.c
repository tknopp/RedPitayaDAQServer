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
  LOG_ERROR("**ERROR: %d, \"%s\"\r\n", (int16_t) err, SCPI_ErrorTranslate(err));
  return 0;
}

scpi_result_t SCPI_Control(scpi_t * context, scpi_ctrl_name_t ctrl, scpi_reg_val_t val) {
  (void) context;

  if (SCPI_CTRL_SRQ == ctrl) {
    LOG_ERROR("**SRQ: 0x%X (%d)\r\n", val, val);
  } else {
    LOG_ERROR("**CTRL %02x: 0x%X (%d)\r\n", ctrl, val, val);
  }
  return SCPI_RES_OK;
}

scpi_result_t SCPI_Reset(scpi_t * context) {
  (void) context;

  LOG_ERROR("**Reset\r\n");
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


static void writeDataChunked(int fd, const void *buf, size_t count);
static void writeDataChunked(int fd, const void *buf, size_t count) 
{
    int n;
    size_t chunkSize = 200000;
    size_t ptr = 0;
    size_t size;
    while(ptr < count)
    {
      size = MIN(count-ptr, chunkSize);

      n = write(fd, buf + ptr, size);
    
      if (n < 0) 
      {
        LOG_ERROR("Error in sendToHost()");
      }
      ptr += size;
      usleep(30);
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
      joinControlThread();
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
        LOG_INFO("Connection closed");
        stopTx();
        //setMasterTrigger(OFF);
        joinControlThread();
        commThreadRunning = false;
        break;
      } else {
        SCPI_Input(&scpi_context, smbuffer, rc);
      }
    }
    usleep(1000);
    logger_flush();
  }
  LOG_INFO("Comm almost done");

  close(clifd);
  if(newdatasockfd > 0) {
    close(newdatasockfd);
    newdatasockfd = 0;
  }

  LOG_INFO("Comm thread done");
  return NULL;
}


