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
#include "../server/daq_server_scpi.h"

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
bool controlThreadRunning = false;
bool commThreadRunning = false;

float *slowDACLUT = NULL;
bool slowDACInterpolation = false;
double slowDACRampUpTime = 0.4;
double slowDACFractionRampUp = 0.8;
float *slowADCBuffer = NULL;

pthread_t pControl;
pthread_t pComm;

int datasockfd;
int clifd;
struct sockaddr_in cliaddr;
socklen_t clilen;

int newdatasockfd;
struct sockaddr_in newdatasockaddr;
socklen_t newdatasocklen;

char scpi_input_buffer[SCPI_INPUT_BUFFER_LENGTH];
scpi_error_t scpi_error_queue_data[SCPI_ERROR_QUEUE_SIZE];
scpi_t scpi_context;

void getprio( pthread_t id ) {
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

uint64_t getNumSamplesPerFrame() {
  return numSamplesPerPeriod * numPeriodsPerFrame;
}

uint64_t getNumSamplesPerSubPeriod() {
  return getPDMClockDivider() / getDecimation();
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


void createThreads()
{
  controlThreadRunning = true;
  commThreadRunning = true;

  struct sched_param scheduleControl;
  pthread_attr_t attrControl;

  scheduleControl.sched_priority = 1; //SCHED_RR goes from 1 -99
  pthread_attr_init(&attrControl);
  pthread_attr_setinheritsched(&attrControl, PTHREAD_EXPLICIT_SCHED);
  pthread_attr_setschedpolicy(&attrControl, SCHED_RR);
  if( pthread_attr_setschedparam(&attrControl, &scheduleControl) != 0) printf("Failed to set sched param on control thread");
  pthread_create(&pControl, &attrControl, controlThread, NULL);

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

      if(controlThreadRunning)
      {
        joinControlThread();
      }

      createThreads();
    }
    if(commThreadRunning)
    {
      sleep(5.0);
    } else {
      usleep(100000);
    }
  }

  // Exit gracefully
  controlThreadRunning = false;
  stopTx();
  //setMasterTrigger(OFF);
  pthread_join(pControl, NULL);

  return (EXIT_SUCCESS);
}


