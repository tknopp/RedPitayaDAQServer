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

#include "scpi/scpi.h"

#include "../lib/rp-daq-lib.h"
#include "../server/daq_server_scpi.h"


static scpi_result_t RP_Init(scpi_t * context) {

	if(!initialized) {
		init();
		initialized = true;
	}

	if(slowDACLUT != NULL) {
		free(slowDACLUT);
		slowDACLUT = NULL;
	}

	if(enableDACLUT != NULL) {
		free(enableDACLUT);
		enableDACLUT = NULL;
	}

	return SCPI_RES_OK;
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
		return SCPI_RES_ERR;
	}

	int result = setAmplitude((uint16_t)(amplitude*8192.0), channel, component);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	printf("channel = %d; component = %d, amplitude = %f\n", channel, component, amplitude);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetNextAmplitude(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	SCPI_ResultDouble(context, fastDACNextAmplitude[component+4*channel]  / 8192.0 );

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetNextAmplitude(scpi_t * context) {
	int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	double amplitude;
	if (!SCPI_ParamDouble(context, &amplitude, TRUE)) {
		return SCPI_RES_ERR;
	}

	fastDACNextAmplitude[component+4*channel] = (uint16_t)(amplitude*8192.0); 

	printf("SetNextAmpl: channel = %d; component = %d, amplitude = %f\n", channel, component, amplitude);

	return SCPI_RES_OK;
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
		return SCPI_RES_ERR;
	}

	int result = setOffset((int16_t)(offset*8192.0), channel);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

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
		return SCPI_RES_ERR;
	}

	int result = setFrequency(frequency, channel, component);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
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
		return SCPI_RES_ERR;
	}
	printf("channel = %d; component = %d, phase = %f\n", channel, component, phase);

	int result = setPhase(phase, channel, component);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

scpi_choice_def_t DAC_modes[] = {
	{"STANDARD", DAC_MODE_STANDARD},
	{"AWG", DAC_MODE_AWG},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_DAC_SetDACMode(scpi_t * context) {
	int32_t DAC_mode_selection;

	if (!SCPI_ParamChoice(context, DAC_modes, &DAC_mode_selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setDACMode(DAC_mode_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
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
	int32_t trigger_mode_selection;

	if (!SCPI_ParamChoice(context, trigger_modes, &trigger_mode_selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setTriggerMode(trigger_mode_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
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
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	int32_t signal_type_selection;

	if (!SCPI_ParamChoice(context, signal_types, &signal_type_selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setSignalType(channel, signal_type_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetSignalType(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	const char * name;

	SCPI_ChoiceToName(signal_types, getSignalType(channel), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetJumpSharpness(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	SCPI_ResultDouble(context, getJumpSharpness(channel));

	return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetJumpSharpness(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double percentage;
	if (!SCPI_ParamDouble(context, &percentage, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setJumpSharpness(channel, percentage);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}


static scpi_result_t RP_ADC_SetDecimation(scpi_t * context) {
	// Enforce changing the decimation to be only
	// possible while not acquiring data
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}

	uint32_t decimation;
	if (!SCPI_ParamInt32(context, &decimation, TRUE)) {
		return SCPI_RES_ERR;
	}

	printf("set dec = %d \n", decimation);
	int result = setDecimation((uint16_t)decimation);
	if (result < 0) {
		printf("Could not set decimation!");
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetDecimation(scpi_t * context) {

	uint16_t dec = getDecimation();

	SCPI_ResultUInt16(context, dec);

	return SCPI_RES_OK;
}


static scpi_result_t RP_ADC_SetSamplesPerSlowDACStep(scpi_t * context) {
	// Enforce changing the samples per slowDAC steps to be only
	// possible while not acquiring data
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}

	if (!SCPI_ParamInt32(context, &numSamplesPerSlowDACStep, TRUE)) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetSamplesPerSlowDACStep(scpi_t * context) {
	SCPI_ResultInt32(context, numSamplesPerSlowDACStep);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_SetSlowDACStepsPerRotation(scpi_t * context) {
	// Enforce changing the slowDAC steps per rotation to be only
	// possible while not acquiring data
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}

	if (!SCPI_ParamInt32(context, &numSlowDACStepsPerRotation, TRUE)) {
		return SCPI_RES_ERR;
	}


	// Adapt the slowDAC frequency to match the step length
	setPDMClockDivider(numSamplesPerSlowDACStep * getDecimation());

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetSlowDACStepsPerRotation(scpi_t * context) {
	SCPI_ResultInt32(context, numSlowDACStepsPerRotation);

	return SCPI_RES_OK;
}



static scpi_result_t RP_ADC_SetPDMClockDivider(scpi_t * context) {
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}
	int32_t clockDiv = 1;

	if (!SCPI_ParamInt32(context, &clockDiv, TRUE)) {
		return SCPI_RES_ERR;
	}

	setPDMClockDivider(clockDiv);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetPDMClockDivider(scpi_t * context) {
	SCPI_ResultInt32(context, getPDMClockDivider());

	return SCPI_RES_OK;
}



static scpi_result_t RP_ADC_SetNumSlowDACChan(scpi_t * context) {
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}

	if (!SCPI_ParamInt32(context, &numSlowDACChan, TRUE)) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetNumSlowDACChan(scpi_t * context) {
	SCPI_ResultInt32(context, numSlowDACChan);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetSlowDACLostSteps(scpi_t * context) {
	SCPI_ResultInt32(context, numSlowDACLostSteps);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_EnableSlowDAC(scpi_t * context) {
	int result;
	if (!SCPI_ParamInt32(context, &result, TRUE)) {
		return SCPI_RES_ERR;
	}

	if (!SCPI_ParamInt32(context, &numSlowDACRotationsEnabled, TRUE)) {
		return SCPI_RES_ERR;
	}
	if (!SCPI_ParamDouble(context, &slowDACRampUpTime, TRUE)) {
		return SCPI_RES_ERR;
	}
	if (!SCPI_ParamDouble(context, &slowDACFractionRampUp, TRUE)) {
		return SCPI_RES_ERR;
	}
	enableSlowDAC = result;

	if(enableSlowDAC && rxEnabled && numSlowDACChan>0) {
		enableSlowDACAck = false;
		numSlowDACLostSteps = 0;
		while(!enableSlowDACAck) {
			usleep(1.0);
			//sleep(1.0);
			//printf("WAIT FOR SLOW DACAck\n");
		}
		SCPI_ResultInt64(context, rotationSlowDACEnabled);
	} else {
		SCPI_ResultInt64(context, 0);
	}
	if(rxEnabled && !enableSlowDAC) {
		for (int i=0; i<4; i++) {
			setPDMAllValuesVolt(0.0, i);
		}  
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_SlowDACInterpolation(scpi_t * context) {

	int32_t tmp;
	if (!SCPI_ParamInt32(context, &tmp, TRUE)) {
		return SCPI_RES_ERR;
	}
	slowDACInterpolation = (tmp == 1);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_SetNumSlowADCChan(scpi_t * context) {
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}

	if (!SCPI_ParamInt32(context, &numSlowADCChan, TRUE)) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
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
	if(!rxEnabled) {
		return SCPI_RES_ERR;
	}

	uint64_t reqWP;
	if (!SCPI_ParamInt64(context, &reqWP, TRUE)) {
		return SCPI_RES_ERR;
	}

	uint64_t numSamples;
	if (!SCPI_ParamInt64(context, &numSamples, TRUE)) {
		return SCPI_RES_ERR;
	}

	//printf("invoke sendDataToHost()");
	sendDataToClient(reqWP, numSamples, true);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetPipelinedData(scpi_t * context) {
	if(!rxEnabled) {
		return SCPI_RES_ERR;
	}
	
	uint64_t reqWP;
	if (!SCPI_ParamInt64(context, &reqWP, TRUE)) {
		return SCPI_RES_ERR;
	}

	uint64_t numSamples;
	if (!SCPI_ParamInt64(context, &numSamples, TRUE)) {
		return SCPI_RES_ERR;
	}

	uint64_t chunkSize;
	if (!SCPI_ParamInt64(context, &chunkSize, TRUE)) {
		return SCPI_RES_ERR;
	}

	sendPipelinedDataToClient(reqWP, numSamples, chunkSize);
	return SCPI_RES_OK;

}

static scpi_result_t RP_ADC_GetDetailedData(scpi_t * context) {
	if(!rxEnabled) {
		return SCPI_RES_ERR;
	}
	
	uint64_t reqWP;
	if (!SCPI_ParamInt64(context, &reqWP, TRUE)) {
		return SCPI_RES_ERR;
	}

	uint64_t numSamples;
	if (!SCPI_ParamInt64(context, &numSamples, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	sendPipelinedDataToClient(reqWP, numSamples, numSamples);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_Slow_GetFrames(scpi_t * context) {
	// Reading is only possible while an acquisition is running
	if(!rxEnabled) {
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

static scpi_result_t RP_ADC_StartAcquisitionConnection(scpi_t * context) {
	bool connectionEstablished = false;

	printf("RP_ADC_StartAcquisitionConnection\n");
	while(!connectionEstablished) {
		newdatasocklen = sizeof (newdatasockaddr);
		newdatasockfd = accept(datasockfd, (struct sockaddr *) &newdatasockaddr, &newdatasocklen);

		if (newdatasockfd < 0) {
			continue;
		} else {
			connectionEstablished = true;
		}
	}

	//	SCPI_ResultBool(context, connectionEstablished);

	return SCPI_RES_OK;
}

scpi_choice_def_t acquisition_status_modes[] = {
	{"OFF", ACQUISITION_OFF},
	{"ON", ACQUISITION_ON},
	SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_ADC_GetAcquisitionStatus(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(acquisition_status_modes, rxEnabled, &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_SetAcquisitionStatus(scpi_t * context) {
	int32_t acquisition_status_selection;
	if (!SCPI_ParamChoice(context, acquisition_status_modes, &acquisition_status_selection, TRUE)) {
		return SCPI_RES_ERR;
	}
	if(acquisition_status_selection == ACQUISITION_ON) {
		rxEnabled = true;
	} else {
		rxEnabled = false;
		buffInitialized = false;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_PDM_SetPDMNextValue(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	uint32_t next_PDM_value;
	if (!SCPI_ParamInt32(context, &next_PDM_value, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setPDMAllValues((uint16_t)next_PDM_value, channel);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_PDM_SetPDMNextValueVolt(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	double next_PDM_value;
	if (!SCPI_ParamDouble(context, &next_PDM_value, TRUE)) {
		return SCPI_RES_ERR;
	}

	printf("Set PDM channel %d to %f Volt\n", channel, next_PDM_value);

	int result = setPDMAllValuesVolt(next_PDM_value, channel);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_PDM_GetPDMNextValue(scpi_t * context) {
	int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];

	SCPI_ResultUInt16(context, getPDMNextValue(channel));

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

static scpi_result_t RP_DIO_SetDIODirection(scpi_t * context) {
	const char* pin;
	size_t len;
	if (!SCPI_ParamCharacters(context, &pin, &len, TRUE)) {
		return SCPI_RES_ERR;
	}

	int32_t DIO_pin_output_selection;
	if (!SCPI_ParamChoice(context, inout_modes, &DIO_pin_output_selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setDIODirection(pin, DIO_pin_output_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
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
		return SCPI_RES_ERR;
	}

	int32_t DIO_pin_output_selection;
	if (!SCPI_ParamChoice(context, onoff_modes, &DIO_pin_output_selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setDIO(pin, DIO_pin_output_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_DIO_GetDIOOutput(scpi_t * context) {
	const char* pin;
	size_t len;
	if (!SCPI_ParamCharacters(context, &pin, &len, TRUE)) {
		return SCPI_RES_ERR;
	}

	const char* name;

	int result = getDIO(pin);

	if (result < 0) {
		return SCPI_RES_ERR;
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
		return SCPI_RES_ERR;
	}

	int result = setWatchdogMode(watchdog_mode_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_GetPassPDMToFastDAC(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getPassPDMToFastDAC(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetPassPDMToFastDAC(scpi_t * context) {
	int32_t selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setPassPDMToFastDAC(selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
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
	int32_t RAM_writer_mode_selection;

	if (!SCPI_ParamChoice(context, RAM_writer_modes, &RAM_writer_mode_selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setRAMWriterMode(RAM_writer_mode_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_GetMasterTrigger(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getMasterTrigger(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetMasterTrigger(scpi_t * context) {
	int32_t master_trigger_selection;

	if (!SCPI_ParamChoice(context, onoff_modes, &master_trigger_selection, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setMasterTrigger(master_trigger_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_GetKeepAliveReset(scpi_t * context) {
	const char * name;

	SCPI_ChoiceToName(onoff_modes, getKeepAliveReset(), &name);
	SCPI_ResultText(context, name);

	return SCPI_RES_OK;
}

static scpi_result_t RP_SetKeepAliveReset(scpi_t * context) {
	int32_t param;

	if (!SCPI_ParamChoice(context, onoff_modes, &param, TRUE)) {
		return SCPI_RES_ERR;
	}

	int result = setKeepAliveReset(param);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
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
		return SCPI_RES_ERR;
	}

	int result = setInstantResetMode(instant_reset_mode_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
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

static scpi_result_t RP_TriggerStatus(scpi_t * context) {
	SCPI_ResultBool(context, getTriggerStatus());

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

static scpi_result_t RP_ADC_SetSlowDACLUT(scpi_t * context) {

	if(numSlowDACStepsPerRotation > 0 && numSlowDACChan > 0 && !enableSlowDAC) {
		if(slowDACLUT != NULL) {
			free(slowDACLUT);
			slowDACLUT = NULL;
		}
		printf("Allocating slowDACLUT\n");
		slowDACLUT = (float *)malloc(numSlowDACChan * numSlowDACStepsPerRotation * sizeof(float));

		int n = readAll(newdatasockfd,slowDACLUT,numSlowDACChan * numSlowDACStepsPerRotation * sizeof(float));
		if (n < 0) perror("ERROR reading from socket");
		
		return SCPI_RES_OK;
	}
	else {
		return SCPI_RES_ERR;
	}
}


static scpi_result_t RP_ADC_SetEnableDACLUT(scpi_t * context) {

	if(numSlowDACStepsPerRotation > 0 && numSlowDACChan > 0 && !enableSlowDAC) {
		if(enableDACLUT != NULL) {
			free(enableDACLUT);
			enableDACLUT = NULL;
		}
		printf("Allocating enableDACLUT\n");
		enableDACLUT = (bool *)malloc(numSlowDACChan * numSlowDACStepsPerRotation * sizeof(bool));

		int n = readAll(newdatasockfd, enableDACLUT, numSlowDACChan * numSlowDACStepsPerRotation * sizeof(bool));
		if (n < 0) perror("ERROR reading from socket");
		
		return SCPI_RES_OK;
	}
	else {
		return SCPI_RES_ERR;
	}
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
	SCPI_ResultBool(context, getStatus());
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
	{.pattern = "RP:Init", .callback = RP_Init,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude?", .callback = RP_DAC_GetAmplitude,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude", .callback = RP_DAC_SetAmplitude,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:Next:AMPlitude?", .callback = RP_DAC_GetNextAmplitude,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:Next:AMPlitude", .callback = RP_DAC_SetNextAmplitude,},
	{.pattern = "RP:DAC:CHannel#:OFFset?", .callback = RP_DAC_GetOffset,},
	{.pattern = "RP:DAC:CHannel#:OFFset", .callback = RP_DAC_SetOffset,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency?", .callback = RP_DAC_GetFrequency,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency", .callback = RP_DAC_SetFrequency,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse?", .callback = RP_DAC_GetPhase,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse", .callback = RP_DAC_SetPhase,},
	{.pattern = "RP:DAC:MODe", .callback = RP_DAC_SetDACMode,},
	{.pattern = "RP:DAC:MODe?", .callback = RP_DAC_GetDACMode,},
	{.pattern = "RP:DAC:CHannel#:SIGnaltype", .callback = RP_DAC_SetSignalType,},
	{.pattern = "RP:DAC:CHannel#:SIGnaltype?", .callback = RP_DAC_GetSignalType,},
	{.pattern = "RP:DAC:CHannel#:JumpSharpness", .callback = RP_DAC_SetJumpSharpness,},
	{.pattern = "RP:DAC:CHannel#:JumpSharpness?", .callback = RP_DAC_GetJumpSharpness,},
	{.pattern = "RP:ADC:SlowADC", .callback = RP_ADC_SetNumSlowADCChan,},
	{.pattern = "RP:ADC:SlowADC?", .callback = RP_ADC_GetNumSlowADCChan,},
	{.pattern = "RP:ADC:DECimation", .callback = RP_ADC_SetDecimation,},
	{.pattern = "RP:ADC:DECimation?", .callback = RP_ADC_GetDecimation,},
	{.pattern = "RP:ADC:SlowDAC", .callback = RP_ADC_SetNumSlowDACChan,},
	{.pattern = "RP:ADC:SlowDAC?", .callback = RP_ADC_GetNumSlowDACChan,},
	{.pattern = "RP:ADC:SlowDACLUT", .callback = RP_ADC_SetSlowDACLUT,},
	{.pattern = "RP:ADC:EnableDACLUT", .callback = RP_ADC_SetEnableDACLUT,},
	{.pattern = "RP:ADC:SlowDACEnable", .callback = RP_ADC_EnableSlowDAC,},
	{.pattern = "RP:ADC:SlowDACInterpolation", .callback = RP_ADC_SlowDACInterpolation,},
	{.pattern = "RP:ADC:SlowDACLostSteps?", .callback = RP_ADC_GetSlowDACLostSteps,},
	{.pattern = "RP:ADC:SlowDAC:STEPsPerRotation", .callback = RP_ADC_SetSlowDACStepsPerRotation,},
	{.pattern = "RP:ADC:SlowDAC:STEPsPerRotation?", .callback = RP_ADC_GetSlowDACStepsPerRotation,},
	{.pattern = "RP:ADC:SlowDAC:SAMPlesPerStep", .callback = RP_ADC_SetSamplesPerSlowDACStep,},
	{.pattern = "RP:ADC:SlowDAC:SAMPlesPerStep?", .callback = RP_ADC_GetSamplesPerSlowDACStep,},
	{.pattern = "RP:ADC:WP:CURRent?", .callback = RP_ADC_GetCurrentWP,},
	{.pattern = "RP:ADC:DATa?", .callback = RP_ADC_GetData,},
	{.pattern = "RP:ADC:DATa:DETailed?", .callback = RP_ADC_GetDetailedData,},
	{.pattern = "RP:ADC:DATa:PIPElined?", .callback = RP_ADC_GetPipelinedData,},
	{.pattern = "RP:ADC:BUFfer:Size?", .callback = RP_ADC_GetBufferSize,},
	{.pattern = "RP:ADC:Slow:FRAmes:DATa", .callback = RP_ADC_Slow_GetFrames,},
	{.pattern = "RP:ADC:ACQCONNect", .callback = RP_ADC_StartAcquisitionConnection,},
	{.pattern = "RP:ADC:ACQSTATus", .callback = RP_ADC_SetAcquisitionStatus,},
	{.pattern = "RP:ADC:ACQSTATus?", .callback = RP_ADC_GetAcquisitionStatus,},
	{.pattern = "RP:PDM:ClockDivider", .callback = RP_ADC_SetPDMClockDivider,},
	{.pattern = "RP:PDM:ClockDivider?", .callback = RP_ADC_GetPDMClockDivider,},
	{.pattern = "RP:PDM:CHannel#:NextValue", .callback = RP_PDM_SetPDMNextValue,},
	{.pattern = "RP:PDM:CHannel#:NextValueVolt", .callback = RP_PDM_SetPDMNextValueVolt,},
	{.pattern = "RP:PDM:CHannel#:NextValue?", .callback = RP_PDM_GetPDMNextValue,},
	{.pattern = "RP:XADC:CHannel#?", .callback = RP_XADC_GetXADCValueVolt,},
	{.pattern = "RP:DIO:DIR", .callback = RP_DIO_SetDIODirection,},
	{.pattern = "RP:DIO", .callback = RP_DIO_SetDIOOutput,},
	{.pattern = "RP:DIO?", .callback = RP_DIO_GetDIOOutput,},
	{.pattern = "RP:WatchDogMode", .callback = RP_SetWatchdogMode,},
	{.pattern = "RP:WatchDogMode?", .callback = RP_GetWatchdogMode,},
	{.pattern = "RP:RamWriterMode", .callback = RP_SetRAMWriterMode,},
	{.pattern = "RP:RamWriterMode?", .callback = RP_GetRAMWriterMode,},
	{.pattern = "RP:PassPDMToFastDAC", .callback = RP_SetPassPDMToFastDAC,},
	{.pattern = "RP:PassPDMToFastDAC?", .callback = RP_GetPassPDMToFastDAC,},
	{.pattern = "RP:KeepAliveReset", .callback = RP_SetKeepAliveReset,},
	{.pattern = "RP:KeepAliveReset?", .callback = RP_GetKeepAliveReset,},
	{.pattern = "RP:Trigger:MODe", .callback = RP_DAC_SetTriggerMode,},
	{.pattern = "RP:Trigger:MODe?", .callback = RP_DAC_GetTriggerMode,},
	{.pattern = "RP:MasterTrigger", .callback = RP_SetMasterTrigger,},
	{.pattern = "RP:MasterTrigger?", .callback = RP_GetMasterTrigger,},
	{.pattern = "RP:InstantResetMode", .callback = RP_SetInstantResetMode,},
	{.pattern = "RP:InstantResetMode?", .callback = RP_GetInstantResetMode,},
	{.pattern = "RP:PeripheralAResetN?", .callback = RP_PeripheralAResetN,},
	{.pattern = "RP:FourierSynthAResetN?", .callback = RP_FourierSynthAResetN,},
	{.pattern = "RP:PDMAResetN?", .callback = RP_PDMAResetN,},
	{.pattern = "RP:WriteToRAMAResetN?", .callback = RP_WriteToRAMAResetN,},
	{.pattern = "RP:XADCAResetN?", .callback = RP_XADCAResetN,},
	{.pattern = "RP:TriggerStatus?", .callback = RP_TriggerStatus,},
	{.pattern = "RP:WatchdogStatus?", .callback = RP_WatchdogStatus,},
	{.pattern = "RP:InstantResetStatus?", .callback = RP_InstantResetStatus,},
	/* RP-DAQ Errors */
	{.pattern = "RP:STATus:OVERwritten?", .callback = RP_GetOverwrittenStatus,},
	{.pattern = "RP:STATus:CORRupted?", .callback = RP_GetCorruptedStatus,},
	{.pattern = "RP:STATus?", .callback = RP_GetStatus,},
	{.pattern = "RP:STATus:LOSTSteps?", .callback = RP_GetLostStatus,},
	{.pattern = "RP:LOG?", .callback = RP_GetLog,},
	{.pattern = "RP:PERF?", .callback = RP_GetPerformance,},	

	SCPI_CMD_LIST_END
};
