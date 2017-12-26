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
uint64_t numSamplesPerFrame = -1;
uint64_t numFramesInMemoryBuffer = -1;
uint64_t numPeriodsInMemoryBuffer = -1;
uint64_t buff_size = 0;

volatile int64_t currentFrameTotal;
volatile int64_t currentPeriodTotal;
volatile int64_t data_read, data_read_total;
volatile int64_t channel;

uint32_t *buffer = NULL;
bool rxEnabled = false;
bool acquisitionThreadRunning = false;

float *slowDACLUT = NULL;

pthread_t pAcq;
pthread_t pSlowDAC;

int datasockfd;

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

	timeout.tv_sec = 5;
	timeout.tv_usec = 0;

	rc = select(max_fd + 1, &fds, NULL, NULL, &timeout);

	return rc;
}

void* acquisitionThread(void* ch) { 
	uint32_t wp, wp_old;
	bool firstCycle;

	printf("Starting acquisition thread\n");

	// Set priority of this thread
	/*struct sched_param p;
	p.sched_priority = sched_get_priority_max(SCHED_FIFO);
	pthread_t this_thread = pthread_self();
	int ret = pthread_setschedparam(this_thread, SCHED_FIFO, &p);
	if (ret != 0) {
		printf("Unsuccessful in setting thread realtime prio.\n");
		return NULL;     
	}*/

	// Loop until the acquisition is started
	while(acquisitionThreadRunning) {
		// Reset everything in order to provide a fresh start
		// everytime the acquisition is started
		if(rxEnabled) {
			printf("Starting acquisition...\n");
			currentFrameTotal = 0;
			currentPeriodTotal = 0;
			data_read_total = 0; 
			data_read = 0; 

			numSamplesPerFrame = numSamplesPerPeriod * numPeriodsPerFrame; 
			numFramesInMemoryBuffer = 16*1024*1024 / numSamplesPerFrame;
			numPeriodsInMemoryBuffer = numFramesInMemoryBuffer*numPeriodsPerFrame;
			//printf("Release old buffer\n");
			releaseBuffer();
			printf("Initializing new buffer...\n");
			initBuffer();
			printf("New buffer initialized\n");
			
			wp_old = 0;
			firstCycle = true;

			while(getTriggerStatus() == 0 && rxEnabled)
            {
				printf("Waiting for external trigger! \n");
                fflush(stdout);
                usleep(100);
            }

			printf("Trigger received, start reading\n");		
		
			while(rxEnabled) {
				//printf("Get write pointer\n");
				wp = getWritePointer();

				//printf("Get write pointer distance\n");
				uint32_t size = getWritePointerDistance(wp_old, wp)-1;
				//printf("____ %d %d %d \n", size, wp_old, wp);
				if(size > 512*1024) {
					printf("I think we lost a step %d %d %d \n", size, wp_old, wp);
				}

				if(firstCycle) {
					firstCycle = false;
				} else {
					// Limit size to be read to period length
					size = MIN(size, numSamplesPerPeriod);
				}

				if (size > 0) {
					if(data_read + size <= buff_size) { 
						//printf("Read ADC data\n");
						readADCData(wp_old, size, buffer + data_read);

						//printf("Update position information\n");
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

					currentFrameTotal = data_read_total / numSamplesPerFrame;
					currentPeriodTotal = data_read_total / (numSamplesPerPeriod);

					//				printf("++++ data_read: %lld data_read_total: %lld total_frame %lld\n", 
					//				                    data_read, data_read_total, currentFrameTotal);
					//                                fflush(stdout);

				} else {
					//printf("Counter not increased %d %d \n", wp_old, wp);
					usleep(10);
				}
			}
		}
		// Wait for the acquisition to start
		usleep(10);
	}

	printf("Acquisition thread finished\n");
}

void sendFramesToHost(int64_t frame, int64_t numFrames) {
	int n;
	int64_t frameInBuff = frame % numFramesInMemoryBuffer;

	if(numFrames+frameInBuff < numFramesInMemoryBuffer) {
		n = write(newdatasockfd, buffer+frameInBuff*numSamplesPerFrame, 
				numSamplesPerFrame * numFrames * sizeof(uint32_t));

		if (n < 0) {
			printf("Error in sendToHost()\n");
			perror("ERROR writing to socket"); 
		}
	} else {
		int64_t frames1 = numFramesInMemoryBuffer - frameInBuff;
		int64_t frames2 = numFrames - frames1;
		n = write(newdatasockfd, buffer+frameInBuff*numSamplesPerFrame,
				numSamplesPerFrame * frames1 *sizeof(uint32_t));

		if (n < 0) {
			printf("Error in sendToHost() (else part 1)\n");
			perror("ERROR writing to socket");
		}

		n = write(newdatasockfd, buffer,
				numSamplesPerFrame * frames2 * sizeof(uint32_t));

		if (n < 0) {
			printf("Error in sendToHost() (else part 2)\n");
			perror("ERROR writing to socket");
		}
	}
}

void sendPeriodsToHost(int64_t period, int64_t numPeriods) {
	int n;
	int64_t periodInBuff = period % numPeriodsInMemoryBuffer;

	if(numPeriods+periodInBuff < numPeriodsInMemoryBuffer) {
		n = write(newdatasockfd, buffer+periodInBuff*numSamplesPerPeriod, 
				numSamplesPerPeriod * numPeriods * sizeof(uint32_t));

		if (n < 0) {
			printf("Error in sendToHost()\n");
			perror("ERROR writing to socket"); 
		}
	} else {
		int64_t period1 = numPeriodsInMemoryBuffer - periodInBuff;
		int64_t period2 = numPeriods - period1;
		n = write(newdatasockfd, buffer+periodInBuff*numSamplesPerPeriod,
				numSamplesPerPeriod * period1 *sizeof(uint32_t));

		if (n < 0) {
			printf("Error in sendToHost() (else part 1)\n");
			perror("ERROR writing to socket");
		}

		n = write(newdatasockfd, buffer,
				numSamplesPerPeriod * period2 * sizeof(uint32_t));

		if (n < 0) {
			printf("Error in sendToHost() (else part 2)\n");
			perror("ERROR writing to socket");
		}
	}
}

void initBuffer() {
	buff_size = numSamplesPerFrame*numFramesInMemoryBuffer;
	buffer = (uint32_t*)malloc(buff_size * sizeof(uint32_t));
	memset(buffer, 0, buff_size * sizeof(uint32_t));
}

void releaseBuffer() {
	free(buffer);
}

void* slowDACThread(void* ch) { 

	uint32_t wp, wp_old;
	int64_t currentPeriodTotal;
	int64_t oldPeriodTotal;
	bool firstCycle;

	int64_t data_read_total;
	int64_t numSamplesPerFrame; 

	printf("Starting slowDAC thread\n");

	// Set priority of this thread
	struct sched_param p;
	p.sched_priority = sched_get_priority_max(SCHED_FIFO);
	pthread_t this_thread = pthread_self();
	int ret = pthread_setschedparam(this_thread, SCHED_FIFO, &p);
	if (ret != 0) {
		printf("Unsuccessful in setting thread realtime prio.\n");
		return NULL;     
	}

	// Loop until the acquisition is started
	while(acquisitionThreadRunning) {
		// Reset everything in order to provide a fresh start
		// everytime the acquisition is started
		if(rxEnabled && numSlowDACChan > 0) {
			printf("Starting acquisition...\n");
			data_read_total = 0; 
			oldPeriodTotal = -1;

			numSamplesPerFrame = numSamplesPerPeriod * numPeriodsPerFrame; 
			
			wp_old = 0;
            while(getTriggerStatus() == 0 && rxEnabled)
            {
              	printf("Waiting for external trigger SlowDAC thread! \n");
                fflush(stdout);
                usleep(100);
            }

			printf("Trigger received, start sending\n");		
			
			while(rxEnabled) {
				wp = getWritePointer();

				uint32_t size = getWritePointerDistance(wp_old, wp)-1;

				if (size > 0) {
					data_read_total += size;
			    	wp_old = (wp_old + size) % ADC_BUFF_SIZE;
				
					currentFrameTotal = data_read_total / numSamplesPerFrame;
					currentPeriodTotal = data_read_total / (numSamplesPerPeriod);

         			if(currentPeriodTotal > oldPeriodTotal + 1 && numPeriodsPerFrame > 1) {
           				printf("WARNING: We lost an ff step! oldFr %lld newFr %lld size=%d\n", 
                   			oldPeriodTotal, currentPeriodTotal, size);
         			}
         			if(true) { //currentPatchTotal > oldPatchTotal || params.ffLinear) {
           			float factor = ((float)data_read_total - currentPeriodTotal*numSamplesPerPeriod )/
                       			  numSamplesPerPeriod;
           			int currFFStep = currentPeriodTotal % numPeriodsPerFrame;
           			//printf("++++ currFrame: %lld\n",  currFFStep);
           		
					for (int i=0; i< numSlowDACChan; i++) {
             			float val;
             			if(false) {//params.ffLinear) {
               				val = (1-factor)*slowDACLUT[currFFStep*numSlowDACChan+i] +
                     		 factor*slowDACLUT[((currFFStep+1) % numPeriodsPerFrame)*numSlowDACChan+i];
             			} else {
               				val = slowDACLUT[currFFStep*numSlowDACChan+i];
             			}
             			//printf("Set ff channel %d in cycle %d to value %f totalper %lld.\n", 
             			//            i, currFFStep,val, currentPeriodTotal);
             
             			int status = setPDMNextValueVolt(val, i);             

             			//uint64_t curr = getPDMRegisterValue();

             			if (status != 0) {
                 			printf("Could not set AO[%d] voltage.\n", i);
            			 }
           		  	  }
         			}
					oldPeriodTotal = currentPeriodTotal;
				} else {
					//printf("Counter not increased %d %d \n", wp_old, wp);
					//usleep(2);
				}
			}
		}
		// Wait for the acquisition to start
		usleep(40);
	}

	printf("Slow daq thread finished\n");
}


/*
 *
 */
int main(int argc, char** argv) {
	(void) argc;
	(void) argv;
	int rc;

	int listenfd;
	char smbuffer[10];

	// Init FPGA
	init();

	// Start socket for sending the data
	datasockfd = createServer(5026);
	newdatasockfd = 0;

	// Start acquisition thread
	acquisitionThreadRunning = true;
	rxEnabled = false;
	pthread_create(&pAcq, NULL, acquisitionThread, NULL);
	pthread_create(&pSlowDAC, NULL, slowDACThread, NULL);

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

	while (1) {
		int clifd;
		struct sockaddr_in cliaddr;
		socklen_t clilen;

		//printf("Waiting for new connection\n");
		clilen = sizeof (cliaddr);
		clifd = accept(listenfd, (struct sockaddr *) &cliaddr, &clilen);

		if (clifd < 0) continue;

		printf("Connection established %s\r\n", inet_ntoa(cliaddr.sin_addr));

		scpi_context.user_context = &clifd;

		while (1) {
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
					setMasterTrigger(MASTER_TRIGGER_OFF);
					rxEnabled = false;
					break;
				} else {
					SCPI_Input(&scpi_context, smbuffer, rc);
				}
			}
		}

		close(clifd);
		if(newdatasockfd > 0) {
			close(newdatasockfd);
			newdatasockfd = 0;
		}
	}

	// Exit gracefully
	acquisitionThreadRunning = false;
	stopTx();
	setMasterTrigger(MASTER_TRIGGER_OFF);
	rxEnabled = false;
	pthread_join(pAcq, NULL);
	pthread_join(pSlowDAC, NULL);
	releaseBuffer();

	return (EXIT_SUCCESS);
}


