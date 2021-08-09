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
static int  sleepTime = 0;
static int baseSleep = 20;

static sequenceNode_t *current; 
static int lastStep = INT_MAX;

static int lookahead = 110;

bool isSequenceListEmpty() {
	return head == NULL;
}

sequenceNode_t * newSequenceNode() {
	sequenceNode_t* node = (sequenceNode_t*) calloc(1, sizeof(sequenceNode_t));
	node->next = NULL;
	node->prev = NULL;
	return node;
}

void appendSequenceToList(sequenceNode_t* node) {
	if (isSequenceListEmpty()) {
		node->prev = NULL;
		node->next = NULL;
		head = node;
	}
	else {
		node->prev = tail;
		node->next = NULL;
		tail->next = node;
	}
	tail = node;
}

sequenceNode_t* popSequence() {
	if (isSequenceListEmpty()) {
		return NULL;
	}
	else if (tail != NULL) {
		sequenceNode_t * result = tail;
		tail = tail->prev;
		if (tail != NULL) {
			tail->next = NULL;
		}
		else {
			head = NULL;
		}
		return result;
	}
	// Illegal state
	printf("Pop error, sequence list is in illegal state");
	return NULL;
}

void cleanUpSequenceNode(sequenceNode_t * node) {
	if (node != NULL) {
		cleanUpSequence(&(node->sequence).data);
		free(node);
		node = NULL;
	}
}

void cleanUpSequence(sequenceData_t *seqData) {
	if (seqData->LUT != NULL) {
		free(seqData->LUT);
		seqData->LUT = NULL;
	}
	if (seqData->enableLUT != NULL) {
		free(seqData->enableLUT);
		seqData->enableLUT = NULL;
	}
}

void cleanUpSequenceList() {
	int i = 0;
	if (!isSequenceListEmpty()) {
		sequenceNode_t * node = head;
		while (node != NULL) {
			sequenceNode_t * next = node->next;
			cleanUpSequenceNode(node);
			i++;
			node = next;
		}
	}
	head = NULL;
	tail = NULL;
}

bool isSequenceConfigurable() {
	return !rxEnabled && (seqState == CONFIG || seqState == PREPARED || seqState == FINISHED);
}

float getArbitrarySequenceValue(sequenceData_t *seqData, int step, int channel) {
	if (seqData->type == ARBITRARY) {
		return seqData->LUT[step * numSlowDACChan + channel];
	}
	return 0;
}

float getConstantSequenceValue(sequenceData_t *seqData, int step, int channel) {
	if (seqData->type == CONSTANT) {
		return seqData->LUT[channel];
	}
	return 0;
}

float getPauseSequenceValue(sequenceData_t *seqData, int step, int channel) {
	if (seqData->type == PAUSE) {
		return 0; // Identical to failure case
	}
	return 0;
}

float getRangeSequenceValue(sequenceData_t *seqData, int step, int channel){
	if (seqData->type == RANGE) {
		float start = seqData->LUT[0 * numSlowDACChan + channel];
		float stepSize = seqData->LUT[1 * numSlowDACChan + channel];
		return start + step * stepSize;
	}
	return 0;
}


static float getSequenceVal(sequence_t *sequence, int step, int channel) {
	return sequence->getSequenceValue(&(sequence->data), step, channel);
}

sequenceInterval_t computeInterval(sequenceData_t *seqData, int localRepetition, int localStep) {

	int stepInSequence = seqData->numStepsPerRepetition * localRepetition + localStep;
	//printf("%d stepInSequence ", stepInSequence);
	//Regular
	if (seqData->rampUpSteps <= stepInSequence && stepInSequence < seqData->rampUpTotalSteps + (seqData->numStepsPerRepetition * seqData->numRepetitions) + seqData->rampDownSteps) {
		return REGULAR;
	} 
	//RampUp
	else if (stepInSequence < seqData->rampUpSteps) {
		return RAMPUP;
	}
	//RampDown
	else {
		int stepsInRampUpandRegular = (seqData->numStepsPerRepetition * seqData->numRepetitions) + seqData->rampUpTotalSteps;
		if (stepInSequence <= stepsInRampUpandRegular + seqData->rampDownTotalSteps)  {
			return RAMPDOWN;
		}
		else {
			return DONE;
		}
	}
}

static float rampingFunction(float numerator, float denominator) {
	return (0.9640 + tanh(-2.0 + (numerator / denominator) * 4.0)) / 1.92806;
}

static float clamp(double val, double min, double max) {
	double temp = val < min ? min : val;
	return temp > max ? max : temp;
}

static float getFactor(sequenceData_t *seqData, int localRepetition, int localStep) {

	switch(computeInterval(seqData, localRepetition, localStep)) {
		case REGULAR:
			return 1.0;
		case RAMPUP:
			; // Empty statement to allow declaration in switch
			// Step in Ramp up so far = how many steps so far - when does ramp up start
			int stepInRampUp = (seqData->numStepsPerRepetition * localRepetition + localStep) - 0;
			return clamp(rampingFunction((float) stepInRampUp, (float) seqData->rampUpSteps - 1), 0.0, 1.0);
		case RAMPDOWN:
			; // See above
			int stepsUpToRampDown = (seqData->numStepsPerRepetition * seqData->numRepetitions) + seqData->rampUpTotalSteps + (seqData->rampDownTotalSteps - seqData->rampDownSteps);
			int stepsInRampDown = (seqData->numStepsPerRepetition * localRepetition + localStep) - stepsUpToRampDown;
			return clamp(rampingFunction((float) (seqData->rampDownSteps - stepsInRampDown), (float) seqData->rampDownSteps - 1), 0.0, 1.0);
		case DONE:
		default:
			return 0.0;
	}
}

void setupRampingTiming(sequenceData_t *seqData, double rampUpTime, double rampUpFraction, double rampDownTime, double rampDownFraction) {
	double bandwidth = 125e6 / getDecimation();
	double period = (numSamplesPerSlowDACStep * seqData->numStepsPerRepetition) / bandwidth;
	seqData->rampUpTotalSteps = ceil(rampUpTime / (numSamplesPerSlowDACStep / bandwidth));
	seqData->rampUpSteps = ceil(rampUpTime * rampUpFraction / (numSamplesPerSlowDACStep / bandwidth));
	seqData->rampDownTotalSteps = ceil(rampDownTime / (numSamplesPerSlowDACStep / bandwidth));
	seqData->rampDownSteps = ceil(rampDownTime * rampDownFraction / (numSamplesPerSlowDACStep / bandwidth));
}

static void initSlowDAC() {
	// Compute Ramping timing	
	//setupRampingTiming(&dacSequence.data, rampUpTime, rampUpFraction);

	for (int d = 0; d < numSlowDACChan; d++) {
		setEnableDACAll(1, d);
	}

	//Reset Lost Steps Flag
	err.lostSteps = 0;
}

static void cleanUpSlowDAC() {
	stopTx();
	cleanUpSequenceList();
	seqState = FINISHED;
	printf("Seq cleaned/finished\n");
}

static void setLUTValuesFor(int futureStep, int channel, int currPDMIndex) {
	if (current == NULL) {
		setPDMValueVolt(0.0, channel, currPDMIndex);
		setEnableDAC(false, channel, currPDMIndex);
		return;
	}

	// Translate from global timeline to sequence local timeline
	int localRepetition = (futureStep - currentSequenceBaseStep) / current->sequence.data.numStepsPerRepetition;
	int localStep = (futureStep - currentSequenceBaseStep) % current->sequence.data.numStepsPerRepetition;
	sequenceInterval_t interval = computeInterval(&(current->sequence).data, localRepetition, localStep); 

	// Advance to next sequence
	if (interval  == DONE) {
		current = current->next;
		currentSequenceBaseStep = futureStep;

		// Notify end of sequence(s)
		if (current == NULL) {
			if (futureStep < lastStep) {
				lastStep = futureStep;
			}
			setPDMValueVolt(0.0, channel, currPDMIndex);
			setEnableDAC(false, channel, currPDMIndex);
			return;
		}

		// Recompute with new sequence
		localRepetition = (futureStep - currentSequenceBaseStep) / current->sequence.data.numStepsPerRepetition;
		localStep = (futureStep - currentSequenceBaseStep) % current->sequence.data.numStepsPerRepetition;
		interval = computeInterval(&(current->sequence).data, localRepetition, localStep); 
	} 

	// PDM Value
	float val = getSequenceVal(&(current->sequence), localStep, channel);
	float factor = getFactor(&(current->sequence).data, localRepetition, localStep);
	//printf("Step %d factor %f\n", futureStep, factor);
	if (setPDMValueVolt(factor * val, channel, currPDMIndex) != 0) {
		printf("Could not set AO[%d] voltage.\n", channel);	
	}

	// Enable Value
	if (current->sequence.data.enableLUT != NULL && interval == REGULAR) {
		bool temp = current->sequence.data.enableLUT[localStep * numSlowDACChan + channel];
		setEnableDAC(temp, channel, currPDMIndex);
		printf("%d enable", temp);
	}
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



bool prepareSequences() {
	if ((seqState == CONFIG || seqState == PREPARED) && !isSequenceListEmpty()) {
		printf("Preparing Sequence\n");
		initSlowDAC();
		// Init Sequence Iteration
		currentSequenceBaseStep = 0;
		current = head;
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
	int64_t deltaSet = (getTotalWritePointer() / numSamplesPerSlowDACStep) - currentSlowDACStepTotal;

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
			currentSlowDACStepTotal = wp / numSamplesPerSlowDACStep;

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
	rxEnabled = false;
	pthread_join(pControl, NULL);
}
