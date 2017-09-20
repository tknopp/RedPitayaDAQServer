
/*
command to compile:
gcc -O3 pdm.c -o pdm
*/

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
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>

#define TCP_PORT 1001

int interrupted = 0;

void signal_handler(int sig)
{
  interrupted = 1;
}

int main ()
{
  printf("Starting main method\n");
  int mmapfd;
  uint64_t curr_pdm_channel, curr_pdm_channel_1, curr_pdm_channel_2, curr_pdm_channel_3, curr_pdm_channel_4;
  uint64_t last_pdm_channel, last_pdm_channel_1, last_pdm_channel_2, last_pdm_channel_3, last_pdm_channel_4;
  volatile uint32_t *slcr, *axi_hp0;
  volatile void *cfg, *sts, *ram, *buf;

  printf("Open memory\n");
  if((mmapfd = open("/dev/mem", O_RDWR)) < 0)
  {
    perror("open");
    return 1;
  }
  
  printf("Map memory\n");
  slcr = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0xF8000000);
  axi_hp0 = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0xF8008000);
  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40000000);
  sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40002000);

  /* set HP0 bus width to 64 bits */
  printf("Set bus properties\n");
  slcr[2] = 0xDF0D;
  slcr[144] = 0;
  axi_hp0[0] &= ~1;
  axi_hp0[5] &= ~1;

  last_pdm_channel_1 = 0;
  last_pdm_channel_2 = 0;
  last_pdm_channel_3 = 0;
  last_pdm_channel_4 = 0;

  *((uint64_t *)(cfg + 0)) = 0x0000234500001234;
  usleep(20);
last_pdm_channel = *((uint64_t *)(sts + 0));
printf("cfgr: %016x\n", last_pdm_channel);

  while(1)
    {
      /* read ram writer position */
      //printf("Read status\n");
      curr_pdm_channel = *((uint64_t *)(sts + 0));
printf("curr: %016x\n", curr_pdm_channel);
      curr_pdm_channel_1 = (curr_pdm_channel & 0x000000000000FFFF);
      curr_pdm_channel_2 = (curr_pdm_channel & 0x00000000FFFF0000) >> 16;
      curr_pdm_channel_3 = (curr_pdm_channel & 0x0000FFFF00000000) >> 32;
      curr_pdm_channel_4 = (curr_pdm_channel & 0xFFFF000000000000) >> 48;
printf("curr: %016x\n", curr_pdm_channel);
      printf("curr1: %04x; last1: %04x\n", curr_pdm_channel_1, last_pdm_channel_1);
      printf("curr2: %04x; last2: %04x\n", curr_pdm_channel_2, last_pdm_channel_2);
      printf("curr3: %04x; last3: %04x\n", curr_pdm_channel_3, last_pdm_channel_3);
      printf("curr4: %04x; last4: %04x\n", curr_pdm_channel_4, last_pdm_channel_4);

      /* send next sample if ready, otherwise sleep 5 us */
      last_pdm_channel = *((uint64_t *)(cfg + 0));
      if(last_pdm_channel == curr_pdm_channel)
      {
printf("if\n");

        if(last_pdm_channel_1 < 1024) {
          last_pdm_channel_1 += 1;
        } else {
          last_pdm_channel_1 = 0;
        }

        if(last_pdm_channel_2 < 200) {
          last_pdm_channel_2 += 1;
        } else {
          last_pdm_channel_2 = 0;
        }

        if(last_pdm_channel_3 < 256) {
          last_pdm_channel_3 += 1;
        } else {
          last_pdm_channel_3 = 0;
        }

printf("curr1: %04x; last1: %04x\n", curr_pdm_channel_1, last_pdm_channel_1);
      printf("curr2: %04x; last2: %04x\n", curr_pdm_channel_2, last_pdm_channel_2);
      printf("curr3: %04x; last3: %04x\n", curr_pdm_channel_3, last_pdm_channel_3);
      printf("curr4: %04x; last4: %04x\n", curr_pdm_channel_4, last_pdm_channel_4);

        *((uint64_t *)(cfg + 0)) = last_pdm_channel_1+(last_pdm_channel_2 << 16)+(last_pdm_channel_3 << 32)+(last_pdm_channel_4 << 48);
usleep(2000000);

printf("cfg: %016x\n", *((uint64_t *)(cfg + 0)));
      }
      else
      {
printf("else\n");
        usleep(2000000);
      }
    }
  return 0;
}
