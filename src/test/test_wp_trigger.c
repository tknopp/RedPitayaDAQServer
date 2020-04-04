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
  uint8_t wpPDM;
  uint64_t wpTotal;
  uint64_t i;
  init();
  setDACMode(DAC_MODE_RASTERIZED);
  setWatchdogMode(WATCHDOG_OFF);  

  setMasterTrigger(MASTER_TRIGGER_OFF);

  wp = getWritePointer();
  wpTotal = getTotalWritePointer();
  over = getWritePointerOverflows();
  printf("Write pointer = %u %u %llu\n", wp, over, wpTotal);
  usleep(1000000);

  setRAMWriterMode(ADC_MODE_TRIGGERED);
 setMasterTrigger(MASTER_TRIGGER_OFF);  
 usleep(1000000);
  setMasterTrigger(MASTER_TRIGGER_ON);
  
  while(getTriggerStatus() == 0)
  {
    printf("Waiting for external trigger!"); 
    usleep(40);
  }

  while(true)
  {
enableRamWriter();
  setMasterTrigger(MASTER_TRIGGER_ON);		
printf("Master Trigger On \n\n");
   for (i = 1; i < 50; ++i)
  {
    
  
    wp_old = wp;
    wp = getWritePointer();
    over = getWritePointerOverflows();
    wpTotal = getTotalWritePointer();
    wpPDM = getPDMStatusValue();

    uint32_t size = getWritePointerDistance(wp_old, wp)-1;

    printf("wp %u over %u wpDiff %u wpTotal %llu pdm %u \n", wp, over, size, wpTotal, wpPDM);
    if(size == 0) {
      printf("Write Pointer remains the same!");
    //  return 1;
    }

    usleep(20000);   
}
setMasterTrigger(MASTER_TRIGGER_OFF);
printf("Master Trigger OFF \n\n");
   for (i = 1; i < 50; ++i)                                                                                                                                                                                                              
	{                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      
	wp_old = wp;                                                                                                                                                                                                                           
	wp = getWritePointer();                                                                                                                                                                                                                
	over = getWritePointerOverflows();                                                                                                                                                                                                     
	wpTotal = getTotalWritePointer();                                                                                                                                                                                                      
	wpPDM = getPDMStatusValue();                                                                                                                                                                                                                                                                                                                                                                                                                                                  
	
	uint32_t size = getWritePointerDistance(wp_old, wp)-1;                                                                                                                                                                                                                                                                                                                                                                                                                        
	
	printf("wp %u over %u wpDiff %u wpTotal %llu pdm %u \n", wp, over, size, wpTotal, wpPDM);                                                                                                                                              
	if(size == 0) {                                                                                                                                                                                                                          
	resetRamWriter();
//	printf("Write Pointer remains the same!");                                                                                                                                                                                             
	//return 1;                                                                                                                                                                                                                            
	}                                                                                                                                                                                                                                                                                                                                                                                                                                                                             
	usleep(20000);                                                                                                                                                                                                                     
	}  
} 
  return 0;
}

