#ifndef __DAQ_SERVER_SCPI_H_
#define __DAQ_SERVER_SCPI_H_

#include <stdint.h>
#include <signal.h>
#include <fcntl.h>
#include <sys/mman.h>
#include <sys/ioctl.h>
#include <sys/param.h>
#include <inttypes.h>
#include <sys/stat.h>
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

#include <scpi/scpi.h>

#include "../lib/rp-daq-lib.h"

#define SCPI_INPUT_BUFFER_LENGTH 25600
#define SCPI_ERROR_QUEUE_SIZE 17
#define SCPI_IDN1 "CUSTOM"
#define SCPI_IDN2 "REDPITAYA"
#define SCPI_IDN3 NULL
#define SCPI_IDN4 "0.1"

#define ACQUISITION_OFF 0
#define ACQUISITION_ON 1

extern int numSamplesPerSlowDACStep;
extern int numSlowDACStepsPerRotation;
extern int numSlowDACChan;
extern int numSlowADCChan;
extern int enableSlowDAC;
extern int enableSlowDACAck;
extern int numSlowDACRotationsEnabled;
extern int numSlowDACLostSteps;
extern uint64_t rotationSlowDACEnabled;

extern int64_t channel;

extern uint32_t *buffer;
extern bool initialized;
extern bool rxEnabled;
extern bool buffInitialized;
extern bool controlThreadRunning;
extern bool commThreadRunning;

extern pthread_t pControl;
extern pthread_t pComm;

extern int datasockfd;
extern int newdatasockfd;

extern int newdatasockfd;
extern struct sockaddr_in newdatasockaddr;
extern socklen_t newdatasocklen;
extern const scpi_command_t scpi_commands[];
extern scpi_t scpi_context;

extern float *slowDACLUT;
extern bool *enableDACLUT;
extern bool slowDACInterpolation;
extern double slowDACRampUpTime;
extern double slowDACFractionRampUp;
extern float *slowADCBuffer;

extern float fastDACNextAmplitude[8];

extern void getprio(pthread_t id);

extern size_t SCPI_Write(scpi_t *, const char *, size_t);
extern scpi_result_t SCPI_Flush(scpi_t *);
extern int SCPI_Error(scpi_t *, int_fast16_t);
extern scpi_result_t SCPI_Control(scpi_t *, scpi_ctrl_name_t, scpi_reg_val_t);
extern scpi_result_t SCPI_Reset(scpi_t *);
extern scpi_result_t SCPI_SystemCommTcpipControlQ(scpi_t *);
extern scpi_interface_t scpi_interface;

extern char scpi_input_buffer[SCPI_INPUT_BUFFER_LENGTH];
extern scpi_error_t scpi_error_queue_data[SCPI_ERROR_QUEUE_SIZE];
extern scpi_t scpi_context;

extern int createServer(int);
extern int waitServer(int);

extern void* communicationThread(void*);
extern void* controlThread(void*);
extern void joinControlThread();

extern void sendDataToClient(uint64_t, uint64_t);
extern void sendSlowFramesToHost(int64_t, int64_t);
extern void sendFileToClient(FILE*);

// data loss
struct status {
	uint8_t overwritten :1;
	uint8_t corrupted :1;
	uint8_t lostSteps :1;
};
struct status err;
extern uint8_t getErrorStatus();
extern uint8_t getOverwrittenStatus();
extern void clearOverwrittenStatus();
extern uint8_t getCorruptedStatus();
extern void clearCorruptedStatus();
extern uint8_t getLostStepsStatus();
extern void clearLostStepsStatus();
extern FILE* getLogFile();

// performance data
struct performance {
	uint64_t deltaRead;
	uint64_t deltaSend;
};
struct performance perf;
extern void sendPerformanceDataToClient();

#endif /* __DAQ_SERVER_SCPI_H_ */

