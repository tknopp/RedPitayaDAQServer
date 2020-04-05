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
#include <netinet/in.h>
#include <pthread.h>
#include <sched.h>

#include "../lib/rp-daq-lib.h"

int main () {
  uint32_t wp, wp_old, over, over_old;
  uint64_t wpPDM;
  uint64_t wpTotal;

  init();
  setDACMode(DAC_MODE_RASTERIZED);
  setWatchdogMode(OFF);  

  //setMasterTrigger(MASTER_TRIGGER_OFF);

  wp = getWritePointer();
  wpTotal = getTotalWritePointer();
  over = getWritePointerOverflows();
  printf("Write pointer = %u %u %llu\n", wp, over, wpTotal);


  setAmplitude(7000,0,0);


  for(int i=0; i<PDM_BUFF_SIZE; i++)
  {
    float val = ((float) i)/ PDM_BUFF_SIZE;
    setPDMValueVolt(val,0,i);
    printf("Set LUT: %d  %f\n", i, val);
  }


  setRAMWriterMode(ADC_MODE_TRIGGERED);
  usleep(100000);
  setMasterTrigger(ON);
  
  while(getTriggerStatus() == 0)
  {
    printf("Waiting for external trigger!"); 
    usleep(40);
  }

  while(true)
  {
    wp_old = wp;
    wp = getWritePointer();
    over = getWritePointerOverflows();
    wpTotal = getTotalWritePointer();
   for(int i=0; i<PDM_BUFF_SIZE; i++)
  {
    float val = ((float) i)/ PDM_BUFF_SIZE;
    setPDMValueVolt(val,0,i);
    printf("Set LUT: %d  %f\n", i, val);
  }

   
    //setPDMAllValuesVolt(0.4, 0);
    wpPDM = getPDMStatusValue();

    uint32_t size = getWritePointerDistance(wp_old, wp)-1;

    printf("wp %u over %u wpDiff %u wpTotal %llu pdm %llu \n", wp, over, size, wpTotal, wpPDM);
    if(size == 0) {
      printf("Write Pointer remains the same!");
      return 1;
    }

    usleep(10000);
  } 
  return 0;
}

