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
static uint64_t wpPDMStart;
static uint64_t currentSlowDACStepTotal;
static uint64_t currentSetSlowDACStepTotal; //Up to which step are the values already set
static uint64_t currentSlowDACStep;
static uint64_t currentSequenceTotal;
static uint64_t oldSlowDACStepTotal;

static int rampingTotalSteps = -1;
static int rampingSteps = -1;
static int rampingTotalSequences = -1;

static int lookahead=110;
static int lookprehead=5;

static float getSequenceVal(int step, int channel) {
	return dacSequence.slowDACLUT[(step % dacSequence.numStepsPerSequence) * dacSequence.numSlowDACChan + channel];
}

static float getFactor(uint64_t sequence, uint64_t step) {

	// Within regular LUT
	if (sequencesSlowDACEnabled <= sequence && sequence < sequencesSlowDACEnabled + dacSequence.numRepetitions) {
		return 1.0;
	}

	// Ramp up phase
	else if (sequence < sequencesSlowDACEnabled) {
		int64_t currRampUpStep = step;
		int64_t totalStepsInRampUpSequences = dacSequence.numStepsPerSequence * rampingTotalSequences;
		int64_t stepAfterRampUp = totalStepsInRampUpSequences -
			(rampingTotalSteps - rampingSteps);
		if (currRampUpStep < totalStepsInRampUpSequences - rampingTotalSteps) { // Before ramp up
			return 0.0;
		} else if (currRampUpStep < stepAfterRampUp) { // Within ramp up
			int64_t currRampUpStep_ = currRampUpStep - (totalStepsInRampUpSequences - rampingTotalSteps);
			return (0.9640 + tanh(-2.0 + (currRampUpStep_ / ((float)rampingSteps - 1)) * 4.0)) / 1.92806;
		} else {
			return 1.0;
		}
	}

	// Ramp down phase
	else if (sequence >= sequencesSlowDACEnabled + dacSequence.numRepetitions) {
		int64_t totalStepsFromRampUp = dacSequence.numStepsPerSequence *
			(rampingTotalSequences + dacSequence.numRepetitions);
		int64_t currRampDownStep = step - totalStepsFromRampUp;

		if (currRampDownStep > rampingTotalSteps) { // After ramp down
			return 0.0;
		} else if (currRampDownStep > (rampingTotalSteps - rampingSteps)) { // Within ramp down
			int64_t currRampDownStep_ = currRampDownStep - (rampingTotalSteps - rampingSteps);
			return (0.9640 + tanh(-2.0 + ((rampingSteps - currRampDownStep_ - 1) / ((float)rampingSteps - 1)) * 4.0)) / 1.92806;
		} else {
			return 1.0;
		}
	}

	return 0.0;
}

static float getSlowDACVal(int step, int i) {
	uint64_t sequence = step / dacSequence.numStepsPerSequence;
	float val = getSequenceVal(step, i);
	float factor = getFactor(sequence, step);
	return factor * val;
}

static void initSlowDAC() {
	// Compute Ramping timing
	double bandwidth = 125e6 / getDecimation();
	double period = (numSamplesPerSlowDACStep * dacSequence.numStepsPerSequence) / bandwidth;
	rampingTotalSequences = ceil(dacSequence.slowDACRampUpTime / period);
	rampingTotalSteps = ceil(dacSequence.slowDACRampUpTime / (numSamplesPerSlowDACStep / bandwidth));
	rampingSteps = ceil(dacSequence.slowDACRampUpTime * dacSequence.slowDACFractionRampUp / (numSamplesPerSlowDACStep / bandwidth));
	currentSetSlowDACStepTotal = 0;

	for (int d = 0; d < 2; d++) {
		for (int c = 0; c < 4; c++) {
			setAmplitude(dacSequence.fastDACAmplitude[c + 4 * d], d, c);
		}
	}

	for (int d = 0; d < dacSequence.numSlowDACChan; d++) {
		setEnableDACAll(1, d);
	}

	//Reset Lost Steps Flag
	err.lostSteps = 0;
}

static void cleanUpSlowDAC() {
	stopTx();
}

static void setLUTValuesFrom(uint64_t baseStep) {
	uint64_t nextSetStep = 0;
	int64_t nonRedundantSteps = baseStep + lookahead - 1 - currentSetSlowDACStepTotal; //upcoming nextSetStep - currentSetStep
	int start = 0;
	start = MAX(lookprehead, MAX(0, lookahead - nonRedundantSteps));
	//printf("%i\n", start);

	for (int i = 0; i < dacSequence.numSlowDACChan; i++) {
		//lookahead
		for (int y = start; y < lookahead; y++) {
			uint64_t localStep = (baseStep + y);
			uint64_t currPDMIndex = (wpPDMStart + localStep) % PDM_BUFF_SIZE;
			float val = getSlowDACVal(localStep, i);

			int status = setPDMValueVolt(val, i, currPDMIndex);

			if (status != 0) {
				printf("Could not set AO[%d] voltage.\n", i);
			}

			if (dacSequence.enableDACLUT != NULL) {
				int sequence = localStep / dacSequence.numStepsPerSequence;
				// Within regular LUT
				bool val = false;
				if (sequencesSlowDACEnabled <= sequence < sequencesSlowDACEnabled + dacSequence.numRepetitions) {
					val = dacSequence.enableDACLUT[(localStep % dacSequence.numStepsPerSequence) * dacSequence.numSlowDACChan + i];
				}
				setEnableDAC(val, i, currPDMIndex);
			}

			if (localStep > nextSetStep) {
				nextSetStep = localStep;
			}
		}
	}
	currentSetSlowDACStepTotal = nextSetStep;
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

	//	printf("dc: %lld, udc: %lld, ds: %lld\n", deltaControl, avgDeltaControl, deltaSet);

}

void *controlThread(void *ch) {
	rampingTotalSteps = -1;
	rampingSteps = -1;
	rampingTotalSequences = -1;
	//Performance related variables
	float alpha = 0.7;

	bool prepared = false;

	//Sleep
	int baseSleep = 20;
	int sleep;

	LOG_INFO("Starting control thread");
	getprio(pthread_self());

	while (controlThreadRunning) {
		if (getMasterTrigger()) {

			// Handle sequence
			wp = getTotalWritePointer();
			currentSlowDACStepTotal = wp / numSamplesPerSlowDACStep;

			if (currentSlowDACStepTotal > oldSlowDACStepTotal) {
				currentSequenceTotal = wp / (numSamplesPerSlowDACStep * dacSequence.numStepsPerSequence);
				currentSlowDACStep = currentSlowDACStepTotal % dacSequence.numStepsPerSequence;

				if (currentSlowDACStepTotal > oldSlowDACStepTotal + (lookahead - lookprehead) && dacSequence.numStepsPerSequence > 1) {
					handleLostSlowDACSteps(oldSlowDACStepTotal, currentSlowDACStepTotal);
				}

				if (dacSequence.numRepetitions > 0 && sequencesSlowDACEnabled > 0 && (currentSequenceTotal >= dacSequence.numRepetitions + sequencesSlowDACEnabled + rampingTotalSequences)) {
					// We now have measured enough rotations and switch of the slow DAC
					cleanUpSlowDAC();
				} else {
					setLUTValuesFrom(currentSlowDACStep);

					updatePerformance(alpha);
				}
			} else {
				sleep += baseSleep;
			}
			oldSlowDACStepTotal = currentSlowDACStepTotal;
			usleep(sleep);

		} else {
			if (!prepared && dacSequence.slowDACLUT != NULL) {
				initSlowDAC();
				avgDeltaControl = 0;
				avgDeltaSet = 0;
				minDeltaControl = 0xFF;
				maxDeltaSet = 0x00;
				sleep = baseSleep;
				prepared = true;
				setLUTValuesFrom(0);
				printf("Prepared Sequence\n");
			} else {
				usleep(sleep);
				if (!getMasterTrigger()) { // ??????
					prepared = false;
				}
			}
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
