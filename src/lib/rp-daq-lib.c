#include <stdio.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>
#include <stdbool.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>
#include <math.h>
#include <sys/mman.h>
#include <sys/types.h>
#include <sys/ioctl.h>

#include "rp-daq-lib.h"

int mmapfd;
volatile uint32_t *slcr, *axi_hp0;
volatile void *dac_cfg, *adc_sts, *pdm_cfg, *pdm_sts, *reset_sts, *cfg, *ram, *buf;

uint16_t dac_channel_A_modulus[4] = {4800, 4800, 4800, 4800};
uint16_t dac_channel_B_modulus[4] = {4800, 4800, 4800, 4800};

bool master = true;

static const uint32_t ANALOG_OUT_MASK            = 0xFF;
static const uint32_t ANALOG_OUT_BITS            = 16;
static const uint32_t ANALOG_IN_MASK             = 0xFFF;

static const float    ANALOG_IN_MAX_VAL          = 7.0;
static const float    ANALOG_IN_MIN_VAL          = 0.0;
static const uint32_t ANALOG_IN_MAX_VAL_INTEGER  = 0xFFF;
static const float    ANALOG_OUT_MAX_VAL         = 1.8;
static const float    ANALOG_OUT_MIN_VAL         = 0.0;
static const uint32_t ANALOG_OUT_MAX_VAL_INTEGER = 156;

void load_bitstream()
{
  if(isMaster()) {
    system("cat /root/RedPitayaDAQServer/bitfiles/master.bin > /dev/xdevcfg");
  } else {
    system("cat /root/RedPitayaDAQServer/bitfiles/master.bin > /dev/xdevcfg");
  }
}

int init() {
  load_bitstream();

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
  reset_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40005000);
  cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40004000);
  ram = mmap(NULL, 2048*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x1E000000);
  buf = mmap(NULL, 2048*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED|MAP_ANONYMOUS, -1, 0);

  // set HP0 bus width to 64 bits
  slcr[2] = 0xDF0D;
  slcr[144] = 0;
  axi_hp0[0] &= ~1;
  axi_hp0[5] &= ~1;

  return 0;
}

bool isMaster() {
  return master;
}

bool isSlave() {
  return !master;
}

void setMaster() {
  master = true;
}

void setSlave() {
  master = false;
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

int setAmplitude(uint16_t amplitude, int channel, int component) {
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

    uint32_t register_value = *((uint32_t *)(dac_cfg + 16 + 4*component + 16*channel));
    double frequency = -1;
    if(getDACMode() == DAC_MODE_STANDARD) {
        // Calculate frequency from phase increment
        frequency = register_value*((double)BASE_FREQUENCY)/pow(2, 32);
    } else if(getDACMode() == DAC_MODE_RASTERIZED) {
        int modulus = -1;
        if(channel == 0) {
            modulus = dac_channel_A_modulus[component];
        } else {
            modulus = dac_channel_B_modulus[component];
        }
    
        // Calculate frequency from modulus factor
        frequency = register_value*((double)BASE_FREQUENCY)/modulus;
    }

    return frequency;
}

int setFrequency(double frequency, int channel, int component)
{
    if(frequency < 0.03 || frequency >= ((double)BASE_FREQUENCY)) {
        return -2;
    }

    if(channel < 0 || channel > 1) {
        return -3;
    }

    if(component < 0 || component > 3) {
        return -4;
    }

    if(getDACMode() == DAC_MODE_STANDARD) {
        // Calculate phase increment
        uint32_t phase_increment = (uint32_t)round(frequency*pow(2, 32)/((double)BASE_FREQUENCY));
        printf("phase_increment for frequency %f Hz is %04x.\n", frequency, phase_increment);

        *((uint32_t *)(dac_cfg + 16 + 4*component + 16*channel)) = phase_increment;
    } else if(getDACMode() == DAC_MODE_RASTERIZED) {
        int modulus = -1;
        if(channel == 0) {
            modulus = dac_channel_A_modulus[component];
        } else {
            modulus = dac_channel_B_modulus[component];
        }
        
        // Calculate modulus factor
        int modulus_factor = (int)round(frequency*modulus/((double)BASE_FREQUENCY));
        printf("modulus_factor for frequency %f Hz is %04x.\n", frequency, modulus_factor);
        
        setModulusFactor(modulus_factor, channel, component);
    }

    return 0;
}

int getModulusFactor(int channel, int component)
{
    if(channel < 0 || channel > 1) {
        return -3;
    }

    if(component < 0 || component > 3) {
        return -4;
    }

    int modulus_factor = (int)(*((uint32_t *)(dac_cfg + 16 + 4*component + 16*channel)));

    return modulus_factor;
}

int setModulusFactor(uint32_t modulus_factor, int channel, int component)
{
    if(channel < 0 || channel > 1) {
        return -3;
    }

    if(component < 0 || component > 3) {
        return -4;
    }

    int modulus = -1;
    if(channel == 0) {
        modulus = dac_channel_A_modulus[component];
    } else {
        modulus = dac_channel_B_modulus[component];
    }
  
    if(modulus_factor < 0 || modulus_factor > modulus) {
        return -2;
    }

    printf("Setting modulus factor to %d\n", modulus_factor);

    *((uint32_t *)(dac_cfg + 16 + 4*component + 16*channel)) = modulus_factor;

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

    // Get register value
    uint32_t register_value = *((uint32_t *)(dac_cfg + 48 + 4*component + 16*channel));
    double phase_factor = -1;
    if(getDACMode() == DAC_MODE_STANDARD) {
        // Calculate phase factor from phase offset
        phase_factor = register_value/pow(2, 32);
    } else if(getDACMode() == DAC_MODE_RASTERIZED) {
        int modulus = -1;
        if(channel == 0) {
            modulus = dac_channel_A_modulus[component];
        } else {
            modulus = dac_channel_B_modulus[component];
        }
        
        phase_factor = ((double)register_value)/modulus;
    }

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

    if(getDACMode() == DAC_MODE_STANDARD) {
        // Calculate phase offset
        uint32_t phase_offset = (uint32_t)floor(phase_factor*pow(2, 32));
        printf("phase_offset for %f*2*pi rad is %04x.\n", phase_factor, phase_offset);

        *((uint32_t *)(dac_cfg + 48 + 4*component + 16*channel)) = phase_offset;
    } else if(getDACMode() == DAC_MODE_RASTERIZED) {
        int modulus = -1;
        if(channel == 0) {
            modulus = dac_channel_A_modulus[component];
        } else {
            modulus = dac_channel_B_modulus[component];
        }
        
        // Calculate modulus fraction
        uint32_t modulus_fraction = (uint32_t)round(phase_factor*modulus);
        printf("modulus_fraction for %f*2*pi rad is %04x.\n", phase_factor, modulus_fraction);
        
        *((uint32_t *)(dac_cfg + 48 + 4*component + 16*channel)) = modulus_fraction;
    }

    return 0;
}

int setDACMode(int mode) {
    if(mode == DAC_MODE_STANDARD) {
        *((uint32_t *)(cfg + 0)) &= ~8;
    } else if(mode == DAC_MODE_RASTERIZED) {
        *((uint32_t *)(cfg + 0)) |= 8;
    } else {
        return -1;
    }
    
    return 0;
}

int getDACMode() {
    uint32_t register_value = *((uint32_t *)(cfg + 0));
    return ((register_value & 0x00000008) >> 3);
}

/**
  * If the modulus values of some DDS compilers were modified in the FPGA code
  * the modulus values have to be changed in the C program accordingly.
  * This is the purpose of this function. 
  */
int reconfigureDACModulus(int modulus, int channel, int component) {
    if(modulus < 9 || modulus > 16384) {
        return -2;
    }
    
    if(channel < 0 || channel > 1) {
        return -3;
    }
    
    if(component < 0 || component > 3) {
        return -4;
    }
    
    if(channel == 0) {
        dac_channel_A_modulus[component] = modulus;
    }
    
    if(channel == 1) {
        dac_channel_B_modulus[component] = modulus;
    }
    
    return 0;
}

int getDACModulus(int channel, int component) {
    if(channel < 0 || channel > 1) {
        return -3;
    }
    
    if(component < 0 || component > 3) {
        return -4;
    }
    
    if(channel == 0) {
        return dac_channel_A_modulus[component];
    }
    
    if(channel == 1) {
        return dac_channel_B_modulus[component];
    }
    
    return -1;
}

int setPDMRegisterValue(uint64_t value) {
    *((uint64_t *)(pdm_cfg)) = value;
    return 0;
}

uint64_t getPDMRegisterValue() {
    uint64_t value = *((uint64_t *)(pdm_cfg));
    return value;
}

uint64_t getPDMStatusValue() {
    uint64_t value = *((uint64_t *)(pdm_sts));
    return value;
}

int setPDMNextValues(uint16_t channel_1_value, uint16_t channel_2_value, uint16_t channel_3_value, uint16_t channel_4_value) {
    if(channel_1_value < 0 || channel_1_value >= 2048) {
        return -1;
    }
    
    if(channel_2_value < 0 || channel_2_value >= 2048) {
        return -2;
    }
    
    if(channel_3_value < 0 || channel_3_value >= 2048) {
        return -3;
    }
    
    if(channel_4_value < 0 || channel_4_value >= 2048) {
        return -4;
    }

    uint64_t combined_value = (uint64_t)channel_1_value + ((uint64_t)channel_2_value << 16) + ((uint64_t)channel_3_value << 32) + ((uint64_t)channel_4_value << 48);
    setPDMRegisterValue(combined_value);
    
    return 0;
}

int* getPDMNextValues() {
    uint64_t register_value = getPDMRegisterValue();
    static int channel_values[4];
    channel_values[0] = (register_value & 0x000000000000FFFF);
    channel_values[1] = (register_value & 0x00000000FFFF0000) >> 16;
    channel_values[2] = (register_value & 0x0000FFFF00000000) >> 32;
    channel_values[3] = (register_value & 0xFFFF000000000000) >> 48;
    
    return channel_values;
}

int setPDMNextValue(uint16_t value, int channel) {
    if(value < 0 || value >= 2048) {
        return -1;
    }
    
    if(channel < 0 || channel >= 4) {
        return -2;
    }
    
    *((uint16_t *)(pdm_cfg + 2*channel)) = value;
    
    return 0;
}

int setPDMNextValueVolt(float voltage, int channel) {
//    uint16_t val = (uint16_t) (((value - ANALOG_OUT_MIN_VAL) / (ANALOG_OUT_MAX_VAL - ANALOG_OUT_MIN_VAL)) * ANALOG_OUT_MAX_VAL_INTEGER);
  //int n;
  /// Not sure what is correct here: might be helpful https://forum.redpitaya.com/viewtopic.php?f=9&t=614
  if (voltage > 1.8) voltage = 1.8;
  if (voltage < 0) voltage = 0;
  //n = (voltage / 1.8) * 2496.;
  //uint16_t val = ((n / 16) << 16) + (0xffff >> (16 - (n % 16)));
  uint16_t val = (voltage / 1.8) * 2038.;

  //printf("set val %04x.\n", val);
  return setPDMNextValue(val, channel);
}

int getPDMNextValue(int channel) {
    if(channel < 0 || channel >= 4) {
        return -2;
    }
    
    int value = (int)(*((uint16_t *)(pdm_cfg + 2*channel)));
    
    return value;
}

int getPDMCurrentValue(int channel) {
    if(channel < 0 || channel >= 4) {
        return -2;
    }
    
    int value = (int)(*((uint16_t *)(pdm_sts + 2*channel)));
    
    return value;
}

int* getPDMCurrentValues() {
    uint64_t register_value = getPDMStatusValue();
    static int channel_values[4];
    channel_values[0] = (register_value & 0x000000000000FFFF);
    channel_values[1] = (register_value & 0x00000000FFFF0000) >> 16;
    channel_values[2] = (register_value & 0x0000FFFF00000000) >> 32;
    channel_values[3] = (register_value & 0xFFFF000000000000) >> 48;
    
    return channel_values;
}


// Slow Analog Inputs

uint32_t getXADCValue(int channel) {
    FILE *fp;
    uint32_t value;
    switch (channel) {
        case 0:  fp = fopen ("/sys/bus/iio/devices/iio:device0/in_voltage11_vaux8_raw", "r");  break;
        case 1:  fp = fopen ("/sys/bus/iio/devices/iio:device0/in_voltage9_vaux0_raw" , "r");  break;
        case 2:  fp = fopen ("/sys/bus/iio/devices/iio:device0/in_voltage10_vaux1_raw", "r");  break;
        case 3:  fp = fopen ("/sys/bus/iio/devices/iio:device0/in_voltage12_vaux9_raw", "r");  break;
        default:
            return 1;
    }
    fscanf (fp, "%d", &value);
    fclose(fp);
    return value;
}


float getXADCValueVolt(int channel) {
    uint32_t value_raw = getXADCValue(channel);
    return (((float)value_raw / ANALOG_IN_MAX_VAL_INTEGER) * (ANALOG_IN_MAX_VAL - ANALOG_IN_MIN_VAL)) + ANALOG_IN_MIN_VAL;
}

int setWatchdogMode(int mode) {
    if(mode == WATCHDOG_OFF) {
        *((uint8_t *)(cfg + 1)) &= ~2;
    } else if(mode == WATCHDOG_ON) {
        *((uint8_t *)(cfg + 1)) |= 2;
    } else {
        return -1;
    }
    
    return 0;
}

int setRAMWriterMode(int mode) {
    if(mode == ADC_MODE_CONTINUOUS) {
        *((uint8_t *)(cfg + 1)) &= ~1;
    } else if(mode == ADC_MODE_TRIGGERED) {
        *((uint8_t *)(cfg + 1)) |= 1;
    } else {
        return -1;
    }
    
    return 0;
}

int setMasterTrigger(int mode) {
    if(mode == MASTER_TRIGGER_OFF) {
        *((uint8_t *)(cfg + 1)) &= ~4;
    } else if(mode == MASTER_TRIGGER_ON) {
        *((uint8_t *)(cfg + 1)) |= 4;
    } else {
        return -1;
    }
    
    return 0;
}

int getPeripheralAResetN() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x01) >> 0);
    
    return value;
}

int getFourierSynthAResetN() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x02) >> 1);
    
    return value;
}

int getPDMAResetN() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x04) >> 2);
    
    return value;
}

int getWriteToRAMAResetN() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x08) >> 3);
    
    return value;
}

int getXADCAResetN() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x10) >> 4);
    
    return value;
}

int getTriggerStatus() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x20) >> 5);
    
    return value;
}

int getWatchdogStatus() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x40) >> 6);
    
    return value;
}

int getInstantResetStatus() {
    int value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x80) >> 7);
    
    return value;
}

int setDecimation(uint16_t decimation) {
    *((uint16_t *)(cfg + 2)) = decimation;
    return 0;
}

uint16_t getDecimation() {
    uint16_t value = *((uint16_t *)(cfg + 2));
    return value;
}
