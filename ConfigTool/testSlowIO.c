#include <unistd.h>
#include <stdio.h>
#include <stdlib.h>
#include <getopt.h>

#include "rp-instrument-lib.h"

/* Compile
    gcc -c -Wall -Werror -fpic rp-instrument-lib.c
    gcc -shared -o rp-instrument-lib.so rp-instrument-lib.o
    gcc rp-instrument-configuration.c rp-instrument-lib.o -o rp-instrument-configuration
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:./
*/

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



