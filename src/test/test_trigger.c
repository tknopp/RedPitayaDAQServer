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
  uint32_t wp, wp_old;

  init();
  setDACMode(DAC_MODE_RASTERIZED);
  setWatchdogMode(WATCHDOG_OFF);  

  setMasterTrigger(MASTER_TRIGGER_OFF);
  setRAMWriterMode(ADC_MODE_TRIGGERED);

  while(true)
  {
    setMasterTrigger(MASTER_TRIGGER_OFF);
    usleep(400000);
    setMasterTrigger(MASTER_TRIGGER_ON);
    usleep(40);

    while(getTriggerStatus() == 0)
    {
      printf("Waiting for external trigger!"); 
      usleep(40);
    }

    wp_old = getWritePointer();
    usleep(10000);
    wp = getWritePointer();

    uint32_t size = getWritePointerDistance(wp_old, wp)-1;

    printf("____ %d %d %d \n", size, wp_old, wp);
    if(size == 0) {
      printf("Write Pointer remains the same!");
      return 1;
    }

    usleep(40);    
  } 
  return 0;
}

