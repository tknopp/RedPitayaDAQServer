#include <arpa/inet.h>
#include <errno.h>
#include <fcntl.h>
#include <inttypes.h>
#include <math.h>
#include <netinet/in.h>
#include <pthread.h>
#include <sched.h>
#include <scpi/scpi.h>
#include <signal.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/ioctl.h>
#include <sys/mman.h>
#include <sys/param.h>
#include <sys/select.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <unistd.h>
#include <limits.h>

#include "../lib/rp-daq-lib.h"
#include "../server/daq_server_scpi.h"
#include "logger.h"

static uint64_t wp;
static uint64_t currentSlowDACStepTotal;
static uint64_t currentSetSlowDACStepTotal; //Up to which step are the values already set
static uint64_t currentSequenceBaseStep;
static uint64_t oldSlowDACStepTotal;
static int sleepTime = 0;
static int baseSleep = 20;

static sequenceData_t * activeSequence;
static sequenceInterval_t prevInterval;

static int lastStep = INT_MAX;

static int lookahead = 110;

sequenceData_t * allocSequence() {
	sequenceData_t * seq = (sequenceData_t*) calloc(1, sizeof(sequenceData_t));
	seq->LUT = NULL;
	seq->enableLUT = NULL;
	seq->rampUp = NULL;
	seq->rampDown = NULL;
	return seq; 
}

void freeSequence(sequenceData_t *seqData) {
		if (seqData->LUT != NULL) {
		free(seqData->LUT);
		seqData->LUT = NULL;
	}
	if (seqData->enableLUT != NULL) {
		free(seqData->enableLUT);
		seqData->enableLUT = NULL;
	}
	if (seqData->rampUp != NULL) {
		freeRamping(seqData->rampUp);
		seqData->rampUp = NULL;
	}
	if (seqData->rampDown != NULL) {
		freeRamping(seqData->rampDown);
		seqData->rampDown = NULL;
	}
}

rampingData_t * allocRamping() {
	rampingData_t * ramp = (rampingData_t*) calloc(1, sizeof(rampingData_t));
	ramp->LUT = NULL;
	return ramp;
}

void freeRamping(rampingData_t * rampData) {
	if (rampData->LUT != NULL) {
		free(rampData->LUT);
		rampData->LUT = NULL;
	}
}

sequenceData_t *setSequence(sequenceData_t *seq) {
	sequenceData_t * old = activeSequence;
	activeSequence = seq;
	return old;
}

void clearSequence() {
	if (activeSequence != NULL) {
		freeSequence(activeSequence);
	}
	
	setPDMAllValuesVolt(0.0, 0);
	setPDMAllValuesVolt(0.0, 1);
	setPDMAllValuesVolt(0.0, 2);
	setPDMAllValuesVolt(0.0, 3);

	for(int d=0; d<4; d++) {
		setEnableDACAll(1,d);
	}
}

bool isSequenceConfigurable() {
	return getServerMode() == CONFIGURATION && (seqState == CONFIG || seqState == PREPARED || seqState == FINISHED);
}

float getSequenceValue(sequenceData_t *seqData, int seqStep, int channel) {
	int localStep = seqStep % seqData->numStepsPerRepetition;
	return seqData->LUT[localStep * numSlowDACChan + channel];
}

bool getSequenceEnableValue(sequenceData_t *seqData, int seqStep, int channel) {
	bool result = true;
	if (seqData->enableLUT != NULL) {
		int localStep = seqStep % seqData->numStepsPerRepetition;
		result = seqData->enableLUT[localStep * numSlowDACChan + channel];
	}
	return result;
}

float getRampingValue(rampingData_t *rampData, int rampStep, int channel) {
	int localStep = rampStep % rampData->numStepsPerRepetition;
	return rampData->LUT[localStep * numSlowDACChan + channel];
}

int getRampingSteps(rampingData_t *rampData) {
	return rampData->numRepetitions * rampData->numStepsPerRepetition;
}

int getRampUpSteps(sequenceData_t *seqData) {
	if (seqData->rampUp != NULL) {
		return getRampingSteps(seqData->rampUp);
	}
	return 0;
}

int getRampDownSteps(sequenceData_t *seqData) {
	if (seqData->rampDown != NULL) {
		return getRampingSteps(seqData->rampDown);
	}
	return 0;
}

int getSequenceSteps(sequenceData_t *seqData) {
	return seqData->numRepetitions * seqData->numStepsPerRepetition;
}

int getTotalSteps(sequenceData_t *seqData) {
	return getRampUpSteps(seqData) + getSequenceSteps(seqData) + getRampDownSteps(seqData);
}

sequenceInterval_t computeInterval(sequenceData_t *seqData, int step) {
	if (step < getRampUpSteps(seqData)) {
		return RAMPUP;
	}
	else if (step < getRampUpSteps(seqData) + getSequenceSteps(seqData)) {
		return REGULAR;
	}
	else if (step < getTotalSteps(seqData)) {
		return RAMPDOWN;
	}
	else {
		return DONE;
	}
}

static void initSlowDAC() {
	for (int d = 0; d < numSlowDACChan; d++) {
		setEnableDACAll(1, d);
	}

	//Reset Lost Steps Flag
	err.lostSteps = 0;
}

static void cleanUpSlowDAC() {
	stopTx();
	seqState = CONFIG;
	printf("Seq finished\n");
}

static int getBaseStep(sequenceData_t*seqData, sequenceInterval_t interval) {
	switch(interval) {
		case RAMPUP:
			return 0;
		case REGULAR:
			return getRampUpSteps(seqData);
		case RAMPDOWN:
			return getRampUpSteps(seqData) + getSequenceSteps(seqData);
		case DONE:
			return getTotalSteps(seqData);
	}
}

static void setLUTValuesFor(int futureStep, int channel, int currPDMIndex) {
	if (activeSequence == NULL) {
		setPDMValueVolt(0.0, channel, currPDMIndex);
		setEnableDAC(false, channel, currPDMIndex);
		setRampDownDAC(false, channel, currPDMIndex);
		return;
	}

	// Translate from global timeline to sequence local timeline
	sequenceInterval_t interval = computeInterval(activeSequence, futureStep); 
	int localStep = futureStep - getBaseStep(activeSequence, interval);

	if (interval != prevInterval && interval == DONE) {
		printf("Finished sequence\n");
		lastStep = futureStep;
	}
	prevInterval = interval;

	// PDM Value
	float val = 0.0;
	bool enable = true;
	bool rampDown = false;

	switch(interval) {
		case RAMPUP:
			val = getRampingValue(activeSequence->rampUp, localStep, channel);
			break;
		case REGULAR:
			val = getSequenceValue(activeSequence, localStep, channel);
			enable = getSequenceEnableValue(activeSequence, localStep, channel);
			break;
		case RAMPDOWN:
			val = getRampingValue(activeSequence->rampDown, localStep, channel);
			rampDown = true;
			break;
		case DONE:
		default:
			val = 0.0;
			enable = false;
	}
	
	//printf("Step %d factor %f value %f interval %d \n", futureStep, factor, val, computeInterval(&(currentSequence->sequence).data, localRepetition, localStep));
	if (setPDMValueVolt(val, channel, currPDMIndex) != 0) {
		printf("Could not set AO[%d] voltage.\n", channel);	
	}
	setEnableDAC(enable, channel, currPDMIndex);
	setRampDownDAC(rampDown, channel, currPDMIndex);
}

static void setLUTValuesFrom(uint64_t baseStep) {
	uint64_t nextSetStep = 0;
	int64_t nonRedundantSteps = baseStep + lookahead - currentSetSlowDACStepTotal; //upcoming nextSetStep - currentSetStep
	int start = MAX(0, lookahead - nonRedundantSteps);
	
	// "Time" in outer loop as setLUTValuesFor is stateful and advances sequence list based on step/time
	for (int y = start; y < lookahead; y++) {
		for (int chan = 0; chan < numSlowDACChan; chan++) {
			uint64_t futureStep = (baseStep + y); 
			uint64_t currPDMIndex = futureStep % PDM_BUFF_SIZE;
			
			setLUTValuesFor(futureStep, chan, currPDMIndex);

			if (futureStep > nextSetStep) {
				nextSetStep = futureStep;
			}
		}
	}
	currentSetSlowDACStepTotal = nextSetStep + 1;
}



bool prepareSequence() {
	if ((seqState == CONFIG || seqState == PREPARED)) {
		if (activeSequence != NULL) {
			printf("Preparing Sequence\n");
			initSlowDAC();
			// Init Sequence Iteration
			currentSequenceBaseStep = 0;
			lastStep = INT_MAX;
			// Init Perfomance
			avgDeltaControl = 0;
			avgDeltaSet = 0;
			minDeltaControl = 0xFF;
			maxDeltaSet = 0x00;
			// Init Sleep
			sleepTime = baseSleep;
			// Set first values
			setLUTValuesFrom(0);
			seqState = PREPARED;
			printf("Prepared Sequence\n");
		} else {
			printf("No sequence to prepare\n");
		}
		return true;
	}
	return false;
}

static void handleLostSlowDACSteps(uint64_t oldSlowDACStep, uint64_t currentSlowDACStep) {
	LOG_WARN("WARNING: We lost a slow DAC step! oldSlowDACStep %lld newSlowDACStep %lld size=%lld\n",
			oldSlowDACStep, currentSlowDACStep, currentSlowDACStep - oldSlowDACStep);
	err.lostSteps = 1;
	numSlowDACLostSteps += 1;
}

static void updatePerformance(float alpha) {
	int64_t deltaControl = oldSlowDACStepTotal + lookahead - currentSlowDACStepTotal;
	int64_t deltaSet = (getTotalWritePointer() / numSamplesPerStep) - currentSlowDACStepTotal;

	deltaSet = (deltaSet > 0xFF) ? 0xFF : deltaSet;
	deltaControl = (deltaControl < 0) ? 0 : deltaControl;

	avgDeltaControl = alpha * deltaControl + (1 - alpha) * avgDeltaControl;
	avgDeltaSet = alpha * deltaSet + (1 - alpha) * avgDeltaSet;

	if (deltaControl < minDeltaControl) {
		minDeltaControl = deltaControl;
	}
	if (deltaSet > maxDeltaSet) {
		maxDeltaSet = deltaSet;
	}

}

void *controlThread(void *ch) {
	//Performance related variables
	float alpha = 0.7;

	//Book keeping 
	currentSetSlowDACStepTotal = 0;

	//Sleep
	baseSleep = 20;
	sleepTime = baseSleep;

	//If not initialized then image not loaded and mmaped
	while(!initialized) {
		sleep(1);
	}

	printf("Entering control loop\n");

	while (controlThreadRunning) {
		if (getMasterTrigger() && (seqState == PREPARED || seqState == RUNNING)) {
			if (seqState == PREPARED) {
				printf("Sequence started\n");
				seqState = RUNNING;
			}

			// Handle sequence
			wp = getTotalWritePointer();
			currentSlowDACStepTotal = wp / numSamplesPerStep;

			if (currentSlowDACStepTotal > oldSlowDACStepTotal) {

				if (currentSlowDACStepTotal > oldSlowDACStepTotal + lookahead) {
					handleLostSlowDACSteps(oldSlowDACStepTotal, currentSlowDACStepTotal);
				}

				if (currentSlowDACStepTotal >= lastStep) {
					// We now have measured enough rotations and switch of the slow DAC
					cleanUpSlowDAC();
					currentSetSlowDACStepTotal = 0;
				} else {
					setLUTValuesFrom(currentSlowDACStepTotal);
					updatePerformance(alpha);
				}


			} else {
				sleepTime += baseSleep;
			}

			//Iterate
			oldSlowDACStepTotal = currentSlowDACStepTotal;
			usleep(sleepTime);

		} else {

			if (seqState == RUNNING) {
				printf("Sequence was stopped before finishing\n");
				cleanUpSlowDAC();
			}

			// Wait for sequence to be prepared and master trigger	
			usleep(500);
		}
	}

	// clean up
	cleanUpSlowDAC();

	printf("Control thread finished\n");
}

void joinControlThread() {
	controlThreadRunning = false;
	pthread_join(pControl, NULL);
}
