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

float getLookupSequenceValue(sequenceData_t *seqData, int step, int channel) {
	if (seqData->type == LOOKUP) {
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
	if (seqData->rampingRepetitions <= localRepetition && localRepetition < seqData->rampingRepetitions + seqData->numRepetitions) {
		return REGULAR;
	} 
	//RampUp
	else if (localRepetition < seqData->rampingRepetitions) {
		// Before the last rampingSteps in rampup intervall
		if (stepInSequence < seqData->rampingTotalSteps - seqData->rampingSteps) {
			return BEFORE;
		}
		else {
			return RAMPUP;
		}
	}
	//RampDown
	else {
		int stepsInRampUpandRegular = seqData->numStepsPerRepetition * (seqData->rampingRepetitions + seqData->numRepetitions);
		if (stepInSequence <= stepsInRampUpandRegular + seqData->rampingSteps) {
			return RAMPDOWN;
		}
		else if (stepInSequence <= stepsInRampUpandRegular + seqData->rampingTotalSteps)  {
			return AFTER;
		}
		else {
			return DONE;
		}
	}
}

static float rampingFunction(float numerator, float denominator) {
	return (0.9640 + tanh(-2.0 + (numerator / denominator) * 4.0)) / 1.92806;
}

static float getFactor(sequenceData_t *seqData, int localRepetition, int localStep) {

	switch(computeInterval(seqData, localRepetition, localStep)) {
		case REGULAR:
			return 1;
		case RAMPUP:
			; // Empty statement to allow declaration in switch
			// Step in Ramp up so far = how many steps so far - when does ramp up start
			int stepInRampUp = (seqData->numStepsPerRepetition * localRepetition + localStep)
				- (seqData->rampingTotalSteps - seqData->rampingSteps - 1);
			return rampingFunction((float) stepInRampUp, (float) seqData->rampingSteps - 1);
		case RAMPDOWN:
			; // See above
			int stepsUpToRampDown = seqData->numStepsPerRepetition * (seqData->rampingRepetitions + seqData->numRepetitions);
			int stepsInRampDown = (seqData->numStepsPerRepetition * localRepetition + localStep) - stepsUpToRampDown;
			//printf("%d StepsInRampDown\n", stepsInRampDown);
			return rampingFunction((float) (seqData->rampingSteps - stepsInRampDown), (float) seqData->rampingSteps - 1);
		case BEFORE:
		case AFTER:
		case DONE:
		default:
			return 0;
	}
}

static float getSequenceValue(int futureStep, int channel) {
	if (current == NULL) {
		return 0.0;
	}

	// Translate from global timeline to sequence local timeline
	int localRepetition = (futureStep - currentSequenceBaseStep) / current->sequence.data.numStepsPerRepetition;
	int localStep = (futureStep - currentSequenceBaseStep) % current->sequence.data.numStepsPerRepetition;

	// Advance to next sequence
	if (computeInterval(&(current->sequence).data, localRepetition, localStep) == DONE) {
		current = current->next;
		currentSequenceBaseStep = futureStep;

		if (current == NULL) {
			if (futureStep < lastStep) {
				lastStep = futureStep;
			}
			return 0.0;
		}

		// Recompute with new sequence
		localRepetition = (futureStep - currentSequenceBaseStep) / current->sequence.data.numStepsPerRepetition;
		localStep = (futureStep - currentSequenceBaseStep) % current->sequence.data.numStepsPerRepetition;

	} 

	float val = getSequenceVal(&(current->sequence), localStep, channel);
	float factor = getFactor(&(current->sequence).data, localRepetition, localStep);
	//printf("%d interval, ", computeInterval(&dacSequence.data, localRepetition, localStep));
	return factor * val;
}

void setupRampingTiming(sequenceData_t *seqData, double rampUpTime, double rampUpFraction) {
	double bandwidth = 125e6 / getDecimation();
	double period = (numSamplesPerSlowDACStep * seqData->numStepsPerRepetition) / bandwidth;
	seqData->rampingRepetitions = ceil(rampUpTime / period);
	seqData->rampingTotalSteps = ceil(rampUpTime / (numSamplesPerSlowDACStep / bandwidth));
	seqData->rampingSteps = ceil(rampUpTime * rampUpFraction / (numSamplesPerSlowDACStep / bandwidth));
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

static void setLUTValuesFrom(uint64_t baseStep) {
	uint64_t nextSetStep = 0;
	int64_t nonRedundantSteps = baseStep + lookahead - currentSetSlowDACStepTotal; //upcoming nextSetStep - currentSetStep
	int start = MAX(0, lookahead - nonRedundantSteps);
	
	// "Time" in outer loop as getSequenceValue is stateful and advances sequence list
	for (int y = start; y < lookahead; y++) {
		for (int chan = 0; chan < numSlowDACChan; chan++) {
			uint64_t futureStep = (baseStep + y); 
			uint64_t currPDMIndex = futureStep % PDM_BUFF_SIZE;
			float val = getSequenceValue(futureStep, chan);

			//printf("%lld future step, %lld currPDMIndex, %f value\n", futureStep, currPDMIndex, val);
			int status = setPDMValueVolt(val, chan, currPDMIndex);

			if (status != 0) {
				printf("Could not set AO[%d] voltage.\n", chan);
			}

			/* TODO Reimplement
			if (dacSequence.data.enableLUT != NULL) {
				int sequence = futureStep / dacSequence.data.numStepsPerRepetition;
				// Within regular LUT
				bool val = false;
				if (computeInterval(&dacSequence.data, futureStep / dacSequence.data.numStepsPerRepetition, futureStep % dacSequence.data.numStepsPerRepetition) == REGULAR)  {
					val = dacSequence.data.enableLUT[(futureStep % dacSequence.data.numStepsPerRepetition) * numSlowDACChan + chan];
				}
				setEnableDAC(val, chan, currPDMIndex);
			}
			*/

			if (futureStep > nextSetStep) {
				nextSetStep = futureStep;
			}
		}
	}
	currentSetSlowDACStepTotal = nextSetStep + 1;
	//printf("%lld nextSetStep\n", nextSetStep);
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
