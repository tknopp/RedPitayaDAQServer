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

#include "rp-instrument-lib.h"

int mmapfd;
volatile uint32_t *slcr, *axi_hp0;
volatile void *dac_cfg, *adc_sts, *pdm_cfg, *pdm_sts, *ram, *buf;

int init()
{

  // Open memory
  if((mmapfd = open("/dev/mem", O_RDWR)) < 0)
  {
    perror("open");
    return 1;
  }

  // Map memory
  slcr = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0xF8000000);
  axi_hp0 = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0xF8008000);
  dac_cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40000000);
  adc_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40001000);
  pdm_cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40002000);
  pdm_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40003000);
  ram = mmap(NULL, 2048*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x1E000000);
  buf = mmap(NULL, 2048*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);

  // set HP0 bus width to 64 bits
  slcr[2] = 0xDF0D;
  slcr[144] = 0;
  axi_hp0[0] &= ~1;
  axi_hp0[5] &= ~1;

  return 0;
}

uint16_t getAmplitude(int channel, int component) {
  if(channel < 0 || channel > 1) {
    return -3;
  }

  if(component < 0 || component > 3) {
    return -4;
  }

  uint16_t amplitude = *((uint16_t *)(dac_cfg + 2*component + 4*channel));

  return amplitude;
}

int setAmplitude(uint16_t amplitude, int channel, int component)
{
  if(amplitude < 0 || amplitude >= 8192) {
    return -2;
  }

  if(channel < 0 || channel > 1) {
    return -3;
  }

  if(component < 0 || component > 3) {
    return -4;
  }

  *((uint16_t *)(dac_cfg + 2*component + 4*channel)) = amplitude;

  return 0;
}

double getFrequency(int channel, int component) {
  if(channel < 0 || channel > 1) {
    return -3;
  }

  if(component < 0 || component > 3) {
    return -4;
  }

  uint32_t phase_increment = *((uint32_t *)(dac_cfg + 12 + 4*component + 16*channel));
  
  // Calculate frequency from phase increment
  double frequency = phase_increment*125000000.0/pow(2, 28);
  
  return frequency;
}

int setFrequency(double frequency, int channel, int component)
{
  if(frequency < 0.5 || frequency >= 125000000) {
    return -2;
  }

  if(channel < 0 || channel > 1) {
    return -3;
  }

  if(component < 0 || component > 3) {
    return -4;
  }

  // Calculate phase increment
  uint32_t phase_increment = (uint32_t)round(frequency*pow(2, 28)/125000000);
  printf("phase_increment for frequency %f Hz is %04x.\n", frequency, phase_increment);

  *((uint32_t *)(dac_cfg + 12 + 4*component + 16*channel)) = phase_increment;

  return 0;
}

double getPhase(int channel, int component)
{
  if(channel < 0 || channel > 1) {
    return -3;
  }

  if(component < 0 || component > 3) {
    return -4;
  }

  // Calculate phase factor from phase offset
  uint32_t phase_offset = *((uint32_t *)(dac_cfg + 44 + 4*component + 16*channel));
  double phase_factor = phase_offset/pow(2, 28);

  return phase_factor;
}

int setPhase(double phase_factor, int channel, int component)
{
  if(phase_factor < 0.0 || phase_factor > 1.0) {
    return -2;
  }

  if(channel < 0 || channel > 1) {
    return -3;
  }

  if(component < 0 || component > 3) {
    return -4;
  }

  // Calculate phase offset
  uint32_t phase_offset = (uint32_t)floor(phase_factor*pow(2, 28));
  printf("phase_offset for %f*2*pi rad is %04x.\n", phase_factor, phase_offset);

  *((uint32_t *)(dac_cfg + 44 + 4*component + 16*channel)) = phase_offset;

  return 0;
}
