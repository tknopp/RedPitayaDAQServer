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
#include <netinet/tcp.h>

#include "scpi/scpi.h"

#include "../lib/rp-daq-lib.h"
#include "../server/daq_server_scpi.h"

static scpi_result_t returnSCPIBool(scpi_t* context, bool val) {
	if (val) {
		SCPI_ResultBool(context, val);
		return SCPI_RES_OK;
	}
	else {
		SCPI_ResultBool(context, val);
		return SCPI_RES_ERR;
	}
}

static void readyConfigSequence() {
	if (configNode == NULL) {
		configNode = newSequenceNode();
	}
}

scpi_choice_def_t server_modes[] = {
	{"CONFIGURATION", CONFIGURATION},
	{"ACQUISITION", ACQUISITION},
	{"TRANSMISSION", TRANSMISSION},
	SCPI_CHOICE_LIST_END
};

static scpi_result_t RP_GetServerMode(scpi_t * context) {
	const char * name;
	SCPI_ChoiceToName(server_modes, getServerMode(), &name);
	SCPI_ResultText(context, name);
	return SCPI_RES_OK;
}

static scpi_result_t RP_SetServerMode(scpi_t * context) {
	int32_t tmpMode;
	
	if (!SCPI_ParamChoice(context, server_modes, &tmpMode, TRUE)) {
		return returnSCPIBool(context, false);
	}

	serverMode_t current = getServerMode();
	if (current != TRANSMISSION && (tmpMode == CONFIGURATION || tmpMode == ACQUISITION)) {
		setServerMode((serverMode_t) tmpMode);
		return returnSCPIBool(context, true);
	}

	return returnSCPIBool(context, false);
}

static scpi_result_t RP_DAC_GetAmplitude(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	SCPI_ResultDouble(context, getAmplitude(channel, component) / 8192.0 );

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetAmplitude(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double amplitude;
	if (!SCPI_ParamDouble(context, &amplitude, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setAmplitudeVolt(amplitude, channel, component);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	printf("channel = %d; component = %d, amplitude = %f\n", channel, component, amplitude);

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetSequenceAmplitude(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double amplitude;
	if (!SCPI_ParamDouble(context, &amplitude, TRUE)) {
		return returnSCPIBool(context, false);
	}

	if (!isSequenceConfigurable()) 
		return returnSCPIBool(context, false);
	
	readyConfigSequence(); 

	uint16_t ampValue = (uint16_t) (amplitude*8192.0);	
	configNode->sequence.fastConfig.amplitudes[channel * 4 + component] = ampValue;
	configNode->sequence.fastConfig.amplitudesSet[channel * 4 + component] = true;
	seqState = CONFIG;

	return returnSCPIBool(context, true);
}


static scpi_result_t RP_DAC_GetOffset(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double offset = getOffset(channel)/8192.0;
	SCPI_ResultDouble(context, offset);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetOffset(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double offset;
	if (!SCPI_ParamDouble(context, &offset, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setOffsetVolt(offset, channel);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}


static scpi_result_t RP_DAC_SetSequenceOffset(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double offset;
	if (!SCPI_ParamDouble(context, &offset, TRUE)) {
		return returnSCPIBool(context, false);
	}

	if (!isSequenceConfigurable()) 
		return returnSCPIBool(context, false);

	readyConfigSequence();

	configNode->sequence.fastConfig.offset[channel] = offset;
	configNode->sequence.fastConfig.offsetSet[channel] = true;
	seqState = CONFIG;

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetRampingFast(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double period;
	if (!SCPI_ParamDouble(context, &period, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setRampingFrequency(1/period, channel);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetRampingFast(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double period = getRampingFrequency(channel);
	SCPI_ResultDouble(context, 1/period);
	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetFrequency(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double freq = getFrequency(channel, component);
	SCPI_ResultDouble(context, freq);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetFrequency(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double frequency;
	if (!SCPI_ParamDouble(context, &frequency, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setFrequency(frequency, channel, component);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}


static scpi_result_t RP_DAC_SetSequenceFrequency(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double frequency;
	if (!SCPI_ParamDouble(context, &frequency, TRUE)) {
		return returnSCPIBool(context, false);
	}

	if (!isSequenceConfigurable()) 
		return returnSCPIBool(context, false);

	readyConfigSequence();

	configNode->sequence.fastConfig.frequency[channel * 4 + component] = frequency;
	configNode->sequence.fastConfig.frequencySet[channel * 4 + component] = true;
	seqState = CONFIG;
	
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetPhase(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	SCPI_ResultDouble(context, getPhase(channel, component));

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetPhase(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double phase;
	if (!SCPI_ParamDouble(context, &phase, TRUE)) {
		return returnSCPIBool(context, false);
	}
	printf("channel = %d; component = %d, phase = %f\n", channel, component, phase);

	int result = setPhase(phase, channel, component);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetSequencePhase(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double phase;
	if (!SCPI_ParamDouble(context, &phase, TRUE)) {
		return returnSCPIBool(context, false);
	}
	
	if (!isSequenceConfigurable()) 
		return returnSCPIBool(context, false);

	readyConfigSequence();

	configNode->sequence.fastConfig.phase[channel * 4 + component] = phase;
	configNode->sequence.fastConfig.phaseSet[channel * 4 + component] = true;
	seqState = CONFIG;
	

	return returnSCPIBool(context, true);
}

scpi_choice_def_t DAC_modes[] = {
	{"STANDARD", DAC_MODE_STANDARD},
	{"AWG", DAC_MODE_AWG},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_DAC_SetDACMode(scpi_t * context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	int32_t DAC_mode_selection;

	if (!SCPI_ParamChoice(context, DAC_modes, &DAC_mode_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setDACMode(DAC_mode_selection);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetDACMode(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(DAC_modes, getDACMode(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

scpi_choice_def_t trigger_modes[] = {
	{"INTERNAL", TRIGGER_MODE_INTERNAL},
	{"EXTERNAL", TRIGGER_MODE_EXTERNAL},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_DAC_SetTriggerMode(scpi_t * context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	int32_t trigger_mode_selection;

	if (!SCPI_ParamChoice(context, trigger_modes, &trigger_mode_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setTriggerMode(trigger_mode_selection);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetTriggerMode(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(trigger_modes, getTriggerMode(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

scpi_choice_def_t signal_types[] = {
	{"SINE", SIGNAL_TYPE_SINE},
	{"SQUARE", SIGNAL_TYPE_SQUARE},
	{"TRIANGLE", SIGNAL_TYPE_TRIANGLE},
	{"SAWTOOTH", SIGNAL_TYPE_SAWTOOTH},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_DAC_SetSignalType(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	int32_t signal_type_selection;

	if (!SCPI_ParamChoice(context, signal_types, &signal_type_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setSignalType(signal_type_selection, channel, component);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}


static scpi_result_t RP_DAC_SetSequenceSignalType(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	int32_t signal_type_selection;

	if (!SCPI_ParamChoice(context, signal_types, &signal_type_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	if (!isSequenceConfigurable()) 
		return returnSCPIBool(context, false);

	readyConfigSequence();

	configNode->sequence.fastConfig.signalType[channel] = signal_type_selection;
	configNode->sequence.fastConfig.signalTypeSet[channel] = true;
	seqState = CONFIG;

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetSignalType(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	const char * name;

	SCPI_ChoiceToName(signal_types, getSignalType(channel, component), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetJumpSharpness(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	SCPI_ResultDouble(context, getJumpSharpness(channel, component));

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetJumpSharpness(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];
	
	double percentage;
	if (!SCPI_ParamDouble(context, &percentage, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setJumpSharpness(percentage, channel, component);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetSequenceJumpSharpness(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double percentage;
	if (!SCPI_ParamDouble(context, &percentage, TRUE)) {
		return returnSCPIBool(context, false);
	}

	if (!isSequenceConfigurable()) 
		return returnSCPIBool(context, false);

	readyConfigSequence();

	configNode->sequence.fastConfig.jumpSharpness[channel] = percentage;
	configNode->sequence.fastConfig.jumpSharpnessSet[channel] = true;
	seqState = CONFIG;

	return returnSCPIBool(context, true);
}



static scpi_result_t RP_ADC_SetDecimation(scpi_t * context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	uint32_t decimation;
	if (!SCPI_ParamInt32(context, &decimation, TRUE)) {
		return returnSCPIBool(context, false);
	}

	printf("set dec = %d \n", decimation);
	int result = setDecimation((uint16_t)decimation);
	if (result < 0) {
		printf("Could not set decimation!");
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_ADC_GetDecimation(scpi_t * context) {
	uint16_t dec = getDecimation();
	
	SCPI_ResultUInt16(context, dec);
	return SCPI_RES_OK;
}


static scpi_result_t RP_DAC_SetSamplesPerStep(scpi_t * context) {
	if(!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	if (!SCPI_ParamInt32(context, &numSamplesPerStep, TRUE)) {
		return returnSCPIBool(context, false);
	}

	// Adapt the slowDAC frequency to match the step length
	setPDMClockDivider(numSamplesPerStep * getDecimation());
	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetSamplesPerStep(scpi_t * context) {
	SCPI_ResultInt32(context, numSamplesPerStep);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetStepsPerRepetition(scpi_t * context) {
	if(!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	readyConfigSequence(); 

	if (!SCPI_ParamInt32(context, &(configNode->sequence).data.numStepsPerRepetition, TRUE)) {
		return returnSCPIBool(context, false);
	}


	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetStepsPerRepetition(scpi_t * context) {
	SCPI_ResultInt32(context, (configNode->sequence).data.numStepsPerRepetition);

	return SCPI_RES_OK;
}



static scpi_result_t RP_ADC_SetSeqClockDivider(scpi_t * context) {
	if(!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}
	int32_t clockDiv = 1;

	if (!SCPI_ParamInt32(context, &clockDiv, TRUE)) {
		return returnSCPIBool(context, false);
	}

	setPDMClockDivider(clockDiv);
	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_ADC_GetSeqClockDivider(scpi_t * context) {
	SCPI_ResultInt32(context, getPDMClockDivider());

	return SCPI_RES_OK;
}



static scpi_result_t RP_DAC_SetNumSlowDACChan(scpi_t * context) {
	if(!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	readyConfigSequence();

	if (!SCPI_ParamInt32(context, &numSlowDACChan, TRUE)) {
		return returnSCPIBool(context, false);
	}

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetNumSlowDACChan(scpi_t * context) {
	SCPI_ResultInt32(context, numSlowDACChan);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetSlowDACLostSteps(scpi_t * context) {
	SCPI_ResultInt32(context, numSlowDACLostSteps);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetRamping(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);

	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpSteps, TRUE)) 
		return returnSCPIBool(context, false);

	if (!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpTotalSteps, TRUE))
		return returnSCPIBool(context, false);

	configNode->sequence.data.rampDownSteps = configNode->sequence.data.rampUpSteps;
	configNode->sequence.data.rampDownTotalSteps = configNode->sequence.data.rampUpTotalSteps;
	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetRampUp(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);

	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpSteps, TRUE)) 
		return returnSCPIBool(context, false);

	if (!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpTotalSteps, TRUE))
		return returnSCPIBool(context, false);

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetRampDown(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);

	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampDownSteps, TRUE)) 
		return returnSCPIBool(context, false);

	if (!SCPI_ParamInt32(context, &configNode->sequence.data.rampDownTotalSteps, TRUE))
		return returnSCPIBool(context, false);

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetRampingSteps(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);

	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpSteps, TRUE)) 
		return returnSCPIBool(context, false);

	configNode->sequence.data.rampDownSteps = configNode->sequence.data.rampUpSteps;
	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetRampingTotalSteps(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);
	
	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpTotalSteps, TRUE)) 
		return returnSCPIBool(context, false);

	configNode->sequence.data.rampDownTotalSteps = configNode->sequence.data.rampUpTotalSteps;
	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetRampUpSteps(scpi_t * context) {
	readyConfigSequence();
	SCPI_ResultInt32(context, configNode->sequence.data.rampUpSteps);
	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetRampUpSteps(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);

	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpSteps, TRUE)) 
		return returnSCPIBool(context, false);

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetRampUpTotalSteps(scpi_t * context) {
	readyConfigSequence();
	SCPI_ResultInt32(context, configNode->sequence.data.rampUpTotalSteps);
	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetRampUpTotalSteps(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);

	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampUpTotalSteps, TRUE)) 
		return returnSCPIBool(context, false);

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetRampDownSteps(scpi_t * context) {
	readyConfigSequence();
	SCPI_ResultInt32(context, configNode->sequence.data.rampDownSteps);
	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetRampDownSteps(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);
	
	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampDownSteps, TRUE)) 
		return returnSCPIBool(context, false);

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetRampDownTotalSteps(scpi_t * context) {
	readyConfigSequence();
	SCPI_ResultInt32(context, configNode->sequence.data.rampDownTotalSteps);
	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetRampDownTotalSteps(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);
	
	readyConfigSequence();

	if(!SCPI_ParamInt32(context, &configNode->sequence.data.rampDownTotalSteps, TRUE)) 
		return returnSCPIBool(context, false);

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetSequenceRepetitions(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);

	readyConfigSequence();

	if (!SCPI_ParamInt32(context, &(configNode->sequence).data.numRepetitions, TRUE))
		return returnSCPIBool(context, false);

	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetSequenceRepetitions(scpi_t * context) {
	SCPI_ResultInt32(context, (configNode->sequence).data.numRepetitions);
	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_SlowDACInterpolation(scpi_t * context) {
	if (getServerMode() != CONFIGURATION) {
		return SCPI_RES_ERR;
	}

	int32_t tmp;
	if (!SCPI_ParamInt32(context, &tmp, TRUE)) {
		return SCPI_RES_ERR;
	}
	slowDACInterpolation = (tmp == 1);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_SetNumSlowADCChan(scpi_t * context) {
	if(!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	if (!SCPI_ParamInt32(context, &numSlowADCChan, TRUE)) {
		return returnSCPIBool(context, false);
	}
	
	seqState = CONFIG;
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_ADC_GetNumSlowADCChan(scpi_t * context) {
	SCPI_ResultInt32(context, numSlowADCChan);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetCurrentWP(scpi_t * context) {
	SCPI_ResultUInt64(context, getTotalWritePointer());
	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetBufferSize(scpi_t * context) {
	SCPI_ResultUInt64(context, ADC_BUFF_SIZE);
	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetData(scpi_t * context) {
	// Reading is only possible while an acquisition is running
	if (getServerMode() != ACQUISITION) {
		return returnSCPIBool(context, false);
	}

	uint64_t reqWP;
	if (!SCPI_ParamInt64(context, &reqWP, TRUE)) {
		return returnSCPIBool(context, false);
	}

	uint64_t numSamples;
	if (!SCPI_ParamInt64(context, &numSamples, TRUE)) {
		return returnSCPIBool(context, false);
	}

	transmissionState = SIMPLE;
	return SCPI_ResultBool(context, true); // Signal that server starts sending
}

static scpi_result_t RP_ADC_GetPipelinedData(scpi_t * context) {
	if (getServerMode() != ACQUISITION) {
		return returnSCPIBool(context, false);
	}
	
	if (!SCPI_ParamInt64(context, &reqWP, TRUE)) {
		return returnSCPIBool(context, false);
	}

	if (!SCPI_ParamInt64(context, &numSamples, TRUE)) {
		return returnSCPIBool(context, false);
	}

	if (!SCPI_ParamInt64(context, &chunkSize, TRUE)) {
		return returnSCPIBool(context, false);
	}

	transmissionState = PIPELINE;
	return SCPI_ResultBool(context, true); // Signal that server starts sending;

}

static scpi_result_t RP_ADC_Slow_GetFrames(scpi_t * context) {
	// Reading is only possible while an acquisition is running
	if (getServerMode() != ACQUISITION) {
		return SCPI_RES_ERR;
	}

	int64_t frame;
	if (!SCPI_ParamInt64(context, &frame, TRUE)) {
		return SCPI_RES_ERR;
	}

	int64_t numFrames;
	if (!SCPI_ParamInt64(context, &numFrames, TRUE)) {
		return SCPI_RES_ERR;
	}

	//printf("invoke sendDataToHost()");
	//sendSlowFramesToHost(frame, numFrames);

	return SCPI_RES_OK;
}

static scpi_result_t RP_XADC_GetXADCValueVolt(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double val = getXADCValueVolt(channel);

	printf("XADC value = %f \n", val);

	SCPI_ResultDouble(context, val);

	return SCPI_RES_OK;
}

scpi_choice_def_t inout_modes[] = {
	{"IN", IN},
	{"OUT", OUT},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_DIO_GetDIODirection(scpi_t * context) {
	const char* pin;
	size_t len;
	if (!SCPI_ParamCharacters(context, &pin, &len, TRUE)) {
		return returnSCPIBool(context, false);
	}

	const char* name;

	int result = getDIODirection(pin);

	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	SCPI_ChoiceToName(inout_modes, result, &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DIO_SetDIODirection(scpi_t * context) {
	const char* pin;
	size_t len;
	if (!SCPI_ParamCharacters(context, &pin, &len, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int32_t DIO_pin_output_selection;
	if (!SCPI_ParamChoice(context, inout_modes, &DIO_pin_output_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setDIODirection(pin, DIO_pin_output_selection);
	if (result < 0) {
		return returnSCPIBool(context, true);
	}

	return SCPI_RES_OK;
}

scpi_choice_def_t onoff_modes[] = {
	{"OFF", OFF},
	{"ON", ON},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_DIO_SetDIOOutput(scpi_t * context) {
	const char* pin;
	size_t len;
	if (!SCPI_ParamCharacters(context, &pin, &len, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int32_t DIO_pin_output_selection;
	if (!SCPI_ParamChoice(context, onoff_modes, &DIO_pin_output_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setDIO(pin, DIO_pin_output_selection);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DIO_GetDIOOutput(scpi_t * context) {
	const char* pin;
	size_t len;
	if (!SCPI_ParamCharacters(context, &pin, &len, TRUE)) {
		return returnSCPIBool(context, false);
	}

	const char* name;

	int result = getDIO(pin);

	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	SCPI_ChoiceToName(onoff_modes, result,  &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_GetWatchdogMode(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getWatchdogMode(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetWatchdogMode(scpi_t * context) {
	int32_t watchdog_mode_selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &watchdog_mode_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setWatchdogMode(watchdog_mode_selection);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_GetPassPDMToFastDAC(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getPassPDMToFastDAC(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetPassPDMToFastDAC(scpi_t * context) {
	if (!isSequenceConfigurable())
		return returnSCPIBool(context, false);


	int32_t selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setPassPDMToFastDAC(selection);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

scpi_choice_def_t RAM_writer_modes[] = {
	{"CONTINUOUS", ADC_MODE_CONTINUOUS},
	{"TRIGGERED", ADC_MODE_TRIGGERED},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_GetRAMWriterMode(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(RAM_writer_modes, getRAMWriterMode(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetRAMWriterMode(scpi_t * context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	int32_t RAM_writer_mode_selection;

	if (!SCPI_ParamChoice(context, RAM_writer_modes, &RAM_writer_mode_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setRAMWriterMode(RAM_writer_mode_selection);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_GetMasterTrigger(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getMasterTrigger(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetMasterTrigger(scpi_t * context) {
	if (getServerMode() != ACQUISITION) {
		return returnSCPIBool(context, false);
	}

	int32_t master_trigger_selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &master_trigger_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setMasterTrigger(master_trigger_selection);
	if (master_trigger_selection == OFF) {
		setEnableRampDown(OFF, 0);
		setEnableRampDown(OFF, 1);
	}
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_SetEnableRamping(scpi_t *context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	int32_t ramping_selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &ramping_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setEnableRamping(ramping_selection, channel);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);

}

static scpi_result_t RP_DAC_GetEnableRamping(scpi_t *context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	const char * name;

	SCPI_ChoiceToName(onoff_modes, getEnableRamping(channel), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetEnableRampDown(scpi_t *context) {
	if (!(getServerMode() == ACQUISITION || getServerMode() == TRANSMISSION)) {
		return returnSCPIBool(context, false);
	}

	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	int32_t ramping_selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &ramping_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setEnableRampDown(ramping_selection, channel);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);

}

static scpi_result_t RP_DAC_GetEnableRampDown(scpi_t *context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	const char * name;

	SCPI_ChoiceToName(onoff_modes, getEnableRampDown(channel), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetRampingStatus(scpi_t *context) {
	int status = getRampingState();
	SCPI_ResultInt(context, status);
	return SCPI_RES_OK;
}

static scpi_result_t RP_GetKeepAliveReset(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getKeepAliveReset(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetKeepAliveReset(scpi_t * context) {
	if (getServerMode() != ACQUISITION) {
		return returnSCPIBool(context, false);
	}

	int32_t param;

	if (!SCPI_ParamChoice(context, onoff_modes, &param, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setKeepAliveReset(param);
	if (param == OFF) {
		setEnableRampDown(OFF, 0);
		setEnableRampDown(OFF, 1);
	}
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}



static scpi_result_t RP_GetInstantResetMode(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getInstantResetMode(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetInstantResetMode(scpi_t * context) {
	int32_t instant_reset_mode_selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &instant_reset_mode_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	int result = setInstantResetMode(instant_reset_mode_selection);
	if (result < 0) {
		return returnSCPIBool(context, false);
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_PeripheralAResetN(scpi_t * context) {
	SCPI_ResultBool(context, getPeripheralAResetN());

	return SCPI_RES_OK;
}

static scpi_result_t RP_FourierSynthAResetN(scpi_t * context) {
	SCPI_ResultBool(context, getFourierSynthAResetN());

	return SCPI_RES_OK;
}

static scpi_result_t RP_PDMAResetN(scpi_t * context) {
	SCPI_ResultBool(context, getPDMAResetN());

	return SCPI_RES_OK;
}

static scpi_result_t RP_WriteToRAMAResetN(scpi_t * context) {
	SCPI_ResultBool(context, getWriteToRAMAResetN());

	return SCPI_RES_OK;
}

static scpi_result_t RP_XADCAResetN(scpi_t * context) {
	SCPI_ResultBool(context, getXADCAResetN());

	return SCPI_RES_OK;
}

static scpi_result_t RP_WatchdogStatus(scpi_t * context) {
	SCPI_ResultBool(context, getWatchdogStatus());

	return SCPI_RES_OK;
}

static scpi_result_t RP_InstantResetStatus(scpi_t * context) {
	SCPI_ResultBool(context, getInstantResetStatus());

	return SCPI_RES_OK;
}

static int readAll(int fd, void *buf,  size_t len) {
	size_t left = len;
	size_t n = 0;
	char *ptr = (char*) buf;

	while(left > 0) {
		n = read(fd, ptr, left);
		if (n <= 0) {
			return n;
		}
		ptr += n;
		left -= n;
	}
	
	return len;
}

static scpi_result_t RP_DAC_SetArbitraryLUT(scpi_t * context) {

	readyConfigSequence();

	if((configNode->sequence).data.numStepsPerRepetition > 0 && numSlowDACChan > 0 && isSequenceConfigurable()) {
		if((configNode->sequence).data.LUT != NULL) {
			free((configNode->sequence).data.LUT);
			(configNode->sequence).data.LUT = NULL;
		}
		printf("Allocating slowDACLUT\n");
		float * temp  = (float *)calloc(numSlowDACChan, (configNode->sequence).data.numStepsPerRepetition * sizeof(float));

		int n = readAll(newdatasockfd, temp, numSlowDACChan * (configNode->sequence).data.numStepsPerRepetition * sizeof(float));
		if (n < 0) perror("ERROR reading from socket");
	
		printf("Setting Arbitray LUT\n");
		(configNode->sequence).getSequenceValue = &getArbitrarySequenceValue;
		(configNode->sequence).data.type = ARBITRARY;
		(configNode->sequence).data.LUT = temp;
		seqState = CONFIG;
		return returnSCPIBool(context, true);
	}
	else {
		return returnSCPIBool(context, false);
	}
}

static scpi_result_t RP_DAC_SetConstantLUT(scpi_t * context) {

	readyConfigSequence();
	
	if((configNode->sequence).data.numStepsPerRepetition > 0 && numSlowDACChan > 0 && isSequenceConfigurable()) {
		if((configNode->sequence).data.LUT != NULL) {
			free((configNode->sequence).data.LUT);
			(configNode->sequence).data.LUT = NULL;
		}
		printf("Allocating slowDACLUT\n");
		float * temp  = (float *)calloc(numSlowDACChan, sizeof(float));

		int n = readAll(newdatasockfd, temp, numSlowDACChan * sizeof(float));
		if (n < 0) perror("ERROR reading from socket");
	
		printf("Setting Constant LUT\n");
		(configNode->sequence).data.LUT = temp;
		(configNode->sequence).getSequenceValue = &getConstantSequenceValue;
		(configNode->sequence).data.type = CONSTANT;
		seqState = CONFIG;
		return returnSCPIBool(context, true);
	}
	else {
		return returnSCPIBool(context, false);
	}
}

static scpi_result_t RP_DAC_SetPauseLUT(scpi_t * context) {

	readyConfigSequence();

	if((configNode->sequence).data.numStepsPerRepetition > 0 && numSlowDACChan > 0 && isSequenceConfigurable()) {
		if((configNode->sequence).data.LUT != NULL) {
			free((configNode->sequence).data.LUT);
			(configNode->sequence).data.LUT = NULL;
		}
		printf("Allocating slowDACLUT\n");
		float * temp  = (float *)calloc(1, sizeof(float)); //Place holder for != NULL

		printf("Setting Pause LUT\n");
		(configNode->sequence).data.LUT = temp;
		(configNode->sequence).getSequenceValue = &getPauseSequenceValue;
		(configNode->sequence).data.type = PAUSE;
		seqState = CONFIG;
		return returnSCPIBool(context, true);
	}
	else {
		return returnSCPIBool(context, false);
	}
}

static scpi_result_t RP_DAC_SetRangeLUT(scpi_t * context) {

	readyConfigSequence();

	if((configNode->sequence).data.numStepsPerRepetition > 0 && numSlowDACChan > 0 && isSequenceConfigurable()) {
		if((configNode->sequence).data.LUT != NULL) {
			free((configNode->sequence).data.LUT);
			(configNode->sequence).data.LUT = NULL;
		}
		printf("Allocating slowDACLUT\n");
		float * temp  = (float *)calloc(numSlowDACChan * 2,  sizeof(float));

		int n = readAll(newdatasockfd, temp, numSlowDACChan * 2 * sizeof(float));
		if (n < 0) perror("ERROR reading from socket");
	
		printf("Setting Range LUT\n");
		(configNode->sequence).data.LUT = temp;
		(configNode->sequence).getSequenceValue = &getRangeSequenceValue;
		(configNode->sequence).data.type = RANGE;
		seqState = CONFIG;
		return returnSCPIBool(context, true);
	}
	else {
		return returnSCPIBool(context, false);
	}
}

static scpi_result_t RP_DAC_SetEnableDACLUT(scpi_t * context) {

	readyConfigSequence();

	if((configNode->sequence).data.numStepsPerRepetition > 0 && numSlowDACChan > 0 && isSequenceConfigurable()) {
		if((configNode->sequence).data.enableLUT != NULL) {
			free((configNode->sequence).data.enableLUT);
			(configNode->sequence).data.enableLUT = NULL;
		}
		printf("Allocating enableDACLUT\n");
		(configNode->sequence).data.enableLUT = (bool *)calloc(numSlowDACChan, (configNode->sequence).data.numStepsPerRepetition * sizeof(bool));

		int n = readAll(newdatasockfd, (configNode->sequence).data.enableLUT, numSlowDACChan * (configNode->sequence).data.numStepsPerRepetition * sizeof(bool));
		seqState = CONFIG;
		if (n < 0) perror("ERROR reading from socket");
		
		return returnSCPIBool(context, true);
	}
	else {
		return returnSCPIBool(context, false);
	}
}

static scpi_result_t RP_DAC_SetSequenceResetAfter(scpi_t * context) {
	if (!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	readyConfigSequence();

	int32_t reset_after_selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &reset_after_selection, TRUE)) {
		return returnSCPIBool(context, false);
	}

	configNode->sequence.data.resetAfter = reset_after_selection;

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_GetSequenceResetAfter(scpi_t * context) {
	if (!isSequenceConfigurable()) {
		SCPI_ResultText(context, "OFF");
		return SCPI_RES_ERR;
	}

	readyConfigSequence();

	const char * name;

	SCPI_ChoiceToName(onoff_modes, configNode->sequence.data.resetAfter, &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_AppendSequence(scpi_t * context) {
	if (!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	if (configNode != NULL) {
		appendSequenceToList(configNode);
		configNode = NULL;
	}

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_PopSequence(scpi_t * context) {
	if (!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	sequenceNode_t * node = popSequence();
	cleanUpSequenceNode(node);

	return returnSCPIBool(context, true);
}

static scpi_result_t RP_DAC_ClearSequences(scpi_t * context) {
	if (!isSequenceConfigurable()) {
		return returnSCPIBool(context, false);
	}

	printf("Cleared Sequences\n");
	cleanUpSequenceList();

	return returnSCPIBool(context, true);
}


static scpi_result_t RP_DAC_PrepareSequences(scpi_t * context) {
	bool result = false;
	if (isSequenceConfigurable() ) {
		result = prepareSequences();
	}
	return returnSCPIBool(context, result);
}

static scpi_result_t RP_GetOverwrittenStatus(scpi_t * context) {
	SCPI_ResultBool(context, getOverwrittenStatus());
	return SCPI_RES_OK;
}


static scpi_result_t RP_GetCorruptedStatus(scpi_t * context) {
	SCPI_ResultBool(context, getCorruptedStatus());
	return SCPI_RES_OK;
}


static scpi_result_t RP_GetStatus(scpi_t * context) {
	sendStatusToClient();
	return SCPI_RES_OK;
}


static scpi_result_t RP_GetLostStatus(scpi_t * context) {
	SCPI_ResultBool(context, getLostStepsStatus());
	return SCPI_RES_OK;
}

static scpi_result_t RP_GetLog(scpi_t * context) {
	FILE * log = getLogFile();
	if (log != NULL) {
		sendFileToClient(log);
	}
	return SCPI_RES_OK;
}

static scpi_result_t RP_GetPerformance(scpi_t * context) {
	sendPerformanceDataToClient();
	return SCPI_RES_OK;
}

// Calibration
static scpi_result_t RP_Calib_DAC_GetOffset(scpi_t* context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();

	if (channel == 0) {
		SCPI_ResultFloat(context, calib_params.dac_ch1_offs);
	} 
	else if (channel == 1) {
		SCPI_ResultFloat(context, calib_params.dac_ch2_offs);
	}
	else {
		SCPI_ResultFloat(context, NAN);
 		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_Calib_DAC_SetOffset(scpi_t* context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();
	float calibOffset;
	int16_t offset = 0;

	SCPI_ParamFloat(context, &calibOffset, true);
	if (channel == 0) {
		offset = getOffset(channel);
		calib_params.dac_ch1_offs = calibOffset;
	} 
	else if (channel == 1) {
		offset = getOffset(channel);
		calib_params.dac_ch2_offs = calibOffset;
	}
	else {
 		return returnSCPIBool(context, false);
	}

	calib_WriteParams(calib_params, false);	
	calib_Init(); // Reload from cache from EEPROM
	setOffset(offset, channel); // Set offset with new calib
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_Calib_DAC_GetScale(scpi_t* context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();
	if (channel == 0) {
		SCPI_ResultFloat(context, calib_params.dac_ch1_fs);
	}
	else if (channel == 1) {
		SCPI_ResultFloat(context, calib_params.dac_ch2_fs);
	}
	else {
		SCPI_ResultFloat(context, NAN);
 		return SCPI_RES_ERR;
	}


	calib_WriteParams(calib_params, false);	
	calib_Init(); // Reload from cache from EEPROM
	return SCPI_RES_OK;
}

static scpi_result_t RP_Calib_DAC_SetScale(scpi_t* context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();
	float scale;

	SCPI_ParamFloat(context, &scale, true);
	if (channel == 0) {
		calib_params.dac_ch1_fs = scale;
	}
	else if (channel == 1) {
		calib_params.dac_ch2_fs = scale;	
	}
	else {
 		return returnSCPIBool(context, false);
	}


	calib_WriteParams(calib_params, false);	
	calib_Init(); // Reload from cache from EEPROM
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_Calib_ADC_GetOffset(scpi_t* context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();
	if (channel == 0) {
		SCPI_ResultFloat(context, calib_params.adc_ch1_offs);
	} 
	else if (channel == 1) {
		SCPI_ResultFloat(context, calib_params.adc_ch2_offs);
	}
	else {
		SCPI_ResultFloat(context, NAN);
 		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_Calib_ADC_SetOffset(scpi_t* context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();
	float offset;

	SCPI_ParamFloat(context, &offset, true);
	if (channel == 0) {
		calib_params.adc_ch1_offs = offset;
	} 
	else if (channel == 1) {
		calib_params.adc_ch2_offs = offset;	}
	else {
 		return returnSCPIBool(context, false);
	}

	
	calib_WriteParams(calib_params, false);	
	calib_Init(); // Reload from cache from EEPROM
	return returnSCPIBool(context, true);
}

static scpi_result_t RP_Calib_ADC_GetScale(scpi_t* context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();
	if (channel == 0) {
		SCPI_ResultFloat(context, calib_params.adc_ch1_fs);
	}
	else if (channel == 1) {
		SCPI_ResultFloat(context, calib_params.adc_ch2_fs);
	}
	else {
		SCPI_ResultFloat(context, NAN);
 		return SCPI_RES_ERR;
	}


	calib_WriteParams(calib_params, false);	
	calib_Init(); // Reload from cache from EEPROM
	return SCPI_RES_OK;
}

static scpi_result_t RP_Calib_ADC_SetScale(scpi_t* context) {
	if (getServerMode() != CONFIGURATION) {
		return returnSCPIBool(context, false);
	}

	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	rp_calib_params_t calib_params = calib_GetParams();
	float scale;

	SCPI_ParamFloat(context, &scale, true);
	if (channel == 0) {
		calib_params.adc_ch1_fs = scale;
	}
	else if (channel == 1) {
		calib_params.adc_ch2_fs = scale;	
	}
	else {
 		return returnSCPIBool(context, false);
	}


	calib_WriteParams(calib_params, false);	
	calib_Init(); // Reload from cache from EEPROM
	return returnSCPIBool(context, true);
}


static scpi_result_t RP_ResetCalibration(scpi_t * context) {
  calib_LoadFromFactoryZone();
  return SCPI_RES_OK;
}

const scpi_command_t scpi_commands[] = {
	/* IEEE Mandated Commands (SCPI std V1999.0 4.1.1) */
	{ .pattern = "*CLS", .callback = SCPI_CoreCls,},
	{ .pattern = "*ESE", .callback = SCPI_CoreEse,},
	{ .pattern = "*ESE?", .callback = SCPI_CoreEseQ,},
	{ .pattern = "*ESR?", .callback = SCPI_CoreEsrQ,},
	{ .pattern = "*IDN?", .callback = SCPI_CoreIdnQ,},
	{ .pattern = "*OPC", .callback = SCPI_CoreOpc,},
	{ .pattern = "*OPC?", .callback = SCPI_CoreOpcQ,},
	{ .pattern = "*RST", .callback = SCPI_CoreRst,},
	{ .pattern = "*SRE", .callback = SCPI_CoreSre,},
	{ .pattern = "*SRE?", .callback = SCPI_CoreSreQ,},
	{ .pattern = "*STB?", .callback = SCPI_CoreStbQ,},
	{ .pattern = "*TST?", .callback = SCPI_CoreTstQ,},
	{ .pattern = "*WAI", .callback = SCPI_CoreWai,},

	/* Required SCPI commands (SCPI std V1999.0 4.2.1) */
	{.pattern = "SYSTem:ERRor[:NEXT]?", .callback = SCPI_SystemErrorNextQ,},
	{.pattern = "SYSTem:ERRor:COUNt?", .callback = SCPI_SystemErrorCountQ,},
	{.pattern = "SYSTem:VERSion?", .callback = SCPI_SystemVersionQ,},

	/* {.pattern = "STATus:OPERation?", .callback = scpi_stub_callback,}, */
	/* {.pattern = "STATus:OPERation:EVENt?", .callback = scpi_stub_callback,}, */
	/* {.pattern = "STATus:OPERation:CONDition?", .callback = scpi_stub_callback,}, */
	/* {.pattern = "STATus:OPERation:ENABle", .callback = scpi_stub_callback,}, */
	/* {.pattern = "STATus:OPERation:ENABle?", .callback = scpi_stub_callback,}, */

	{.pattern = "STATus:QUEStionable[:EVENt]?", .callback = SCPI_StatusQuestionableEventQ,},
	/* {.pattern = "STATus:QUEStionable:CONDition?", .callback = scpi_stub_callback,}, */
	{.pattern = "STATus:QUEStionable:ENABle", .callback = SCPI_StatusQuestionableEnable,},
	{.pattern = "STATus:QUEStionable:ENABle?", .callback = SCPI_StatusQuestionableEnableQ,},

	{.pattern = "STATus:PRESet", .callback = SCPI_StatusPreset,},

	/* RP-DAQ */
	{.pattern = "RP:MODe?", .callback = RP_GetServerMode,},
	{.pattern = "RP:MODe", .callback = RP_SetServerMode,},
	// DAC
	{.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude?", .callback = RP_DAC_GetAmplitude,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude", .callback = RP_DAC_SetAmplitude,},
	{.pattern = "RP:DAC:CHannel#:OFFset?", .callback = RP_DAC_GetOffset,},
	{.pattern = "RP:DAC:CHannel#:OFFset", .callback = RP_DAC_SetOffset,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency?", .callback = RP_DAC_GetFrequency,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency", .callback = RP_DAC_SetFrequency,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse?", .callback = RP_DAC_GetPhase,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse", .callback = RP_DAC_SetPhase,},
	//{.pattern = "RP:DAC:MODe", .callback = RP_DAC_SetDACMode,},
	//{.pattern = "RP:DAC:MODe?", .callback = RP_DAC_GetDACMode,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:SIGnaltype", .callback = RP_DAC_SetSignalType,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:SIGnaltype?", .callback = RP_DAC_GetSignalType,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:JUMPsharpness", .callback = RP_DAC_SetJumpSharpness,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:JUMPsharpness?", .callback = RP_DAC_GetJumpSharpness,},
	// Ramping
	{.pattern = "RP:DAC:CHannel#:RAMPing", .callback = RP_DAC_SetRampingFast,},
	{.pattern = "RP:DAC:CHannel#:RAMPing?", .callback = RP_DAC_GetRampingFast,},
	{.pattern = "RP:DAC:CHannel#:RAMPing:ENaBle", .callback = RP_DAC_SetEnableRamping,},
	{.pattern = "RP:DAC:CHannel#:RAMPing:ENaBle?", .callback = RP_DAC_GetEnableRamping,},
	{.pattern = "RP:DAC:CHannel#:RAMPing:DoWN", .callback = RP_DAC_SetEnableRampDown,},
	{.pattern = "RP:DAC:CHannel#:RAMPing:DoWN?", .callback = RP_DAC_GetEnableRampDown,},
	//{.pattern = "RP:DAC:CHannel#:RAMPing:STATus?", .callback = RP_DAC_GetChannelRampingStatus,},
	{.pattern = "RP:DAC:RAMPing:STATus?", .callback = RP_DAC_GetRampingStatus,},
	// Sequences
	{.pattern = "RP:DAC:SEQ:CLocKdivider", .callback = RP_ADC_SetSeqClockDivider,},
	{.pattern = "RP:DAC:SEQ:CLocKdivider?", .callback = RP_ADC_GetSeqClockDivider,},
	{.pattern = "RP:DAC:SEQ:SAMPlesperstep", .callback = RP_DAC_SetSamplesPerStep,},
	{.pattern = "RP:DAC:SEQ:SAMPlesperstep?", .callback = RP_DAC_GetSamplesPerStep,},
	{.pattern = "RP:DAC:SEQ:CHan", .callback = RP_DAC_SetNumSlowDACChan,},
	{.pattern = "RP:DAC:SEQ:CHan?", .callback = RP_DAC_GetNumSlowDACChan,},
	{.pattern = "RP:DAC:PASStofast", .callback = RP_SetPassPDMToFastDAC,},
	{.pattern = "RP:DAC:PASStofast?", .callback = RP_GetPassPDMToFastDAC,},
	// Specific/Current Sequence
	{.pattern = "RP:DAC:SEQ:LUT:ARBITRARY", .callback = RP_DAC_SetArbitraryLUT,},
	{.pattern = "RP:DAC:SEQ:LUT:CONSTANT", .callback = RP_DAC_SetConstantLUT,},
	{.pattern = "RP:DAC:SEQ:LUT:PAUSE", .callback = RP_DAC_SetPauseLUT,},
	{.pattern = "RP:DAC:SEQ:LUT:RANGE", .callback = RP_DAC_SetRangeLUT,},
	{.pattern = "RP:DAC:SEQ:LUT:ENaBle", .callback = RP_DAC_SetEnableDACLUT,},
	//{.pattern = "RP:DAC:SEQ:LostSteps?", .callback = RP_DAC_GetSlowDACLostSteps,},
	{.pattern = "RP:DAC:SEQ:STEPs:REPetition", .callback = RP_DAC_SetStepsPerRepetition,},
	{.pattern = "RP:DAC:SEQ:STEPs:REPetition?", .callback = RP_DAC_GetStepsPerRepetition,},
	{.pattern = "RP:DAC:SEQ:RaMPing", .callback = RP_DAC_SetRamping,},
	// TODO RAMPING SCPI
	{.pattern = "RP:DAC:SEQ:REPetitions", .callback = RP_DAC_SetSequenceRepetitions,},
	{.pattern = "RP:DAC:SEQ:REPetitions?", .callback = RP_DAC_GetSequenceRepetitions,},
	{.pattern = "RP:DAC:SEQ:RESETafter", .callback = RP_DAC_SetSequenceResetAfter,},
	{.pattern = "RP:DAC:SEQ:RESETafter?", .callback = RP_DAC_GetSequenceResetAfter,},
	{.pattern = "RP:DAC:SEQ:APPend", .callback = RP_DAC_AppendSequence,},
	{.pattern = "RP:DAC:SEQ:POP", .callback = RP_DAC_PopSequence,},
	{.pattern = "RP:DAC:SEQ:CLEAR", .callback = RP_DAC_ClearSequences,},
	{.pattern = "RP:DAC:SEQ:PREPare", .callback = RP_DAC_PrepareSequences,},
	// Sequences DAC Config
	{.pattern = "RP:DAC:SEQ:CHannel#:COMPonent#:AMPlitude", .callback = RP_DAC_SetSequenceAmplitude,},
	{.pattern = "RP:DAC:SEQ:CHannel#:OFFset", .callback = RP_DAC_SetSequenceOffset,},
	{.pattern = "RP:DAC:SEQ:CHannel#:COMPonent#:FREQuency", .callback = RP_DAC_SetSequenceFrequency,},
	{.pattern = "RP:DAC:SEQ:CHannel#:COMPonent#:PHAse", .callback = RP_DAC_SetSequencePhase,},
	{.pattern = "RP:DAC:SEQ:CHannel#:SIGnaltype", .callback = RP_DAC_SetSequenceSignalType,},
	{.pattern = "RP:DAC:SEQ:CHannel#:JUMPsharpness", .callback = RP_DAC_SetSequenceJumpSharpness,},
	// ADC
	//{.pattern = "RP:ADC:SlowADC", .callback = RP_ADC_SetNumSlowADCChan,},
	//{.pattern = "RP:ADC:SlowADC?", .callback = RP_ADC_GetNumSlowADCChan,},
	{.pattern = "RP:ADC:DECimation", .callback = RP_ADC_SetDecimation,},
	{.pattern = "RP:ADC:DECimation?", .callback = RP_ADC_GetDecimation,},
	//{.pattern = "RP:ADC:SlowDACInterpolation", .callback = RP_ADC_SlowDACInterpolation,},
	{.pattern = "RP:ADC:WP?", .callback = RP_ADC_GetCurrentWP,},
	{.pattern = "RP:ADC:DATa?", .callback = RP_ADC_GetData,},
	//{.pattern = "RP:ADC:DATa:DETailed?", .callback = RP_ADC_GetDetailedData,},
	{.pattern = "RP:ADC:DATa:PIPElined?", .callback = RP_ADC_GetPipelinedData,},
	{.pattern = "RP:ADC:BUFfer:Size?", .callback = RP_ADC_GetBufferSize,},
	//{.pattern = "RP:ADC:Slow:FRAmes:DATa", .callback = RP_ADC_Slow_GetFrames,},
	//{.pattern = "RP:XADC:CHannel#?", .callback = RP_XADC_GetXADCValueVolt,},
	{.pattern = "RP:DIO:DIR", .callback = RP_DIO_SetDIODirection,},
	{.pattern = "RP:DIO:DIR?", .callback = RP_DIO_GetDIODirection,},
	{.pattern = "RP:DIO", .callback = RP_DIO_SetDIOOutput,},
	{.pattern = "RP:DIO?", .callback = RP_DIO_GetDIOOutput,},
	{.pattern = "RP:WatchDogMode", .callback = RP_SetWatchdogMode,},
	{.pattern = "RP:WatchDogMode?", .callback = RP_GetWatchdogMode,},
	{.pattern = "RP:TRIGger:ALiVe", .callback = RP_SetKeepAliveReset,},
	{.pattern = "RP:TRIGger:ALiVe?", .callback = RP_GetKeepAliveReset,},
	{.pattern = "RP:TRIGger:MODe", .callback = RP_DAC_SetTriggerMode,},
	{.pattern = "RP:TRIGger:MODe?", .callback = RP_DAC_GetTriggerMode,},
	{.pattern = "RP:TRIGger", .callback = RP_SetMasterTrigger,},
	{.pattern = "RP:TRIGger?", .callback = RP_GetMasterTrigger,},
	//{.pattern = "RP:InstantResetMode", .callback = RP_SetInstantResetMode,},
	//{.pattern = "RP:InstantResetMode?", .callback = RP_GetInstantResetMode,},
	//{.pattern = "RP:PeripheralAResetN?", .callback = RP_PeripheralAResetN,},
	//{.pattern = "RP:FourierSynthAResetN?", .callback = RP_FourierSynthAResetN,},
	//{.pattern = "RP:PDMAResetN?", .callback = RP_PDMAResetN,},
	//{.pattern = "RP:WriteToRAMAResetN?", .callback = RP_WriteToRAMAResetN,},
	//{.pattern = "RP:XADCAResetN?", .callback = RP_XADCAResetN,},
	//{.pattern = "RP:WatchdogStatus?", .callback = RP_WatchdogStatus,},
	//{.pattern = "RP:InstantResetStatus?", .callback = RP_InstantResetStatus,},
	/* RP-DAQ Errors */
	{.pattern = "RP:STATus:OVERwritten?", .callback = RP_GetOverwrittenStatus,},
	{.pattern = "RP:STATus:CORRupted?", .callback = RP_GetCorruptedStatus,},
	{.pattern = "RP:STATus?", .callback = RP_GetStatus,},
	{.pattern = "RP:STATus:LOSTSteps?", .callback = RP_GetLostStatus,},
	{.pattern = "RP:LOG?", .callback = RP_GetLog,},
	{.pattern = "RP:PERF?", .callback = RP_GetPerformance,},	

	/* Calibration */
	{.pattern = "RP:CALib:DAC:CHannel#:OFFset?", .callback = RP_Calib_DAC_GetOffset,},
	{.pattern = "RP:CALib:DAC:CHannel#:OFFset", .callback = RP_Calib_DAC_SetOffset,},
	{.pattern = "RP:CALib:DAC:CHannel#:SCAle?", .callback = RP_Calib_DAC_GetScale,},
	{.pattern = "RP:CALib:DAC:CHannel#:SCAle", .callback = RP_Calib_DAC_SetScale,},
	{.pattern = "RP:CALib:ADC:CHannel#:OFFset?", .callback = RP_Calib_ADC_GetOffset,},
	{.pattern = "RP:CALib:ADC:CHannel#:OFFset", .callback = RP_Calib_ADC_SetOffset,},
	{.pattern = "RP:CALib:ADC:CHannel#:SCAle?", .callback = RP_Calib_ADC_GetScale,},
	{.pattern = "RP:CALib:ADC:CHannel#:SCAle", .callback = RP_Calib_ADC_SetScale,},
	{.pattern = "RP:CALib:RESet", .callback = RP_ResetCalibration,},

	SCPI_CMD_LIST_END
};
