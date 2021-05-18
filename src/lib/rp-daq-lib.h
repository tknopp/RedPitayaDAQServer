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


#define BASE_FREQUENCY 125000000
#define ADC_BUFF_NUM_BITS 24 
#define ADC_BUFF_SIZE (1 << (ADC_BUFF_NUM_BITS+1)) 
#define ADC_BUFF_MEM_ADDRESS 0x18000000 // 0x1E000000  

#define PDM_BUFF_SIZE 128  

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

#define OFF 0
#define ON 1

#define IN 0
#define OUT 1

extern bool verbose;

extern int mmapfd;
extern volatile uint32_t *slcr, *axi_hp0;
// FPGA registers that are memory mapped
extern void *adc_sts, *pdm_sts, *reset_sts, *cfg, *ram, *buf, *dio_sts;
extern char *pdm_cfg, *dac_cfg; 

// init routines
extern int init();
extern void loadBitstream();

// fast DAC
extern uint16_t getAmplitude(int, int);
extern int setAmplitude(uint16_t, int, int);
extern int16_t getOffset(int);
extern int setOffset(int16_t, int);
extern double getFrequency(int, int);
extern int setFrequency(double, int, int);
extern double getPhase(int, int);
extern int setPhase(double, int, int);
extern int setDACMode(int);
extern int getDACMode();
extern int getSignalType(int);
extern int setSignalType(int, int);
extern float getJumpSharpness(int);
extern int setJumpSharpness(int, float);

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

// slow IO
extern int getPDMClockDivider();
extern int setPDMClockDivider(int);
extern int setPDMRegisterValue(uint64_t, int);
extern int setPDMRegisterAllValues(uint64_t);
extern int setPDMValue(int16_t, int, int);
extern int setPDMAllValues(int16_t, int);
extern int setPDMValueVolt(float, int, int);
extern int setPDMAllValuesVolt(float, int);
extern uint64_t getPDMRegisterValue();
extern uint64_t getPDMWritePointer();
extern uint64_t getPDMTotalWritePointer();
extern int* getPDMNextValues();
extern int getPDMNextValue();
extern uint32_t getXADCValue(int);
extern float getXADCValueVolt(int);
extern int setEnableDACAll(int8_t, int);
extern int setEnableDAC(int8_t, int, int);

// misc
extern int setDIODirection(const char*,int);
extern int setDIO(const char*,int);
extern int getDIO(const char*);
extern int setTriggerMode(int);
extern int getTriggerMode();
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
extern int getPassPDMToFastDAC();
extern int setPassPDMToFastDAC(int);
extern void stopTx();

// Calibration

// From https://github.com/RedPitaya/RedPitaya/blob/e7f4f6b161a9cbbbb3f661228a6e8c5b8f34f661/api/include/redpitaya/rp_Z20_125.h#L264
/**
 * Calibration parameters, stored in the EEPROM device
 */
typedef struct {
    uint32_t fe_ch1_fs_g_hi;    //!< High gain front end full scale voltage, channel A
    uint32_t fe_ch2_fs_g_hi;    //!< High gain front end full scale voltage, channel B
    uint32_t fe_ch1_fs_g_lo;    //!< Low gain front end full scale voltage, channel A
    uint32_t fe_ch2_fs_g_lo;    //!< Low gain front end full scale voltage, channel B
    int32_t  fe_ch1_lo_offs;    //!< Front end DC offset, channel A
    int32_t  fe_ch2_lo_offs;    //!< Front end DC offset, channel B
    uint32_t be_ch1_fs;         //!< Back end full scale voltage, channel A
    uint32_t be_ch2_fs;         //!< Back end full scale voltage, channel B
    int32_t  be_ch1_dc_offs;    //!< Back end DC offset, channel A
    int32_t  be_ch2_dc_offs;    //!< Back end DC offset, on channel B
	uint32_t magic;			    //!
    int32_t  fe_ch1_hi_offs;    //!< Front end DC offset, channel A
    int32_t  fe_ch2_hi_offs;    //!< Front end DC offset, channel B
    uint32_t low_filter_aa_ch1;  //!< Filter equalization coefficients AA for Low mode, channel A
    uint32_t low_filter_bb_ch1;  //!< Filter equalization coefficients BB for Low mode, channel A
    uint32_t low_filter_pp_ch1;  //!< Filter equalization coefficients PP for Low mode, channel A
    uint32_t low_filter_kk_ch1;  //!< Filter equalization coefficients KK for Low mode, channel A
    uint32_t low_filter_aa_ch2;  //!< Filter equalization coefficients AA for Low mode, channel B
    uint32_t low_filter_bb_ch2;  //!< Filter equalization coefficients BB for Low mode, channel B
    uint32_t low_filter_pp_ch2;  //!< Filter equalization coefficients PP for Low mode, channel B
    uint32_t low_filter_kk_ch2;  //!< Filter equalization coefficients KK for Low mode, channel B
    uint32_t  hi_filter_aa_ch1;  //!< Filter equalization coefficients AA for High mode, channel A
    uint32_t  hi_filter_bb_ch1;  //!< Filter equalization coefficients BB for High mode, channel A
    uint32_t  hi_filter_pp_ch1;  //!< Filter equalization coefficients PP for High mode, channel A
    uint32_t  hi_filter_kk_ch1;  //!< Filter equalization coefficients KK for High mode, channel A
    uint32_t  hi_filter_aa_ch2;  //!< Filter equalization coefficients AA for High mode, channel B
    uint32_t  hi_filter_bb_ch2;  //!< Filter equalization coefficients BB for High mode, channel B
    uint32_t  hi_filter_pp_ch2;  //!< Filter equalization coefficients PP for High mode, channel B
    uint32_t  hi_filter_kk_ch2;  //!< Filter equalization coefficients KK for High mode, channel B   

} rp_calib_params_t;

// From https://github.com/RedPitaya/RedPitaya/blob/e7f4f6b161a9cbbbb3f661228a6e8c5b8f34f661/api/src/calib.h

extern int calib_Init();
extern int calib_Release();

extern rp_calib_params_t calib_GetParams();
extern rp_calib_params_t calib_GetDefaultCalib();
extern int calib_WriteParams(rp_calib_params_t calib_params,bool use_factory_zone);
extern int calib_SetParams(rp_calib_params_t calib_params);
extern void calib_SetToZero();
extern int calib_LoadFromFactoryZone();

uint32_t cmn_CalibFullScaleFromVoltage(float voltageScale)

#endif /* RP_DAQ_LIB_H */
