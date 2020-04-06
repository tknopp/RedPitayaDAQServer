#ifndef __DAQ_SERVER_SCPI_H_
#define __DAQ_SERVER_SCPI_H_

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

#define SCPI_INPUT_BUFFER_LENGTH 25600
#define SCPI_ERROR_QUEUE_SIZE 17
#define SCPI_IDN1 "CUSTOM"
#define SCPI_IDN2 "REDPITAYA"
#define SCPI_IDN3 NULL
#define SCPI_IDN4 "0.1"

extern int numSamplesPerPeriod;
extern int numSamplesPerSubPeriod;
extern int numPeriodsPerFrame;
extern int numSlowDACChan;
extern int numSlowADCChan;
extern int enableSlowDAC;
extern int enableSlowDACAck;
extern int numSlowDACFramesEnabled;
extern int numSlowDACLostSteps;
extern int64_t frameSlowDACEnabled;

extern int64_t startWP;
extern int64_t channel;

extern uint32_t *buffer;
extern bool initialized;
extern bool rxEnabled;
extern bool buffInitialized;
extern bool acquisitionThreadRunning;

extern pthread_t pAcq;

extern int datasockfd;
extern int newdatasockfd;

extern float *slowDACLUT;
extern bool slowDACInterpolation;
extern double slowDACRampUpTime;
extern double slowDACFractionRampUp;
extern float *slowADCBuffer;

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

extern uint64_t getCurrentFrameTotal();
extern uint64_t getCurrentPeriodTotal();
extern uint64_t getNumSamplesPerFrame();
extern uint64_t getNumSubPeriodsPerPeriod();
extern uint64_t getNumSubPeriodsPerFrame();
extern uint64_t getNumSamplesPerSubPeriod();
extern int createServer(int);
extern int waitServer(int);
extern void* acquisitionThread(void*);
extern void* slowDACThread(void*);
extern void sendFramesToHost(int64_t, int64_t);
extern void sendPeriodsToHost(int64_t, int64_t);
extern void sendSlowFramesToHost(int64_t, int64_t);
extern void initBuffer();
extern void releaseBuffer();

#endif /* __DAQ_SERVER_SCPI_H_ */

