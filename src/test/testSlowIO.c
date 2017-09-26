#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

#include "../lib/rp-daq-lib.h"

int main(int argc, char *argv[]) {
  init();

  float val=0.9;
  
  setPDMNextValueVolt(val, 0);
  setPDMNextValueVolt(val, 1);
  setPDMNextValueVolt(val, 2);
  setPDMNextValueVolt(val, 3);

  usleep(1000000);

  float v0 = getXADCValueVolt(0);
  float v1 = getXADCValueVolt(1);
  float v2 = getXADCValueVolt(2);
  float v3 = getXADCValueVolt(3);

  printf("%f %f %f %f \n",v0,v1,v2,v3);

  return 0;
}



