#ifndef __SCPI_COMMANDS_H_
#define __SCPI_COMMANDS_H_

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
#include "daq_server_scpi.h"

#define ACQUISITION_OFF 0
#define ACQUISITION_ON 1

extern int newdatasockfd;
extern struct sockaddr_in newdatasockaddr;
extern socklen_t newdatasocklen;

extern const scpi_command_t scpi_commands[];
/*extern scpi_choice_def_t DAC_modes[];
extern scpi_choice_def_t watchdog_modes[];
extern scpi_choice_def_t RAM_writer_modes[];
extern scpi_choice_def_t master_trigger_modes[];
extern scpi_choice_def_t instant_reset_modes[];

extern static scpi_result_t RP_DAC_GetAmplitude(scpi_t *);
extern static scpi_result_t RP_DAC_SetAmplitude(scpi_t *);
extern static scpi_result_t RP_DAC_GetFrequency(scpi_t *) ;
extern static scpi_result_t RP_DAC_SetFrequency(scpi_t *);
extern static scpi_result_t RP_DAC_GetModulusFactor(scpi_t *);
extern static scpi_result_t RP_DAC_SetModulusFactor(scpi_t *);
extern static scpi_result_t RP_DAC_GetPhase(scpi_t *);
extern static scpi_result_t RP_DAC_SetPhase(scpi_t *);
extern static scpi_result_t RP_DAC_SetDACMode(scpi_t *);
extern static scpi_result_t RP_DAC_GetDACMode(scpi_t *);
extern static scpi_result_t RP_DAC_ReconfigureDACModulus(scpi_t *);
extern static scpi_result_t RP_DAC_GetDACModulus(scpi_t *);

extern static scpi_result_t RP_ADC_SetDecimation(scpi_t *);
extern static scpi_result_t RP_ADC_GetDecimation(scpi_t *);
extern static scpi_result_t RP_ADC_SetSamplesPerPeriod(scpi_t *);
extern static scpi_result_t RP_ADC_GetSamplesPerPeriod(scpi_t *);
extern static scpi_result_t RP_ADC_SetPeriodsPerFrame(scpi_t *);
extern static scpi_result_t RP_ADC_GetPeriodsPerFrame(scpi_t *);
extern static scpi_result_t RP_ADC_GetCurrentFrame(scpi_t *);
extern static scpi_result_t RP_ADC_GetFrames(scpi_t *);
extern static scpi_result_t RP_ADC_StartAcquisitionConnection(scpi_t *);
extern static scpi_result_t RP_ADC_SetAcquisitionStatus(scpi_t *);

extern static scpi_result_t RP_PDM_SetPDMNextValue(scpi_t *);
extern static scpi_result_t RP_PDM_GetPDMNextValue(scpi_t *);
extern static scpi_result_t RP_PDM_GetPDMCurrentValue(scpi_t *);

extern static scpi_result_t RP_XADC_GetXADCValueVolt(scpi_t *);

extern static scpi_result_t RP_WatchdogMode(scpi_t *);
extern static scpi_result_t RP_RAMWriterMode(scpi_t *);
extern static scpi_result_t RP_MasterTrigger(scpi_t *);
extern static scpi_result_t RP_InstantResetMode(scpi_t *);

extern static scpi_result_t RP_PeripheralAResetN(scpi_t *);
extern static scpi_result_t RP_FourierSynthAResetN(scpi_t *);
extern static scpi_result_t RP_PDMAResetN(scpi_t *);
extern static scpi_result_t RP_WriteToRAMAResetN(scpi_t *);
extern static scpi_result_t RP_XADCAResetN(scpi_t *);
extern static scpi_result_t RP_TriggerStatus(scpi_t *);
extern static scpi_result_t RP_WatchdogStatus(scpi_t *);
extern static scpi_result_t RP_InstantResetStatus(scpi_t *);*/

#endif /* __SCPI_COMMANDS_H_ */
