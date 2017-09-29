#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

#include "../lib/rp-daq-lib.h"

/* Compile
    gcc -c -Wall -Werror -fpic rp-instrument-lib.c
    gcc -shared -o rp-instrument-lib.so rp-instrument-lib.o
    gcc rp-instrument-configuration.c rp-instrument-lib.o -o rp-instrument-configuration
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./
*/

int main(int argc, char *argv[]) {
  setSlave();
  init();
  setDACMode(DAC_MODE_RASTERIZED);
  setAmplitude(0x0FFF, 0, 0);  
  setAmplitude(0x0222, 0, 1);
  setAmplitude(0x0333, 0, 2);
  setAmplitude(0x0444, 0, 3);
  setAmplitude(0x0555, 1, 0);
  setAmplitude(0x0666, 1, 1);
  setAmplitude(0x0777, 1, 2);
  setAmplitude(0x0888, 1, 3);
  
  /*setAmplitude(0x0, 0, 1);
  setAmplitude(0x0, 0, 2);
  setAmplitude(0x0, 0, 3);
  setAmplitude(0x0, 1, 0);
  setAmplitude(0x0, 1, 1);
  setAmplitude(0x0, 1, 2);
  setAmplitude(0x0, 1, 3);
  
  /*setFrequency(25000, 0, 0);
  setFrequency(50000, 0, 1);
  setFrequency(75000, 0, 2);
  setFrequency(125000, 0, 3);
  setFrequency(175000, 1, 0);
  setFrequency(225000, 1, 1);
  setFrequency(275000, 1, 2);
  setFrequency(325000, 1, 3);
*/
  setPhase(0.1, 0, 0);
  setPhase(0.2, 0, 1);
  setPhase(0.3, 0, 2);
  setPhase(0.4, 0, 3);
  setPhase(0.5, 1, 0);
  setPhase(0.6, 1, 1);
  setPhase(0.7, 1, 2);
  setPhase(0.8, 1, 3);
 
  //setFrequency(125000, 0, 0);
  setModulusFactor(1, 0, 0);
  setModulusFactor(2, 0, 1);
  setModulusFactor(3, 0, 2);
  setModulusFactor(4, 0, 3);
  setModulusFactor(5, 1, 0);
  setModulusFactor(6, 1, 1);
  setModulusFactor(7, 1, 2);
  setModulusFactor(8, 1, 3);

  //setWatchdogMode(WATCHDOG_ON);
  setRAMWriterMode(ADC_MODE_TRIGGERED);
  setMasterTrigger(MASTER_TRIGGER_ON);

  usleep(1000);

  printf("test getAmplitude (channel 0, component 0): %04x\n", getAmplitude(0, 0));
  printf("test getFrequency (channel 0, component 0): %f Hz\n", getFrequency(0, 0));
  printf("test getPhase (channel 0, component 0): %f*2*pi rad\n", getPhase(0, 0));

  printf("getPeripheralAResetN(): %d\n", getPeripheralAResetN());
  printf("getFourierSynthAResetN(): %d\n", getFourierSynthAResetN());
  printf("getPDMAResetN(): %d\n", getPDMAResetN());
  printf("getWriteToRAMAResetN(): %d\n", getWriteToRAMAResetN());
  printf("getXADCAResetN(): %d\n", getXADCAResetN());
  printf("getTriggerStatus(): %d\n", getTriggerStatus());
  printf("getWatchdogStatus(): %d\n", getWatchdogStatus());
  printf("getInstantResetStatus(): %d\n", getInstantResetStatus());

  setDecimation(32);
  printf("getDecimation(): %d", getDecimation());
  
  return 0;
}
