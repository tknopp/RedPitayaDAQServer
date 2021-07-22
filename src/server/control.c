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

#include "../lib/rp-daq-lib.h"
#include "../server/daq_server_scpi.h"
#include "logger.h"

static uint64_t wp;
static uint64_t currentSlowDACStepTotal;
static uint64_t currentSetSlowDACStepTotal; //Up to which step are the values already set
static uint64_t currentSequenceTotal;
static uint64_t oldSlowDACStepTotal;

static int lookahead=110;

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

float getLookupSequenceValue(sequenceData_t *seqData, int step, int channel) {
	if (seqData->type == LOOKUP) {
		return seqData->LUT[step * seqData->numSlowDACChan + channel];
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
		//TODO Implement range computation per channel
		return 1;
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
		else {
			return AFTER;
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
			int stepsInRampDown = localStep - stepsUpToRampDown;
			return rampingFunction((float) (seqData->rampingSteps - stepsInRampDown), (float) seqData->rampingSteps - 1);
		case BEFORE:
		case AFTER:
		default:
			return 0;
	}
}

static float getSlowDACVal(int step, int i) {
	uint64_t localRepetition = step / dacSequence.data.numStepsPerRepetition;
	int localStep = step % dacSequence.data.numStepsPerRepetition;
	float val = getSequenceVal(&dacSequence, localStep, i);
	float factor = getFactor(&dacSequence.data, localRepetition, localStep);
	//printf("%d ", computeInterval(&dacSequence.data, localRepetition, localStep));
	return factor * val;
}

void setupRampingTiming(sequenceData_t *seqData, double rampUpTime, double rampUpFraction) {
	double bandwidth = 125e6 / getDecimation();
	double period = (numSamplesPerSlowDACStep * dacSequence.data.numStepsPerRepetition) / bandwidth;
	seqData->rampingRepetitions = ceil(rampUpTime / period);
	seqData->rampingTotalSteps = ceil(rampUpTime / (numSamplesPerSlowDACStep / bandwidth));
	seqData->rampingSteps = ceil(rampUpTime * rampUpFraction / (numSamplesPerSlowDACStep / bandwidth));
}

static void initSlowDAC() {
	// Compute Ramping timing	
	setupRampingTiming(&dacSequence.data, rampUpTime, rampUpFraction);

	for (int d = 0; d < dacSequence.data.numSlowDACChan; d++) {
		setEnableDACAll(1, d);
	}

	//Reset Lost Steps Flag
	err.lostSteps = 0;
}

static void cleanUpSlowDAC() {
	stopTx();
	cleanUpSequence(&dacSequence.data);
	sequencePrepared = false;
}

static void setLUTValuesFrom(uint64_t baseStep) {
	uint64_t nextSetStep = 0;
	int64_t nonRedundantSteps = baseStep + lookahead - currentSetSlowDACStepTotal; //upcoming nextSetStep - currentSetStep
	int start = MAX(0, lookahead - nonRedundantSteps);
	printf("Set values from base %lld\n", baseStep);
	for (int i = 0; i < dacSequence.data.numSlowDACChan; i++) {
		//lookahead
		for (int y = start; y < lookahead; y++) {
			uint64_t localStep = (baseStep + y); //Rename to future step or w/e, local refers to something else now
			uint64_t currPDMIndex = localStep % PDM_BUFF_SIZE;
			float val = getSlowDACVal(localStep, i);

			//printf("%lld future step, %lld currPDMIndex, %f value\n", localStep, currPDMIndex, val);
			int status = setPDMValueVolt(val, i, currPDMIndex);

			if (status != 0) {
				printf("Could not set AO[%d] voltage.\n", i);
			}

			if (dacSequence.data.enableLUT != NULL) {
				int sequence = localStep / dacSequence.data.numStepsPerRepetition;
				// Within regular LUT
				bool val = false;
				if (computeInterval(&dacSequence.data, localStep / dacSequence.data.numStepsPerRepetition, localStep % dacSequence.data.numStepsPerRepetition) == REGULAR)  {
					val = dacSequence.data.enableLUT[(localStep % dacSequence.data.numStepsPerRepetition) * dacSequence.data.numSlowDACChan + i];
				}
				setEnableDAC(val, i, currPDMIndex);
			}

			if (localStep > nextSetStep) {
				nextSetStep = localStep;
			}
		}
	}
	currentSetSlowDACStepTotal = nextSetStep + 1;
	//printf("%lld nextSetStep\n", nextSetStep);
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
	sequencePrepared = false;
	bool sequenceFinished = false;
	currentSetSlowDACStepTotal = 0;

	//Sleep
	int baseSleep = 20;
	int sleepTime = baseSleep;

	//If not initialized then image not loaded and mmaped
	while(!initialized) {
		sleep(1);
	}

	printf("Entering control loop\n");

	while (controlThreadRunning) {
		if (getMasterTrigger() && !sequenceFinished) {
			// Handle sequence
			wp = getTotalWritePointer();
			currentSlowDACStepTotal = wp / numSamplesPerSlowDACStep;
			
			sequencePrepared = false;

			if (currentSlowDACStepTotal > oldSlowDACStepTotal) {
				
				currentSequenceTotal = wp / (numSamplesPerSlowDACStep * dacSequence.data.numStepsPerRepetition);
			
				if (currentSlowDACStepTotal > oldSlowDACStepTotal + lookahead && dacSequence.data.numStepsPerRepetition > 1) {
					handleLostSlowDACSteps(oldSlowDACStepTotal, currentSlowDACStepTotal);
				}

				if (dacSequence.data.numRepetitions > 0 && computeInterval(&dacSequence.data, currentSequenceTotal, currentSlowDACStepTotal) == AFTER) {
					// We now have measured enough rotations and switch of the slow DAC
					cleanUpSlowDAC();
					sequenceFinished = true;
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
			if (!sequencePrepared && dacSequence.data.LUT != NULL) {
				printf("Preparing Sequence\n");
				initSlowDAC();
				avgDeltaControl = 0;
				avgDeltaSet = 0;
				minDeltaControl = 0xFF;
				maxDeltaSet = 0x00;
				sleepTime = baseSleep;
				sequencePrepared = true;
				setLUTValuesFrom(0);
				printf("Prepared Sequence\n");
				sequenceFinished = false;
			}
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
