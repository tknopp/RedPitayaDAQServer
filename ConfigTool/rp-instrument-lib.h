#ifndef RP_INSTRUMENT_LIB_H
#define RP_INSTRUMENT_LIB_H

#include <stdio.h>
#include <stdint.h>
#include <string.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/ioctl.h>

#define BASE_FREQUENCY 125000000

extern int mmapfd;
extern volatile uint32_t *slcr, *axi_hp0;
extern volatile void *dac_cfg, *adc_sts, *pdm_cfg, *pdm_sts, *ram, *buf;

#define DAC_MODE_RASTERIZED 0
#define	DAC_MODE_STANDARD   1
extern int dac_mode; // 0 => rasterized (divider based), 1 => standard (frequency based)

extern uint16_t dac_channel_A_modulus[4];
extern uint16_t dac_channel_B_modulus[4];

extern int init();
extern void load_bitstream();
extern uint16_t getAmplitude(int, int);
extern int setAmplitude(uint16_t, int, int);
extern double getFrequency(int, int);
extern int setFrequency(double, int, int);
extern int getModulusFactor(int, int);
extern int setModulusFactor(int, int, int);
extern double getPhase(int, int);
extern int setPhase(double, int, int);
extern int setDACMode(int);
extern int getDACMode();
extern int reconfigureDACModulus(int, int, int);
extern int setPDMRegisterValue(uint64_t);
extern uint64_t getPDMRegisterValue();
extern uint64_t getPDMStatusValue();
extern int setPDMNextValues(uint16_t, uint16_t, uint16_t, uint16_t);
extern int* getPDMNextValues();
extern int setPDMNextValue(uint16_t, int);
extern int setPDMNextValueVolt(float, int);
extern int getPDMNextValue();
extern int getPDMCurrentValue(int);
extern int* getPDMCurrentValues();

extern uint32_t getXADCValue(int);
extern float getXADCValueVolt(int);

#endif /* RP_INSTRUMENT_LIB_H */
