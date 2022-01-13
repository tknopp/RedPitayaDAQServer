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

#define _GNU_SOURCE
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
#include <sched.h>
#include <errno.h>
#include <signal.h>
#include <time.h>
#include "logger.h"

#include <scpi/scpi.h>

#include "../lib/rp-daq-lib.h"
#include "../server/daq_server_scpi.h"


sequenceState_t seqState;
sequenceNode_t *head = NULL; 
sequenceNode_t *tail = NULL;
sequenceNode_t *configNode = NULL;

double rampUpTime;
double rampUpFraction;
double rampDownTime;
double rampDownFraction;
int numSamplesPerStep = 0; 
int numSlowDACStepsPerSequence = 20;
int numSlowDACChan = 0;
int numSlowADCChan = 0;
int numSlowDACSequencesEnabled = 0;
int numSlowDACLostSteps = 0;

int64_t channel;

bool initialized = false;
bool rxEnabled = false;
bool buffInitialized = false;
bool controlThreadRunning = false;
bool commThreadRunning = false;

bool slowDACInterpolation = false;
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

struct status err;

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

uint8_t getStatus() {
	return getErrorStatus() | rxEnabled << 3 | seqState == RUNNING << 4; 
}

uint8_t getErrorStatus() {
	return err.overwritten | err.corrupted << 1 | err.lostSteps << 2;
}

uint8_t getOverwrittenStatus() {
	return err.overwritten;
}

void clearOverwrittenStatus() {
	err.overwritten = 0;
}

uint8_t getCorruptedStatus() {
	return err.corrupted;
}

void clearCorruptedStatus() {
	err.corrupted = 0;
}

uint8_t getLostStepsStatus() {
	return err.lostSteps;
}

void clearLostStepsStatus() {
	err.lostSteps = 0;
}

void createThreads() {
	controlThreadRunning = true;
	commThreadRunning = true;

	struct sched_param scheduleControl;
	pthread_attr_t attrControl;

	scheduleControl.sched_priority = 5; //SCHED_RR goes from 1 -99
	pthread_attr_init(&attrControl);
	pthread_attr_setinheritsched(&attrControl, PTHREAD_EXPLICIT_SCHED);
	pthread_attr_setschedpolicy(&attrControl, SCHED_FIFO);
	if( pthread_attr_setschedparam(&attrControl, &scheduleControl) != 0)
		LOG_INFO("Failed to set sched param on control thread");
	pthread_create(&pControl, &attrControl, controlThread, NULL);
	//pthread_create(&pControl, NULL, controlThread, NULL);

	struct sched_param scheduleComm;
	pthread_attr_t attrComm;

	scheduleComm.sched_priority = 5; //SCHED_RR goes from 1 -99
	pthread_attr_init(&attrComm);
	pthread_attr_setinheritsched(&attrComm, PTHREAD_EXPLICIT_SCHED);
	pthread_attr_setschedpolicy(&attrComm, SCHED_FIFO);
	if( pthread_attr_setschedparam(&attrComm, &scheduleComm) != 0) 
		LOG_INFO("Failed to set sched param on communication thread");
	pthread_create(&pComm, &attrComm, communicationThread, (void*)clifd);
	//pthread_create(&pComm, NULL, communicationThread, (void*)clifd);

	//pthread_detach(pComm);

	cpu_set_t mask;
	CPU_ZERO(&mask);
	CPU_SET(1, &mask);
	if (pthread_setaffinity_np(pComm, sizeof(mask), &mask))
		printf("CPU Mask Comm failed\n");
	CPU_ZERO(&mask);
	CPU_SET(0, &mask);
	if (pthread_setaffinity_np(pControl, sizeof(mask), &mask))
		printf("CPU Mask Control failed\n");


	return;
}

FILE* getLogFile() {
	return fopen("/media/mmcblk0p1/apps/RedPitayaDAQServer/log.txt", "rb");
}

/*
 *
 */
int main(int argc, char** argv) {

	logger_initFileLogger("/media/mmcblk0p1/apps/RedPitayaDAQServer/log.txt", 1024 * 1024 * 1024, 5);
	logger_setLevel(LogLevel_DEBUG);
	logger_autoFlush(1);

	LOG_INFO("Starting RedPitayaDAQServer");

	logger_flush();

	int rc;
	int listenfd;

	// Start socket for sending the data
	datasockfd = createServer(5026);
	newdatasockfd = 0;

	rxEnabled = false;
	buffInitialized = false;

	// Set priority of this thread
	struct sched_param p;
	p.sched_priority = 20;
	pthread_t this_thread = pthread_self();
	int ret = pthread_setschedparam(this_thread, SCHED_RR, &p);
	if (ret != 0) {
		LOG_INFO("Unsuccessful in setting thread realtime prio.\n");
		return 1;     
	}

	// Ignore SIGPIPE signal to ensure that process is not silently terminated
	sigaction(SIGPIPE, &(struct sigaction){SIG_IGN}, NULL);


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

	cleanUpSequenceList();

	while (true) {
		logger_flush();
		printf("\033[0m");
		clilen = sizeof (cliaddr);
		int clifdTmp = accept(listenfd, (struct sockaddr *) &cliaddr, &clilen);
		if (clifdTmp >= 0) {
			LOG_INFO("Connection established %s\r\n", inet_ntoa(cliaddr.sin_addr));
			clifd = clifdTmp;

			scpi_context.user_context = &clifd;

			// if comm thread still running -> join it
			if(commThreadRunning) {
				commThreadRunning = false;
				pthread_join(pComm, NULL);
			}

			if(controlThreadRunning) {
				joinControlThread();
			}
			
			if(!initialized) {
				init();
				initialized = true;
			}

			newdatasocklen = sizeof(newdatasockaddr);
			newdatasockfd = accept(datasockfd, (struct sockaddr *) &newdatasockaddr, &newdatasocklen);

			if (newdatasockfd < 0) {
				printf("Error accepting data socket: %s\n", strerror(errno));
				close(clifdTmp);
			}
			else {
				createThreads();
				printf("Created threads\n");
			}
		}
		
	}

	// Exit gracefully
	controlThreadRunning = false;
	stopTx();
	//setMasterTrigger(OFF);
	pthread_join(pControl, NULL);

	return (EXIT_SUCCESS);
}
