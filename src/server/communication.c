#include <stdint.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/param.h>
#include <inttypes.h>
#include <sys/sendfile.h>
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


static const size_t userspaceSizeSamples = 64 * 1024;
static const size_t userspaceSizeBytes = userspaceSizeSamples * sizeof(uint32_t);
static uint8_t * userspaceBuffer = NULL;

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
	timeout.tv_usec = 1000;

	rc = select(max_fd + 1, &fds, NULL, NULL, &timeout);

	return rc;
}


static int writeAll(int fd, const void *buf, size_t len);
static int writeAll(int fd, const void *buf, size_t len) {
	size_t bytesSent = 0;
	size_t bytesLeft = len;
	size_t n; 
	while (bytesSent < len) {
		n = write(fd, buf + bytesSent, bytesLeft);
		if (n == -1) {
			return n;
		} 
		bytesSent+=n;
		bytesLeft-=n;
	}
	return bytesSent;
} 



void neoncopy(void *dst, const void *src, int cnt) {
	asm volatile
		(
		 "loop_%=:\n"
		 "vldm %[src]!, {q0, q1, q2, q3}\n"
		 "vstm %[dst]!, {q0, q1, q2, q3}\n"
		 "subs %[cnt], %[cnt], #64\n"
		 "bgt loop_%="
		 : [dst] "+r" (dst), [src] "+r" (src), [cnt] "+r" (cnt)
		 :
		 : "q0", "q1", "q2", "q3", "cc", "memory"
		);
}


/*
 * This function copies count many bytes from the adc-pointer to the userspace buffer, starting from the beginning of the userspace buffer.
 * Count has to fit in the userspace buffer. The function tries to use the neon copy whenever it can
 * */
static size_t copySamplesToBuffer(const void *adc, size_t count) {
	size_t ptr = 0;
	size_t size, sizeTemp;
	while(ptr < count) {
		sizeTemp = MIN(count-ptr, userspaceSizeBytes);
		//Neon Copy copies 64 Byte in each iteration, size should always be a multiple of 64 or a different copy needs to be used
		size = sizeTemp - (sizeTemp % 64);
		if (size == 0) {
			size = sizeTemp;
			memcpy(userspaceBuffer + ptr, adc + ptr, size);
		}
		else {
			neoncopy(userspaceBuffer + ptr, adc + ptr, size);
		}
		ptr += size;
	}
	return ptr;
}

static bool sendBufferedSamplesToClient(uint64_t wpTotal, uint64_t numSamples) {
	bool wasCorrupted = false;
	int n = 0;
	uint32_t wp = getInternalWritePointer(wpTotal);
	uint64_t sendSamples = 0;
	uint64_t daqTotal = 0;
	uint64_t samplesToCopy = 0;
	size_t copiedBytes = 0;

	while (sendSamples < numSamples) {
		//Move samples to userspace
		samplesToCopy = MIN(numSamples - sendSamples, userspaceSizeSamples);
		copiedBytes = copySamplesToBuffer(ram + sizeof(uint32_t)*(wp + sendSamples), samplesToCopy*sizeof(uint32_t));

		//Check if samples could have been corrupted
		daqTotal = getTotalWritePointer();
		wasCorrupted |= ((daqTotal - wpTotal + sendSamples + samplesToCopy) > ADC_BUFF_SIZE && daqTotal > (wpTotal + sendSamples + samplesToCopy));

		//Send samples to client
		n = writeAll(newdatasockfd, userspaceBuffer, copiedBytes);
		if (n < 0) {
			LOG_ERROR("Error in writeSamplesChunked.writeAll");
		}
		sendSamples += samplesToCopy;
	}
	
	return wasCorrupted;
} 

struct performance sendDataToClient(uint64_t wpTotal, uint64_t numSamples, bool clearFlags) {
	uint64_t daqTotal = getTotalWritePointer();
	uint32_t wp = getInternalWritePointer(wpTotal);
	uint64_t deltaRead = daqTotal - wpTotal;
	uint64_t deltaSend = 0;
	struct performance perfResult;
	perfResult.deltaRead = deltaRead;
	// Requested data specific status
	if (clearFlags) { 
		err.overwritten = 0;
		err.corrupted = 0;
	}

	if (deltaRead > ADC_BUFF_SIZE && daqTotal > wpTotal) {
		err.overwritten = 1;  	
		LOG_WARN("%lli Requested data was overwritten", wpTotal);	
	} 

	// Send Data
	if(wp+numSamples <= ADC_BUFF_SIZE) {

		bool wasCorrupted = sendBufferedSamplesToClient(wpTotal, numSamples);
		
		uint64_t daqTotalAfter = getTotalWritePointer();
		deltaSend = daqTotalAfter - daqTotal;
		if (err.overwritten == 0 && wasCorrupted) {
			err.corrupted = 1;
			LOG_WARN("%lli Sent data was corrupted", wpTotal);	
		}

		perfResult.deltaSend = deltaSend;

	} else {                                                                                                  
		uint64_t size1 = ADC_BUFF_SIZE - wp;                                                              
		uint64_t size2 = numSamples - size1;
		
		struct performance temp1 = sendDataToClient(wpTotal, size1, false);
		struct performance temp2 = sendDataToClient(wpTotal + size1, size2, false);
		perfResult.deltaSend = temp1.deltaSend + temp2.deltaSend;

	}

	if (clearFlags) {
		perf = perfResult;
	}

	return perfResult;
}

void sendPipelinedDataToClient(uint64_t wpTotal, uint64_t numSamples, uint64_t chunkSize) {
	uint64_t sendSamplesTotal = 0;
	uint64_t sendSamples = 0;
	uint64_t samplesToSend = 0;
	uint64_t writeWP = 0;
	uint64_t readWP = 0;
	uint64_t chunk = 0;
	bool clearFlags = true;

	while (sendSamplesTotal < numSamples && chunkSize > 0 ) {
		chunk = MIN(numSamples - sendSamplesTotal, chunkSize); // Client and Server can compute same chunk value
		
		// Send chunk
		//printf("Send chunk %llu\n", chunk);
		while (sendSamples < chunk) {
			readWP = wpTotal + sendSamplesTotal + sendSamples;
			writeWP = getTotalWritePointer();

			// Wait for samples to be available
			samplesToSend = MIN(userspaceSizeSamples, chunk - sendSamples);
			while (readWP + samplesToSend >= writeWP) {
		//		printf("Wait for at least %llu\n", samplesToSend);
				writeWP = getTotalWritePointer();
				usleep(30);
			}
			samplesToSend = MIN(writeWP - readWP, chunk - sendSamples);
		//	printf("Send %llu, left %llu\n", samplesToSend, chunk - (sendSamples + samplesToSend));

			sendDataToClient(readWP, samplesToSend, clearFlags);
			sendSamples += samplesToSend;
			clearFlags = false; // Only the first sendData each iteration clears the flags
		}

		sendStatusToClient();
		sendPerformanceDataToClient();
		

		sendSamples = 0;
		clearFlags = true;
		sendSamplesTotal += chunk;
		
	}
}


void sendFileToClient(FILE* file) {
	int fd = fileno(file);
	struct stat fInfo;
	off_t fSize = 0;
	off_t offset = 0;
	if (!fstat(fd, &fInfo)) {
		fSize = fInfo.st_size;
	}
	int64_t remain = fSize; //To have known size
	send(newdatasockfd, &remain, sizeof(remain), 0);
	int64_t n = 0;
	while (((n = sendfile(newdatasockfd, fd, &offset, remain)) > 0) && remain > 0) {
		remain -= n;
	}
}

void sendPerformanceDataToClient() {
	sendADCPerformanceDataToClient();
	sendDACPerformanceDataToClient();
}

void sendADCPerformanceDataToClient() {
	uint64_t deltas[2] = {perf.deltaRead, perf.deltaSend};
	int n = 0;
	n = send(newdatasockfd, deltas, sizeof(deltas), 0);
	if (n < 0) {
		LOG_WARN("Error while sending ADC performance data");
	}
}

void sendDACPerformanceDataToClient() {
	uint8_t perfValues[4] = {avgDeltaControl, avgDeltaSet, minDeltaControl, maxDeltaSet};
	int n = 0;
	n = send(newdatasockfd, perfValues, sizeof(perfValues), 0);
	if (n < 0) {
		LOG_WARN("Error while sending DAC performance data");
	}
}

void sendStatusToClient() {
	uint8_t status = getStatus();
	int n = 0;
	n = send(newdatasockfd, &status, sizeof(status), 0);
	if (n < 0) {
		LOG_WARN("Error while sending status");
	}
}

void* communicationThread(void* p) { 
	int clifd = (int)p;
	int rc;
	char smbuffer[20];

 	userspaceBuffer = malloc(userspaceSizeBytes);


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
		logger_flush();
	}
	LOG_INFO("Comm almost done");

	free(userspaceBuffer);
	userspaceBuffer = NULL;

	close(clifd);
	if(newdatasockfd > 0) {
		close(newdatasockfd);
		newdatasockfd = 0;
	}

	LOG_INFO("Comm thread done");
	return NULL;
}


