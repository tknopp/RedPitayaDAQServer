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

extern int mmapfd;
extern volatile uint32_t *slcr, *axi_hp0;
extern volatile void *dac_cfg, *adc_sts, *pdm_cfg, *pdm_sts, *ram, *buf;

extern int init();
extern uint16_t getAmplitude(int, int);
extern int setAmplitude(uint16_t, int, int);
extern double getFrequency(int, int);
extern int setFrequency(double, int, int);
extern double getPhase(int, int);
extern int setPhase(double, int, int);


#endif /* RP_INSTRUMENT_LIB_H */
