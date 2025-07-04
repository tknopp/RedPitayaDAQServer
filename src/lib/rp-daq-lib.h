#ifndef RP_DAQ_LIB_H
#define RP_DAQ_LIB_H

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/ioctl.h>

#define MASK_LOWER_48 0x0000ffffffffffff
#define MASK_LOWER_14 0x3fff
#define CHANNEL_OFFSET 13
#define COMPONENT_OFFSET 3
#define COMPONENT_START_OFFSET 1 
#define SIGNAL_TYPE_OFFSET 0
#define A_OFFSET SIGNAL_TYPE_OFFSET 0 
#define INCR_OFFSET A_OFFSET 0
#define AMPLITUDE_OFFSET  0 
#define FREQ_OFFSET 1
#define PHASE_OFFSET 2

#define BASE_FREQUENCY 125000000
#define ADC_BUFF_NUM_BITS 24 
#define ADC_BUFF_SIZE (1 << (ADC_BUFF_NUM_BITS+1)) 
#define ADC_BUFF_MEM_ADDRESS 0x18000000 // 0x1E000000  

#define PDM_BUFF_SIZE 8192
#define AWG_BUFF_SIZE 16384

#define DAC_MODE_AWG  1
#define	DAC_MODE_STANDARD   0

#define SIGNAL_TYPE_SINE 0
#define SIGNAL_TYPE_SQUARE 1
#define SIGNAL_TYPE_TRIANGLE 2
#define SIGNAL_TYPE_SAWTOOTH 3

#define ADC_MODE_CONTINUOUS 0
#define ADC_MODE_TRIGGERED 1

#define TRIGGER_MODE_INTERNAL 0
#define	TRIGGER_MODE_EXTERNAL 1

#define COUNTER_TRIGGER_DIO 0
#define	COUNTER_TRIGGER_ADC 1

#define OFF 0
#define ON 1

#define DIO_IN 1
#define DIO_OUT 0

#define CALIB_VERSION 2

extern bool verbose;

extern int mmapfd;
extern volatile uint32_t *slcr, *axi_hp0;
// FPGA registers that are memory mapped
extern void *pdm_sts, *reset_sts, *cfg, *ram, *buf, *dio_sts;
extern uint32_t *counter_trigger_cfg, *counter_trigger_sts;
extern uint16_t *pdm_cfg;
extern uint64_t *adc_sts, *dac_cfg; 
extern uint32_t *awg_0_cfg, *awg_1_cfg;
extern uint32_t *version_sts;

// init routines
extern uint32_t getFPGAId();
extern bool isZynq7010();
extern bool isZynq7015();
extern bool isZynq7020();
extern bool isZynq7030();
extern bool isZynq7045();
extern int init();
extern void loadBitstream();
extern uint32_t getFPGAImageVersion();

// fast DAC
extern uint16_t getAmplitude(int, int);
extern int setAmplitudeVolt(double, int, int);
extern int setAmplitude(uint16_t, int, int);
extern int16_t getOffset(int);
extern int setOffsetVolt(double, int);
extern int setOffset(int16_t, int);
extern double getFrequency(int, int);
extern int setFrequency(double, int, int);
extern double getPhase(int, int);
extern int setPhase(double, int, int);
extern int setDACMode(int);
extern int getDACMode();
extern int getSignalType(int, int);
extern int setSignalType(int, int, int);
extern int setCalibDACScale(float, int);
extern int setCalibDACOffset(float, int);
extern int setCalibDACLowerLimit(float, int);
extern int setCalibDACUpperLimit(float, int);
extern int setArbitraryWaveform(float*, int);
//extern int getRampingPeriod(int);

// Ramping
extern int getEnableRamping(int channel);
extern int setEnableRamping(int mode, int channel);
extern int setRampingFrequency(double, int);
extern double getRampingFrequency(int channel);
extern int setEnableRampDown(int mode, int channel);
extern int getEnableRampDown(int channel);
extern uint8_t getRampingState();

// fast ADC
extern int setDecimation(uint16_t decimation);
extern uint16_t getDecimation();
extern uint32_t getWritePointer();
extern uint64_t getTotalWritePointer();
extern uint32_t getInternalWritePointer(uint64_t wp);
extern uint32_t getInternalPointerOverflows(uint64_t wp) ;
extern uint32_t getWritePointerOverflows();
extern uint32_t getWritePointerDistance(uint32_t start_pos, uint32_t end_pos);
extern void readADCData(uint32_t wp, uint32_t size, uint32_t* buffer);
extern int resetRamWriter();
extern int enableRamWriter();

// Sequence
extern int getSamplesPerStep();
extern int setSamplesPerStep(int);
//extern int setPDMRegisterValue(uint64_t, int);
//extern int setPDMRegisterAllValues(uint64_t);
extern int setPDMValue(int16_t, int, int);
extern int setPDMAllValues(int16_t, int);
extern int setPDMValueVolt(float, int, int);
extern int setPDMAllValuesVolt(float, int);
extern uint64_t getPDMRegisterValue();
extern uint32_t getPDMWritePointer();
extern uint32_t getPDMTotalWritePointer();
extern int* getPDMNextValues();
extern int getPDMNextValue();
extern uint32_t getXADCValue(int);
extern float getXADCValueVolt(int);
extern int setEnableDACAll(int8_t, int);
extern int setEnableDAC(int8_t, int, int);
extern int setResyncDACAll(int8_t, int);
extern int setResyncDAC(int8_t, int, int);
//extern int setResetDAC(int8_t, int);
extern int setRampDownDAC(int8_t, int, int);
extern int setRampDownDACAll(int8_t, int);
extern int getRampDownDAC(int, int);

// Counter trigger
extern int counter_trigger_setEnabled(bool enable);
extern bool counter_trigger_isEnabled();
extern int counter_trigger_setPresamples(uint32_t presamples);
extern int counter_trigger_getPresamples();
extern int counter_trigger_arm();
extern int counter_trigger_disarm();
extern bool counter_trigger_isArmed();
extern int counter_trigger_setReset(bool reset);
extern bool counter_trigger_getReset();
extern uint32_t counter_trigger_getLastCounter();
extern int counter_trigger_setReferenceCounter();
extern uint32_t counter_trigger_getReferenceCounter();
extern uint32_t counter_trigger_getSelectedChannelType();
extern bool counter_trigger_setSelectedChannelType(uint32_t channelType);
extern char* counter_trigger_getSelectedChannel();
extern uint32_t counter_trigger_setSelectedChannel(const char* channel);

// Sequence
extern int getCounterSamplesPerStep();
extern int setCounterSamplesPerStep(int);

// misc
extern int getInternalPINNumber(const char*);
extern char* getPinFromInternalPINNumber(const uint32_t);
extern int getDIODirection(const char*);
extern int setDIODirection(const char*, int);
extern int setDIO(const char*, int);
extern int getDIO(const char*);
extern int getDIOHBridge(const char*);
extern int setDIOHBridge(const char*, int);
extern int setTriggerMode(int);
extern int getTriggerMode();
extern int setTriggerPropagation(int);
extern int getTriggerPropagation();
extern int getWatchdogMode();
extern int setWatchdogMode(int);
extern int getRAMWriterMode();
extern int setRAMWriterMode(int);
extern int getKeepAliveReset();
extern int setKeepAliveReset(int);
extern int getMasterTrigger();
extern int setMasterTrigger(int);
extern int getInstantResetMode();
extern int setInstantResetMode(int);
extern int getPeripheralAResetN();
extern int getFourierSynthAResetN();
extern int getPDMAResetN();
extern int getWriteToRAMAResetN();
extern int getXADCAResetN();
extern int getTriggerStatus();
extern int getWatchdogStatus();
extern int getInstantResetStatus();
extern void stopTx();

// Calibration

/**
 * Calibration parameters, stored in the EEPROM device
 */
typedef struct {
    char id[3+1];
    int version;
    uint16_t set_flags;
    float adc_ch1_fs;
    float adc_ch1_offs;
    float adc_ch2_fs;
    float adc_ch2_offs;
    float dac_ch1_fs;
    float dac_ch1_offs;
    float dac_ch2_fs;
    float dac_ch2_offs;
    float dac_ch1_lower;
    float dac_ch1_upper;
    float dac_ch2_lower;
    float dac_ch2_upper;
} rp_calib_params_t;

extern int calib_Init();
extern int calib_Release();
extern int calib_validate(rp_calib_params_t * calib_params);
extern int calib_apply();

extern int calib_setADCOffset(rp_calib_params_t * calib_params, float value, int channel);
extern int calib_setADCScale(rp_calib_params_t * calib_params, float value, int channel);
extern int calib_setDACOffset(rp_calib_params_t * calib_params, float value, int channel);
extern int calib_setDACScale(rp_calib_params_t * calib_params, float value, int channel);
extern int calib_setDACLowerLimit(rp_calib_params_t * calib_params, float value, int channel);
extern int calib_setDACUpperLimit(rp_calib_params_t * calib_params, float value, int channel);

extern rp_calib_params_t calib_GetParams();
extern rp_calib_params_t calib_GetDefaultCalib();
extern double getCalibDACScale(int channel, bool isPDM);
extern int calib_WriteParams(rp_calib_params_t calib_params,bool use_factory_zone);
extern int calib_SetParams(rp_calib_params_t calib_params);
extern void calib_SetToZero();
extern int calib_LoadFromFactoryZone();

uint32_t cmn_CalibFullScaleFromVoltage(float voltageScale);

#endif /* RP_DAQ_LIB_H */
