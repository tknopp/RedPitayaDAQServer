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
#include <sched.h>
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

extern int numSlowADCChan;

extern int64_t channel;

extern uint32_t *buffer;
extern bool initialized;
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
extern int setSocketNonBlocking(int);

extern void* communicationThread(void*);
extern void* controlThread(void*);
extern void joinControlThread();

typedef enum {CONFIGURATION, MEASUREMENT, TRANSMISSION} serverMode_t;
extern serverMode_t getServerMode();
extern void setServerMode(serverMode_t mode);


// Sequences
// Sequence structures
typedef enum {ARBITRARY, CONSTANT, PAUSE, RANGE} sequenceTypes_t;
typedef enum {CONFIG, PREPARED, RUNNING, FINISHED} sequenceState_t;
typedef enum {RAMPUP, REGULAR, RAMPDOWN, DONE} sequenceInterval_t;

typedef struct {
	int numStepsPerRepetition; // How many steps per repetition
	float* LUT; // LUT for value function pointer
	bool * enableLUT;
	int rampUpRepetitions; // How many repetitions for both individually ramp up/down
	int rampUpTotalSteps; // How many steps are in these repetitions
	int rampUpSteps; // How many of those steps have a ramping factor
	int rampDownRepetitions; 
	int rampDownTotalSteps; 
	int rampDownSteps;
	int numRepetitions; // How many regular repetitions are there
	sequenceTypes_t type; // Sanity check for function pointer
	bool resetAfter;
} sequenceData_t;

typedef struct {
	double amplitudes[8];
	bool amplitudesSet[8];
	double offset[2];
	bool offsetSet[2];
	double frequency[8];
	bool frequencySet[8];
	double phase[8];
	bool phaseSet[8];
	int signalType[2];
	bool signalTypeSet[2];
	double jumpSharpness[2];
	bool jumpSharpnessSet[2];
} fastDACConfig_t;

typedef struct {
	sequenceData_t data;
	float (*getSequenceValue) (sequenceData_t *seqData, int step, int channel);
	fastDACConfig_t fastConfig;
} sequence_t;

typedef struct sequenceNode_s sequenceNode_t;
struct sequenceNode_s {
	sequence_t sequence;
	sequenceNode_t* prev;
	sequenceNode_t* next;
};

// Global sequence settings
extern int numSlowDACChan; // How many channels are considered
extern int numSamplesPerStep;
extern int numSlowDACLostSteps;
extern bool slowDACInterpolation;
extern float *slowADCBuffer;
extern sequenceState_t seqState; //State of sequence(s)
extern sequenceNode_t *head; //always first node
extern sequenceNode_t *tail; //always last node

// Function pointers for each sequence type
extern float getArbitrarySequenceValue(sequenceData_t*, int, int);
extern float getConstantSequenceValue(sequenceData_t*, int, int);
extern float getPauseSequenceValue(sequenceData_t*, int, int);
extern float getRangeSequenceValue(sequenceData_t*, int, int);

// Sequence construction and utility functions
extern sequenceNode_t *configNode;
extern double rampUpTime;
extern double rampUpFraction;
extern double rampDownTime;
extern double rampDownFraction;
extern bool prepareSequences();
extern void setupRampingTiming(sequenceData_t *seqData, double rampUpTime, double rampUpFraction, double rampDownTime, double rampDownFraction);
extern void cleanUpSequence(sequenceData_t * seqData);
extern void cleanUpSequenceList();
extern sequenceInterval_t computeInterval(sequenceData_t *seqData, int repetition, int step);
extern bool isSequenceConfigurable();
extern bool isSequenceListEmpty();
extern int sequenceListLength();
extern void appendSequenceToList(sequenceNode_t*);
extern sequenceNode_t * popSequence();
extern sequenceNode_t * newSequenceNode();
extern void cleanUpSequenceNode(sequenceNode_t*);

// Sequence Fast DAC Config FIFO Queue
typedef struct configNode_s configNode_t;
struct configNode_s {
	fastDACConfig_t * config;
	uint64_t startStep;
	configNode_t* next;
};
extern void enqueue(configNode_t** queue, fastDACConfig_t *config, int stepStart);
extern fastDACConfig_t* dequeue(configNode_t** queue);



// data loss
struct status {
	uint8_t overwritten :1;
	uint8_t corrupted :1;
	uint8_t lostSteps :1;
};
extern struct status err;
extern uint8_t getStatus();
extern uint8_t getErrorStatus();
extern uint8_t getOverwrittenStatus();
extern void clearOverwrittenStatus();
extern uint8_t getCorruptedStatus();
extern void clearCorruptedStatus();
extern uint8_t getLostStepsStatus();
extern void clearLostStepsStatus();
extern FILE* getLogFile();

// performance data
// ADC Performance
struct performance {
	uint64_t deltaRead;
	uint64_t deltaSend;
};
extern struct performance perf;
// DAC/Control performance
extern uint8_t avgDeltaControl;
extern uint8_t avgDeltaSet;
extern uint8_t minDeltaControl;
extern uint8_t maxDeltaSet;

// Client communication
extern void sendPerformanceDataToClient();
extern void sendADCPerformanceDataToClient();
extern void sendDACPerformanceDataToClient();
extern void sendDataToClient(uint64_t, uint64_t, bool);
extern void sendPipelinedDataToClient(uint64_t, uint64_t, uint64_t);
extern void sendSlowFramesToHost(int64_t, int64_t);
extern void sendFileToClient(FILE*);
extern void sendStatusToClient();

#endif /* __DAQ_SERVER_SCPI_H_ */

