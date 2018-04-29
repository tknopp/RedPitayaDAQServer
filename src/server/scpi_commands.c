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
#include "../server/scpi_commands.h"

int newdatasockfd;
struct sockaddr_in newdatasockaddr;
socklen_t newdatasocklen;

static scpi_result_t RP_DAC_GetAmplitude(scpi_t * context) {
    int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	SCPI_ResultUInt16(context, getAmplitude(channel, component));

    return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetAmplitude(scpi_t * context) {
    int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];
	
	uint32_t amplitude;
    if (!SCPI_ParamInt32(context, &amplitude, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	int result = setAmplitude((uint16_t)amplitude, channel, component);
	if (result < 0) {
		return SCPI_RES_ERR;
	}
	
	printf("channel = %d; component = %d, amplitude = %d\n", channel, component, amplitude);
	
    return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetFrequency(scpi_t * context) {
    int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

        double freq = getFrequency(channel, component);
        
	printf("freq = %f \n", freq);
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

static scpi_result_t RP_DAC_GetModulusFactor(scpi_t * context) {
    int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];

	SCPI_ResultUInt32(context, getModulusFactor(channel, component));

    return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_SetModulusFactor(scpi_t * context) {
    int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];
	
	uint32_t modulus_factor;
    if (!SCPI_ParamInt32(context, &modulus_factor, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	int result = setModulusFactor(modulus_factor, channel, component);
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
    {"RASTERIZED", DAC_MODE_RASTERIZED},
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

static scpi_result_t RP_DAC_ReconfigureDACModulus(scpi_t * context) {
    int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];
	
	uint32_t modulus;
    if (!SCPI_ParamInt32(context, &modulus, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	int result = reconfigureDACModulus(modulus, channel, component);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

    return SCPI_RES_OK;
}

static scpi_result_t RP_DAC_GetDACModulus(scpi_t * context) {
    int32_t numbers[2];
	SCPI_CommandNumbers(context, numbers, 2, 1);
	int channel = numbers[0];
	int component = numbers[1];
	
	SCPI_ResultUInt32(context, getDACModulus(channel, component));

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

static scpi_result_t RP_ADC_SetSamplesPerPeriod(scpi_t * context) {
	// Enforce changing the samples per period to be only
	// possible while not acquiring data
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}

	if (!SCPI_ParamInt32(context, &numSamplesPerPeriod, TRUE)) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetSamplesPerPeriod(scpi_t * context) {
	SCPI_ResultInt32(context, numSamplesPerPeriod);

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_SetPeriodsPerFrame(scpi_t * context) {
	// Enforce changing the periods per frame to be only
	// possible while not acquiring data
	if(rxEnabled) {
		return SCPI_RES_ERR;
	}

	if (!SCPI_ParamInt32(context, &numPeriodsPerFrame, TRUE)) {
		return SCPI_RES_ERR;
	}

	return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetPeriodsPerFrame(scpi_t * context) {
	SCPI_ResultInt32(context, numPeriodsPerFrame);

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

static scpi_result_t RP_ADC_EnableSlowDAC(scpi_t * context) {

        if (!SCPI_ParamInt32(context, &enableSlowDAC, TRUE)) {
                return SCPI_RES_ERR;
        }

        return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetCurrentFrame(scpi_t * context) {
        // Reading is only possible while an acquisition is running
        if(!rxEnabled) {
                return SCPI_RES_ERR;
        }

	SCPI_ResultInt64(context, currentFrameTotal-1);

    return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetCurrentWP(scpi_t * context) {
        // Reading is only possible while an acquisition is running
        if(!rxEnabled) {
                return SCPI_RES_ERR;
        }

	SCPI_ResultInt64(context, getWritePointer());

    return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetCurrentPeriod(scpi_t * context) {
        // Reading is only possible while an acquisition is running
        if(!rxEnabled) {
                return SCPI_RES_ERR;
        }

	SCPI_ResultInt64(context, currentPeriodTotal-1);

    return SCPI_RES_OK;
}



static scpi_result_t RP_ADC_GetFrames(scpi_t * context) {
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
	sendFramesToHost(frame, numFrames);
	
    return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_GetPeriods(scpi_t * context) {
	// Reading is only possible while an acquisition is running
	if(!rxEnabled) {
		return SCPI_RES_ERR;
	}
	
	int64_t period;
    if (!SCPI_ParamInt64(context, &period, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	int64_t numPeriods;
	if (!SCPI_ParamInt64(context, &numPeriods, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	//printf("invoke sendDataToHost()");
	sendPeriodsToHost(period, numPeriods);
	
    return SCPI_RES_OK;
}

static scpi_result_t RP_ADC_StartAcquisitionConnection(scpi_t * context) {
	bool connectionEstablished = false;
	
	while(!connectionEstablished) {
		newdatasocklen = sizeof (newdatasockaddr);
		newdatasockfd = accept(datasockfd, (struct sockaddr *) &newdatasockaddr, &newdatasocklen);

		if (newdatasockfd < 0) {
			continue;
		} else {
			connectionEstablished = true;
		}
	}
	
	SCPI_ResultBool(context, connectionEstablished);
	
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
	
	int result = setPDMNextValue((uint16_t)next_PDM_value, channel);
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
	
	int result = setPDMNextValueVolt(next_PDM_value, channel);
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

static scpi_result_t RP_PDM_GetPDMCurrentValue(scpi_t * context) {
    int32_t numbers[1];
	SCPI_CommandNumbers(context, numbers, 1, 1);
	int channel = numbers[0];
	
	SCPI_ResultUInt16(context, getPDMCurrentValue(channel));

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

scpi_choice_def_t watchdog_modes[] = {
    {"OFF", WATCHDOG_OFF},
    {"ON", WATCHDOG_ON},
    SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_GetWatchdogMode(scpi_t * context) {
	const char * name;

    SCPI_ChoiceToName(watchdog_modes, getWatchdogMode(), &name);
	SCPI_ResultText(context, name);

    return SCPI_RES_OK;
}

static scpi_result_t RP_SetWatchdogMode(scpi_t * context) {
    int32_t watchdog_mode_selection;

    if (!SCPI_ParamChoice(context, watchdog_modes, &watchdog_mode_selection, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	int result = setWatchdogMode(watchdog_mode_selection);
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

scpi_choice_def_t master_trigger_modes[] = {
    {"OFF", MASTER_TRIGGER_OFF},
    {"ON", MASTER_TRIGGER_ON},
    SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_GetMasterTrigger(scpi_t * context) {
	const char * name;

    SCPI_ChoiceToName(master_trigger_modes, getMasterTrigger(), &name);
	SCPI_ResultText(context, name);

    return SCPI_RES_OK;
}

static scpi_result_t RP_SetMasterTrigger(scpi_t * context) {
    int32_t master_trigger_selection;

    if (!SCPI_ParamChoice(context, master_trigger_modes, &master_trigger_selection, TRUE)) {
		return SCPI_RES_ERR;
	}
	
	int result = setMasterTrigger(master_trigger_selection);
	if (result < 0) {
		return SCPI_RES_ERR;
	}

    return SCPI_RES_OK;
}

scpi_choice_def_t instant_reset_modes[] = {
    {"OFF", INSTANT_RESET_OFF},
    {"ON", INSTANT_RESET_ON},
    SCPI_CHOICE_LIST_END /* termination of option list */
};

static scpi_result_t RP_GetInstantResetMode(scpi_t * context) {
	const char * name;

    SCPI_ChoiceToName(instant_reset_modes, getInstantResetMode, &name);
	SCPI_ResultText(context, name);

    return SCPI_RES_OK;
}

static scpi_result_t RP_SetInstantResetMode(scpi_t * context) {
    int32_t instant_reset_mode_selection;

    if (!SCPI_ParamChoice(context, instant_reset_modes, &instant_reset_mode_selection, TRUE)) {
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


static scpi_result_t RP_ADC_SetSlowDACLUT(scpi_t * context) {

    if(numPeriodsPerFrame > 0 && numSlowDACChan > 0) {
    	if(slowDACLUT != NULL) {
            free(slowDACLUT);
        }
        printf("Allocating slowDACLUT\n");
        slowDACLUT = (float *)malloc(numSlowDACChan * numPeriodsPerFrame * sizeof(float));
    


      for(int i=0; i<numPeriodsPerFrame; i++) {
        for(int l=0; l<numSlowDACChan; l++) {
          if (!SCPI_ParamFloat(context, slowDACLUT+i*numSlowDACChan + l, TRUE)) {
                  return SCPI_RES_ERR;
          }
          //printf("LUT=%f \n", slowDACLUT[i*numSlowDACChan + l]);
        }
      }
   }
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
    {.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude?", .callback = RP_DAC_GetAmplitude,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:AMPlitude", .callback = RP_DAC_SetAmplitude,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency?", .callback = RP_DAC_GetFrequency,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FREQuency", .callback = RP_DAC_SetFrequency,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FACtor?", .callback = RP_DAC_GetModulusFactor,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:FACtor", .callback = RP_DAC_SetModulusFactor,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse?", .callback = RP_DAC_GetPhase,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:PHAse", .callback = RP_DAC_SetPhase,},
	{.pattern = "RP:DAC:MODe", .callback = RP_DAC_SetDACMode,},
	{.pattern = "RP:DAC:MODe?", .callback = RP_DAC_GetDACMode,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:MODulus", .callback = RP_DAC_ReconfigureDACModulus,},
	{.pattern = "RP:DAC:CHannel#:COMPonent#:MODulus?", .callback = RP_DAC_GetDACModulus,},
	{.pattern = "RP:ADC:DECimation", .callback = RP_ADC_SetDecimation,},
	{.pattern = "RP:ADC:DECimation?", .callback = RP_ADC_GetDecimation,},
	{.pattern = "RP:ADC:PERiod", .callback = RP_ADC_SetSamplesPerPeriod,},
	{.pattern = "RP:ADC:PERiod?", .callback = RP_ADC_GetSamplesPerPeriod,},
	{.pattern = "RP:ADC:PERiods:CURRent?", .callback = RP_ADC_GetCurrentPeriod,},
	{.pattern = "RP:ADC:PERiods:DATa", .callback = RP_ADC_GetPeriods,},
	{.pattern = "RP:ADC:SlowDAC", .callback = RP_ADC_SetNumSlowDACChan,},
	{.pattern = "RP:ADC:SlowDAC?", .callback = RP_ADC_GetNumSlowDACChan,},
	{.pattern = "RP:ADC:SlowDACLUT", .callback = RP_ADC_SetSlowDACLUT,},
	{.pattern = "RP:ADC:SlowDACEnable", .callback = RP_ADC_EnableSlowDAC,},
	{.pattern = "RP:ADC:FRAme", .callback = RP_ADC_SetPeriodsPerFrame,},
	{.pattern = "RP:ADC:FRAme?", .callback = RP_ADC_GetPeriodsPerFrame,},
	{.pattern = "RP:ADC:FRAmes:CURRent?", .callback = RP_ADC_GetCurrentFrame,},
	{.pattern = "RP:ADC:WP:CURRent?", .callback = RP_ADC_GetCurrentWP,},
	{.pattern = "RP:ADC:FRAmes:DATa", .callback = RP_ADC_GetFrames,},
	{.pattern = "RP:ADC:ACQCONNect", .callback = RP_ADC_StartAcquisitionConnection,},
	{.pattern = "RP:ADC:ACQSTATus", .callback = RP_ADC_SetAcquisitionStatus,},
	{.pattern = "RP:ADC:ACQSTATus?", .callback = RP_ADC_GetAcquisitionStatus,},
	{.pattern = "RP:PDM:CHannel#:NextValue", .callback = RP_PDM_SetPDMNextValue,},
	{.pattern = "RP:PDM:CHannel#:NextValueVolt", .callback = RP_PDM_SetPDMNextValueVolt,},
	{.pattern = "RP:PDM:CHannel#:NextValue?", .callback = RP_PDM_GetPDMNextValue,},
	{.pattern = "RP:PDM:CHannel#:CurrentValue?", .callback = RP_PDM_GetPDMCurrentValue,},
	{.pattern = "RP:XADC:CHannel#?", .callback = RP_XADC_GetXADCValueVolt,},
	{.pattern = "RP:WatchDogMode", .callback = RP_SetWatchdogMode,},
	{.pattern = "RP:WatchDogMode?", .callback = RP_GetWatchdogMode,},
	{.pattern = "RP:RamWriterMode", .callback = RP_SetRAMWriterMode,},
	{.pattern = "RP:RamWriterMode?", .callback = RP_GetRAMWriterMode,},
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

    SCPI_CMD_LIST_END
};
