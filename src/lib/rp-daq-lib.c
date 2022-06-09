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
#include <sys/socket.h> /* for socket(), connect(), send(), and recv() */
#include <arpa/inet.h>  /* for sockaddr_in and inet_addr() */
#include <time.h>
#include <limits.h>
#include "rp-daq-lib.h"

bool verbose = false;

int mmapfd;
volatile uint32_t *slcr, *axi_hp0;
void *adc_sts, *pdm_sts, *reset_sts, *cfg, *ram, *dio_sts;
char *pdm_cfg;
uint64_t *dac_cfg;
volatile int32_t *xadc;

// static const uint32_t ANALOG_OUT_MASK            = 0xFF;
// static const uint32_t ANALOG_OUT_BITS            = 16;
// static const uint32_t ANALOG_IN_MASK             = 0xFFF;

static const float    ANALOG_IN_MAX_VAL          = 7.0;
static const float    ANALOG_IN_MIN_VAL          = 0.0;
static const uint32_t ANALOG_IN_MAX_VAL_INTEGER  = 0xFFF;
// static const float    ANALOG_OUT_MAX_VAL         = 1.8;
// static const float    ANALOG_OUT_MIN_VAL         = 0.0;
// static const uint32_t ANALOG_OUT_MAX_VAL_INTEGER = 156;

// Cached parameter values.
static rp_calib_params_t calib;

static int16_t getCalibDACOffset(int channel) {
	if (channel == 0) 
		return (int16_t)(calib.dac_ch1_offs*8192.0);
	else if (channel == 1)
		return (int16_t)(calib.dac_ch1_offs*8192.0);
	else
		return 0;
}

double getCalibDACScale(int channel, bool isPDM) {
	if (isPDM || channel >= 2) 
		return 1.0;
	else  if (channel == 0)
		return calib.dac_ch1_fs;
	else if (channel == 1)
		return calib.dac_ch2_fs;
	else
		return 0.0;
}

// Init stuff

uint32_t getFPGAId() {
	// Refer to "Register PSS_IDCODE Details" on page 1607 in https://www.xilinx.com/support/documentation/user_guides/ug585-Zynq-7000-TRM.pdf
	uint32_t id = (slcr[332] >> 12) & 0x1f;
	return id;
}

bool isZynq7010() {
	return (getFPGAId() == 0x02);
}

bool isZynq7015() {
	return (getFPGAId() == 0x1b);
}

bool isZynq7020() {
	return (getFPGAId() == 0x07);
}

bool isZynq7030() {
	return (getFPGAId() == 0x0c);
}

bool isZynq7045() {
	return (getFPGAId() == 0x11);
}

void loadBitstream() {
	if(!access("/tmp/bitstreamLoaded", F_OK )){
		printf("Bitfile already loaded\n");
	} else {
		printf("Load Bitfile\n");
		int catResult = 0;

		if(isZynq7020()) {
			printf("loading bitstream /root/apps/RedPitayaDAQServer/bitfiles/daq_xc7z020clg400-1.bit\n");
			catResult = system("cat /root/apps/RedPitayaDAQServer/bitfiles/daq_xc7z020clg400-1.bit > /dev/xdevcfg");
		}
		else {
			printf("loading bitstream /root/apps/RedPitayaDAQServer/bitfiles/daq_xc7z010clg400-1.bit\n");
			catResult = system("cat /root/apps/RedPitayaDAQServer/bitfiles/daq_xc7z010clg400-1.bit > /dev/xdevcfg");
		}
		

		if(catResult <= -1) {
			printf("Error while writing the image to the FPGA.\n");
		}
		else {
			printf("Bitsream loaded\n");
		}

		FILE* fp = fopen("/tmp/bitstreamLoaded", "a");
		int writeResult = fprintf(fp, "loaded \n");

		if(writeResult <= -1) {
			printf("Error while writing to the status file.\n");
		}

		fclose(fp);
	}

}

int init() {
	// Open memory
	if((mmapfd = open("/dev/mem", O_RDWR|O_SYNC)) < 0) {
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
	dio_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40006000);
	cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40004000);
	ram = mmap(NULL, sizeof(int32_t)*ADC_BUFF_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, ADC_BUFF_MEM_ADDRESS);
	xadc = mmap(NULL, 16*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40010000);

	loadBitstream();
	
	calib_Init(); // Load calibration from EEPROM
	calib_validate(&calib);
	printf("Using calibration version %d with: %u\n", calib.version, calib.set_flags);
	calib_apply();

	// Set HP0 bus width to 64 bits
	slcr[2] = 0xDF0D;
	slcr[144] = 0;
	axi_hp0[0] &= ~1;
	axi_hp0[5] &= ~1;

	// Explicitly set default values
	setDecimation(16);
	printf("Decimation = %d \n", getDecimation());
	setDACMode(DAC_MODE_STANDARD);
	setWatchdogMode(OFF);
	setRAMWriterMode(ADC_MODE_TRIGGERED);
	setMasterTrigger(OFF);
	setInstantResetMode(OFF);
	setPassPDMToFastDAC(OFF);

	stopTx();

	/*setFrequency(25000, 0, 0);
	  setFrequency(25000, 0, 1);
	  setFrequency(25000, 0, 2);
	  setFrequency(25000, 0, 3);
	  setFrequency(25000, 1, 0);
	  setFrequency(25000, 1, 1);
	  setFrequency(25000, 1, 2);
	  setFrequency(25000, 1, 3);*/

	setPhase(0, 0, 0);
	setPhase(0, 0, 1);
	setPhase(0, 0, 2);
	setPhase(0, 0, 3);
	setPhase(0, 1, 0);
	setPhase(0, 1, 1);
	setPhase(0, 1, 2);
	setPhase(0, 1, 3);

	setAmplitude(0, 0, 0);
	setAmplitude(0, 0, 1);
	setAmplitude(0, 0, 2);
	setAmplitude(0, 0, 3);
	setAmplitude(0, 1, 0);
	setAmplitude(0, 1, 1);
	setAmplitude(0, 1, 2);
	setAmplitude(0, 1, 3);

	setOffset(0, 0);
	setOffset(0, 1);

	setEnableDACAll(1, 0);
	setEnableDACAll(1, 1);
	setEnableDACAll(1, 2);
	setEnableDACAll(1, 3);

	return 0;
}

// fast DAC

uint16_t getAmplitude(int channel, int component) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	if(component < 0 || component > 3) {
		return -4;
	}

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + AMPLITUDE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel);
	uint16_t amplitude = (uint16_t)(register_value >> 48);
	return amplitude;
}

int setAmplitudeVolt(double amplitude, int channel, int component) {
	return setAmplitude((uint16_t)(amplitude*8192.0), channel, component);
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

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + AMPLITUDE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((uint64_t) amplitude) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + AMPLITUDE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel) = register_value;

	return 0;
}

int16_t getOffset(int channel) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	uint64_t register_value = *(dac_cfg + CHANNEL_OFFSET*channel);
	int16_t offset = (int16_t)(register_value >> 48);

	return offset;
}

int setOffsetVolt(double offset, int channel) {
	return setOffset((int16_t)(offset*8192.0), channel);
}
int setOffset(int16_t offset, int channel) {
	if(offset < -8191 || offset >= 8192) {
		return -2;
	}

	if(channel < 0 || channel > 1) {
		return -3;
	}

	uint64_t register_value = *(dac_cfg + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) offset) << 48) & ~MASK_LOWER_48);

	*(dac_cfg + CHANNEL_OFFSET*channel) = register_value;

	return 0;
}

double getFrequency(int channel, int component) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	if(component < 0 || component > 3) {
		return -4;
	}

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel) & MASK_LOWER_48;
	double frequency = -1;
	if(getDACMode() == DAC_MODE_STANDARD) {
		// Calculate frequency from phase increment
		frequency = register_value*((double)BASE_FREQUENCY)/pow(2, 48);
	} else {
		// TODO AWG
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
		uint64_t phase_increment = (uint64_t)round(frequency*pow(2, 48)/((double)BASE_FREQUENCY));

		if(verbose) {
			printf("Phase_increment for frequency %f Hz is %08llx.\n", frequency, phase_increment);
		}

		uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel);
		register_value = (register_value & ~MASK_LOWER_48) | ( phase_increment & MASK_LOWER_48);
		*(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel) = register_value;

	} else {
		// TODO AWG
	}

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
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel) & MASK_LOWER_48;
	double phase_factor = -1;
	if(getDACMode() == DAC_MODE_STANDARD) {
		// Calculate phase factor from phase offset
		phase_factor = register_value/pow(2, 48);
	} else {
		// TODO AWG
	}

	return phase_factor*2*M_PI;
}

int setPhase(double phase, int channel, int component)
{
	phase = fmod(phase, 2*M_PI);
	phase = (phase < 0) ? phase+2*M_PI : phase;

	double phase_factor = phase / (2*M_PI);

	if(channel < 0 || channel > 1) {
		return -3;
	}

	if(component < 0 || component > 3) {
		return -4;
	}

	if(getDACMode() == DAC_MODE_STANDARD) {
		// Calculate phase offset
		uint64_t phase_offset = (uint64_t)floor(phase_factor*pow(2, 48));

		if(verbose) {
			printf("phase_offset for %f*2*pi rad is %08llx.\n", phase_factor, phase_offset);
		}

		uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel);
		register_value = (register_value & ~MASK_LOWER_48) | ( phase_offset & MASK_LOWER_48);
		*(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel) = register_value;
		
	} else {
		// TODO AWG
	}

	return 0;
}

int setDACMode(int mode) {
	//if(mode == DAC_MODE_STANDARD) {
	//    *((uint32_t *)(cfg + 0)) &= ~8;
	//} else if(mode == DAC_MODE_AWG) {
	// TODO AWG
	//*((uint32_t *)(cfg + 0)) |= 8;
	//} else {
	//    return -1;
	//}

	return 0;
}

int getDACMode() {
	return DAC_MODE_STANDARD;
	//uint32_t register_value = *((uint32_t *)(cfg + 0));
	//return ((register_value & 0x00000008) >> 3);
}

int setSignalType(int signal_type, int channel, int component) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	if(component < 0 || component > 3) {
		return -4;
	}

	if((signal_type != SIGNAL_TYPE_SINE)
			&& (signal_type != SIGNAL_TYPE_SQUARE)
			&& (signal_type != SIGNAL_TYPE_TRIANGLE)
			&& (signal_type != SIGNAL_TYPE_SAWTOOTH)) {
		return -2;
	}
	
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel);
	uint64_t mask = 0x000000000000ffff;
	register_value = (register_value & ~mask) | (signal_type & mask);
	*(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel) = register_value;

	return 0;
}

int getSignalType(int channel, int component) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	if(component < 0 || component > 3) {
		return -4;
	}

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel);
	uint64_t mask = 0x000000000000ffff;
	int value = (int) (register_value & mask);
	return value;
}

int setJumpSharpness(float percentage, int channel, int component) {
	if(channel < 0 || channel > 1 || percentage == 0.0) {
		return -3;
	}

	if(component < 0 || component > 3) {
		return -4;
	}

	int16_t A = (int16_t) (8191*percentage);
	int16_t A_incr = (int16_t) (8191/A);
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel);
	uint64_t mask = 0x00000000ffff0000;
	register_value = (register_value & ~mask) | (A & mask);
	mask = 0x0000ffff00000000;
	register_value = (register_value & ~mask) | (A_incr & mask);
	*(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel) = register_value;

	return 0;
}

float getJumpSharpness(int channel, int component) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	if(component < 0 || component > 3) {
		return -4;
	}

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel);
	uint64_t mask = 0x00000000ffff0000;
	int value = (int) ((register_value & mask) >> 16);

	return ((float)value)/8191.0;
}

int setCalibDACScale(float value, int channel) {
	if (channel < 0 || channel > 1) {
		return -3;
	}

	int16_t scale = (int16_t)(value*8191.0);
	if (scale < -8191 || scale >= 8192) {
		return -2;
	}
	// Config scale is stored in first component freq
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) scale) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}

int setCalibDACOffset(float value, int channel) {
	if (channel < 0 || channel > 1) {
		return -3;
	}
	
	int16_t offset = (int16_t)(value*8191.0);
	if (offset < -8191 || offset >= 8192) {
		return -2;
	}
	// Config offset is stored in first component phase
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) offset) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}


// Fast ADC

int setDecimation(uint16_t decimation) {
	if(decimation < 8 || decimation > 8192) {
		return -1;
	}

	*((uint16_t *)(cfg + 2)) = decimation;
	return 0;
}

uint16_t getDecimation() {
	uint16_t value = *((uint16_t *)(cfg + 2));
	return value;
}

#define BIT_MASK(__TYPE__, __ONE_COUNT__) \
	((__TYPE__) (-((__ONE_COUNT__) != 0))) \
	& (((__TYPE__) -1) >> ((sizeof(__TYPE__) * CHAR_BIT) - (__ONE_COUNT__)))

uint32_t getWritePointer() {
	uint32_t val = (*((uint32_t *)(adc_sts + 0)));
	uint32_t mask = BIT_MASK(uint64_t, ADC_BUFF_NUM_BITS); // Extract lower bits
	return 2*(val&mask);
}

uint32_t getInternalWritePointer(uint64_t wp) {
	uint32_t mask = BIT_MASK(uint64_t, ADC_BUFF_NUM_BITS+1); // Extract lower bits
	return wp&mask;
}

uint32_t getInternalPointerOverflows(uint64_t wp) {
	return wp >> (ADC_BUFF_NUM_BITS + 1);
}

uint32_t getWritePointerOverflows() {
	return (*(((uint64_t *)(adc_sts + 0)))) >> ADC_BUFF_NUM_BITS; // Extract upper bits
}

uint64_t getTotalWritePointer() {
	return 2*(*(((uint64_t *)(adc_sts + 0))));
}

uint32_t getWritePointerDistance(uint32_t start_pos, uint32_t end_pos) {
	end_pos   = end_pos   % ADC_BUFF_SIZE;
	start_pos = start_pos % ADC_BUFF_SIZE;
	if (end_pos < start_pos)
		end_pos += ADC_BUFF_SIZE;
	return end_pos - start_pos + 1;
}

void readADCData(uint32_t wp, uint32_t size, uint32_t* buffer) {
	if(wp+size <= ADC_BUFF_SIZE) {

		memcpy(buffer, ram + sizeof(uint32_t)*wp, size*sizeof(uint32_t));

	} else {
		uint32_t size1 = ADC_BUFF_SIZE - wp;
		uint32_t size2 = size - size1;

		memcpy(buffer, ram + sizeof(uint32_t)*wp, size1*sizeof(uint32_t));
		memcpy(buffer+size1, ram, size2*sizeof(uint32_t));
	}
}

// Slow IO
int setEnableDACAll(int8_t value, int channel) {
	for(int i=0; i<PDM_BUFF_SIZE; i++) {
		setEnableDAC(value,channel,i);
	}
	return 0;
}

int setEnableDAC(int8_t value, int channel, int index) {

	if(value < 0 || value >= 2) {
		return -1;
	}

	if(channel < 0 || channel >= 4) {
		return -2;
	}

	int bitpos = 12 + channel;

	// The enable bits are in the 4-th slowDAC channel
	// clear the bit
	*((int16_t *)(pdm_cfg + 2*(3+4*index))) &= ~(1u << bitpos);
	// set the bit
	*((int16_t *)(pdm_cfg + 2*(3+4*index))) |= (value << bitpos);

	return 0;
}

int setResetDAC(int8_t value, int index) {
	if (value < 0 || value >= 2)
		return -1;

	//printf("%d before reset pdm\n", *((int16_t *)(pdm_cfg + 2*(0+4*index))));
	int bitpos = 14;
	// Reset bit is in the 1-th channel
	// clear the bit
	*((int16_t *)(pdm_cfg + 2*(0+4*index))) &= ~(1u << bitpos);
	// set the bit
	*((int16_t *)(pdm_cfg + 2*(0+4*index))) |= (value << bitpos);
	//printf("%d reset pdm\n", *((int16_t *)(pdm_cfg + 2*(0+4*index))));
	return 0;
}

int setRampDownDAC(int8_t value, int channel, int index) {
	if(value < 0 || value >= 2) {
		return -1;
	}

	if(channel < 0 || channel > 1) {
		return -2;
	}

	int bitpos = 14 + channel * 1; // 14 or 15
	// Ramp Down bit is in the 3rd channel
	// clear the bit
	*((int16_t *)(pdm_cfg + 2*(2+4*index))) &= ~(1u << bitpos);
	// set the bit
	*((int16_t *)(pdm_cfg + 2*(2+4*index))) |= (value << bitpos);
	return 0;
}

int setPDMRegisterValue(uint64_t value, int index) {
	//printf("setPDMRegisterValue: value=%llu index=%d \n", value, index);
	*(((uint64_t *)(pdm_cfg))+index) = value;
	return 0;
}

int setPDMRegisterAllValues(uint64_t value) {
	for(int i=0; i<PDM_BUFF_SIZE; i++) {
		setPDMRegisterValue(value,i);
	}
	return 0;
}

int setPDMValue(int16_t value, int channel, int index) {
	//printf("setPDMValue: value=%d channel=%d index=%d \n", value, channel, index);

	//if(value < 0 || value >= 2048) {
	/*if( value >= 8192) {
	  return -1;
	  }*/

	if(channel < 0 || channel >= 4) {
		return -2;
	}

	//printf("%p   %p   %d \n", (void*)pdm_cfg, (void*)((uint16_t *)(pdm_cfg+2*(channel+4*index))), 2*(channel+4*index) );
	*((int16_t *)(pdm_cfg + 2*(channel+4*index))) = value;

	return 0;
}

int setPDMAllValues(int16_t value, int channel) {
	for(int i=0; i<PDM_BUFF_SIZE; i++) {
		setPDMValue(value, channel, i);
	}
	return 0;
}

int setPDMValueVolt(float voltage, int channel, int index) {
	//    uint16_t val = (uint16_t) (((value - ANALOG_OUT_MIN_VAL) / (ANALOG_OUT_MAX_VAL - ANALOG_OUT_MIN_VAL)) * ANALOG_OUT_MAX_VAL_INTEGER);
	//int n;
	/// Not sure what is correct here: might be helpful https://forum.redpitaya.com/viewtopic.php?f=9&t=614

	//n = (voltage / 1.8) * 2496.;
	//uint16_t val = ((n / 16) << 16) + (0xffff >> (16 - (n % 16)));

	int16_t val;

	if( !getPassPDMToFastDAC() || channel >= 2 ) {
		if (voltage > 1.8) voltage = 1.8;
		if (voltage < 0) voltage = 0;
		val = (voltage / 1.8) * 2038.;
	} else {
		if (voltage > 1) voltage = 1;
		if (voltage < -1) voltage = -1;
		val = voltage * 8192.;
	}

	//printf("set val %04x.\n", val);
	return setPDMValue(val, channel, index);
}

int setPDMAllValuesVolt(float voltage, int channel) {
	for(int i=0; i<PDM_BUFF_SIZE; i++) {
		setPDMValueVolt(voltage, channel, i);
	}
	return 0;
}

int getPDMClockDivider() {
	int32_t value = *((int32_t *)(cfg + 4));
	return value*2;
}

int setPDMClockDivider(int divider) {
	printf("SetPDMClockDivider to %d\n", divider);

	*((int32_t *)(cfg + 4)) = divider/2;

	return 0;
}

uint64_t getPDMRegisterValue() {
	uint64_t value = *((uint64_t *)(pdm_cfg));
	return value;
}

uint64_t getPDMTotalWritePointer() {
	uint64_t value = *((uint64_t *)(pdm_sts));
	return value;
}

uint64_t getPDMWritePointer() {
	uint64_t value = *((uint64_t *)(pdm_sts));
	return value % PDM_BUFF_SIZE;
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

int getPDMNextValue(int channel) {
	if(channel < 0 || channel >= 4) {
		return -2;
	}

	int value = (int)(*((uint16_t *)(pdm_cfg + 2*channel)));

	return value;
}


// Slow Analog Inputs

uint32_t getXADCValue(int channel) {
	uint32_t value;
	switch (channel) {
		case 0:  value = xadc[152] >> 4; break;
		case 1:  value = xadc[144] >> 4; break;
		case 2:  value = xadc[145] >> 4; break;
		case 3:  value = xadc[153] >> 4; break;
		default:
			 return 1;
	}
	return value;
}

float getXADCValueVolt(int channel) {
	uint32_t value_raw = getXADCValue(channel);
	return (((float)value_raw / ANALOG_IN_MAX_VAL_INTEGER) * (ANALOG_IN_MAX_VAL - ANALOG_IN_MIN_VAL)) + ANALOG_IN_MIN_VAL;
}

int getWatchdogMode() {
	int value = (((int)(*((uint8_t *)(cfg + 1))) & 0x02) >> 1);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}

	return -1;
}

int setWatchdogMode(int mode) {
	if(mode == OFF) {
		*((uint8_t *)(cfg + 1)) &= ~2;
	} else if(mode == ON) {
		*((uint8_t *)(cfg + 1)) |= 2;
	} else {
		return -1;
	}

	return 0;
}

int getRAMWriterMode() {
	int value = (((int)(*((uint8_t *)(cfg + 1))) & 0x01) >> 0);

	if(value == 0) {
		return ADC_MODE_CONTINUOUS;
	} else if(value == 1) {
		return ADC_MODE_TRIGGERED;
	}

	return -1;
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

int getTriggerMode() {
	int value = (((int)(*((uint8_t *)(cfg + 1))) & 0x10) >> 4);

	if(value == 0) {
		return TRIGGER_MODE_INTERNAL;
	} else if(value == 1) {
		return TRIGGER_MODE_EXTERNAL;
	}

	return -1;
}

int setTriggerMode(int mode) {
	if(mode == TRIGGER_MODE_INTERNAL) {
		*((uint8_t *)(cfg + 1)) &= ~16;
	} else if(mode == TRIGGER_MODE_EXTERNAL) {
		*((uint8_t *)(cfg + 1)) |= 16;
	} else {
		return -1;
	}

	return 0;
}

int getMasterTrigger() {
	int value;

	value = ((int)(*((uint8_t *)(reset_sts + 1))) & 0x01);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}

	return -1;
}

int setMasterTrigger(int mode) {
	if(mode == OFF) {
		setKeepAliveReset(ON);
		double waitTime = getPDMClockDivider() / 125e6;
		usleep( 10*waitTime * 1000000);
		*((uint8_t *)(cfg + 1)) &= ~(1 << 5);
		usleep( 10*waitTime * 1000000);
		setRAMWriterMode(ADC_MODE_TRIGGERED);
		setKeepAliveReset(OFF);
	} else if(mode == ON) {
			*((uint8_t *)(cfg + 1)) |= (1 << 5);
	} else {
		return -1;
	}

	return 0;
}

// RAMPING
int getEnableRamping(int channel) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	int value = (int)((*((uint8_t *)(cfg + 10)) >> channel) & 1);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}
	return -1;
}

int setEnableRamping(int mode, int channel) {
	if (mode != OFF && mode != ON) {
		return -1;
	}

	if(channel < 0 || channel > 1) {
		return -3;
	}

	if (mode == OFF) {
		*((uint8_t *)(cfg + 10)) &= ~(1 << channel);
	}
	else {
		*((uint8_t *)(cfg + 10)) |= (1 << channel);
	}
	return 0;
}

int setEnableRampDown(int mode, int channel) {
	if (mode != OFF && mode != ON) {
		return -1;
	}

	if(channel < 0 || channel > 1) {
		return -3;
	}

	if (mode == OFF) {
		*((uint8_t *)(cfg + 10)) &= ~(1 << (channel + 2));
	}
	else {
		*((uint8_t *)(cfg + 10)) |= (1 << (channel + 2));
	}
	return 0;
}

int getEnableRampDown(int channel) {
	if(channel < 0 || channel > 1) {
		return -3;
	}

	int value = (int)((*((uint8_t *)(cfg + 10)) >> (channel + 2)) & 1);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}
	return -1;	
}

int setRampingFrequency(double period, int channel) {
	if(channel < 0 || channel > 1) {
		return -3;
	}
	
	if(period < 0.03 || period >= ((double)BASE_FREQUENCY)) {
		return -2;
	}

	uint64_t phase_increment = (uint64_t)round(period*pow(2, 48)/((double)BASE_FREQUENCY));

	uint64_t register_value = *(dac_cfg + CHANNEL_OFFSET*channel);
	register_value = (register_value & ~MASK_LOWER_48) | (phase_increment & MASK_LOWER_48);
	*(dac_cfg + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}

double getRampingFrequency(int channel) {
	if(channel < 0 || channel > 1) {
		return -3;
	}
	uint64_t register_value = *(dac_cfg + CHANNEL_OFFSET*channel) & MASK_LOWER_48;
	double period_factor = register_value*((double)BASE_FREQUENCY)/pow(2, 48);
	return period_factor;
}

uint8_t getRampingState() {
	uint8_t value = *((uint8_t *)(reset_sts + 2));
	return value;
}

int getInstantResetMode() {
	int value = (((int)(*((uint8_t *)(cfg + 1))) & 0x08) >> 3);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}

	return -1;
}

int setInstantResetMode(int mode) {
	if(mode == OFF) {
		*((uint8_t *)(cfg + 1)) &= ~8;
	} else if(mode == ON) {
		*((uint8_t *)(cfg + 1)) |= 8;
	} else {
		return -1;
	}

	return 0;
}

int getPassPDMToFastDAC() {
	int value = (((int)(*((uint8_t *)(cfg))) & 0x08) >> 3);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}

	return -1;
}

int setPassPDMToFastDAC(int mode) {
	if(mode == OFF) {
		*((uint8_t *)(cfg)) &= ~8;
	} else if(mode == ON) {
		*((uint8_t *)(cfg)) |= 8;
	} else {
		return -1;
	}

	return 0;
}

int getKeepAliveReset() {
	int value = (((int)(*((uint8_t *)(cfg + 1))) & 0x40) );

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}

	return -1;
}

int setKeepAliveReset(int mode) {
	if(mode == OFF) {
		if(getMasterTrigger() == OFF) { // we only disable the Ram Writer if the trigger is off
			uint32_t wp, wp_old, size;
			wp_old = getWritePointer();
			do {
				usleep(100);
				wp = getWritePointer();
				size = getWritePointerDistance(wp_old, wp) - 1;
				wp_old = wp;
				printf("setRamWriterEnabled: wp %d  wp_old %d  size  %d \n", wp, wp_old, size);
			} while(size > 0);
			*((uint8_t *)(cfg + 1)) &= ~64;
		}
	} else if(mode == ON) {
		*((uint8_t *)(cfg + 1)) |= 64;
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
	int value;

	if(getTriggerMode() == TRIGGER_MODE_INTERNAL)
	{
		value = (((int)(*((uint8_t *)(cfg + 1))) & 0x20) >> 5);
	} else {
		value = (((int)(*((uint8_t *)(reset_sts + 0))) & 0x20) >> 5);
	}
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

int getInternalPINNumber(const char* pin) {
	if(strncmp(pin, "DIO7_P", 6) == 0) {
		return 0;
	} else if(strncmp(pin, "DIO7_N", 6) == 0) {
		return 1;
	} else if(strncmp(pin, "DIO6_P", 6) == 0) {
		return 2;
	} else if(strncmp(pin, "DIO6_N", 6) == 0) {
		return 3;
	} else if(strncmp(pin, "DIO5_N", 6) == 0) {
		return 4;
	} else if(strncmp(pin, "DIO4_N", 6) == 0) {
		return 5;
	} else if(strncmp(pin, "DIO3_N", 6) == 0) {
		return 6;
	} else if(strncmp(pin, "DIO2_N", 6) == 0) {
		return 7;
	} else {
		return -1;
	}
}

int getDIODirection(const char* pin) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return -3;
	}

	uint32_t register_value = *((uint8_t *)(dio_sts));
	register_value = ((register_value & (0x1 << (pinInternal))) >> (pinInternal));
	
	if(register_value == 1) {
		return IN;
	} else {
		return OUT;
	}
}

int setDIODirection(const char* pin, int value) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return -3;
	}

	if(value == OUT) {
		*((uint8_t *)(cfg + 9)) &= ~(0x1 << (pinInternal));
	} else if(value == IN) {
		*((uint8_t *)(cfg + 9)) |= (0x1 << (pinInternal));
	} else {
		return -1;
	}

	return 0;
}

int setDIO(const char* pin, int value) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return -3;
	}

	if(value == OFF) {
		*((uint8_t *)(cfg + 8)) &= ~(0x1 << (pinInternal));
	} else if(value == ON) {
		*((uint8_t *)(cfg + 8)) |= (0x1 << (pinInternal));
	} else {
		return -1;
	}

	return 0;
}

int getDIO(const char* pin) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return -3;
	}

	uint32_t register_value = *((uint8_t *)(dio_sts));
	return ((register_value & (0x1 << (pinInternal))) >> (pinInternal));
}

void stopTx() {
	setAmplitude(0, 0, 0);
	setAmplitude(0, 0, 1);
	setAmplitude(0, 0, 2);
	setAmplitude(0, 0, 3);
	setAmplitude(0, 1, 0);
	setAmplitude(0, 1, 1);
	setAmplitude(0, 1, 2);
	setAmplitude(0, 1, 3);

	setPDMAllValuesVolt(0.0, 0);
	setPDMAllValuesVolt(0.0, 1);
	setPDMAllValuesVolt(0.0, 2);
	setPDMAllValuesVolt(0.0, 3);


	for(int d=0; d<4; d++) {
		setEnableDACAll(1,d);
	}
}

// Calibration

// From https://github.com/RedPitaya/RedPitaya/blob/e7f4f6b161a9cbbbb3f661228a6e8c5b8f34f661/api/src/calib.c

#define CALIB_MAGIC 0xAABBCCDD
#define CALIB_MAGIC_FILTER 0xDDCCBBAA
#define GAIN_LO_FILT_AA 0x7D93
#define GAIN_LO_FILT_BB 0x437C7
#define GAIN_LO_FILT_PP 0x2666
#define GAIN_LO_FILT_KK 0xd9999a
#define GAIN_HI_FILT_AA 0x4205
#define GAIN_HI_FILT_BB 0x2F38B
#define GAIN_HI_FILT_PP 0x2666
#define GAIN_HI_FILT_KK 0xd9999a

int calib_ReadParams(rp_calib_params_t *calib_params,bool use_factory_zone);
rp_calib_params_t getDefaultCalib();

static const char eeprom_device[]="/sys/bus/i2c/devices/0-0050/eeprom";
static const int  eeprom_calib_off=0x0008;
static const int  eeprom_calib_factory_off = 0x1c08;

int calib_Init()
{
    calib_ReadParams(&calib,false);
    return 0; // Success
}

int calib_Release()
{
    return 0; // Success
}

/**
 * Returns cached parameter values
 * @return Cached parameters.
 */
rp_calib_params_t calib_GetParams()
{
    return calib;
}

rp_calib_params_t calib_GetDefaultCalib(){
    return getDefaultCalib();
}

/**
 * @brief Read calibration parameters from EEPROM device.
 *
 * Function reads calibration parameters from EEPROM device and stores them to the
 * specified buffer. Communication to the EEPROM device is taken place through
 * appropriate system driver accessed through the file system device
 * /sys/bus/i2c/devices/0-0050/eeprom.
 *
 * @param[out]   calib_params  Pointer to destination buffer.
 * @retval       0 Success
 * @retval       >0 Failure
 *
 */
int calib_ReadParams(rp_calib_params_t *calib_params,bool use_factory_zone)
{
    FILE   *fp;
    size_t  size;

    /* sanity check */
    if(calib_params == NULL) {
        return 11; // Uninitialized Input Argument
    }

    /* open EEPROM device */
    fp = fopen(eeprom_device, "r");
    if(fp == NULL) {
        return 1; // Failed to Open EEPROM Device
    }

    /* ...and seek to the appropriate storage offset */
    int offset = use_factory_zone ? eeprom_calib_factory_off : eeprom_calib_off;
    if(fseek(fp, offset, SEEK_SET) < 0) {
        fclose(fp);
        return 12; // Failed to Find Calibration Parameters
    }

    /* read data from EEPROM component and store it to the specified buffer */
    size = fread(calib_params, sizeof(char), sizeof(rp_calib_params_t), fp);
    if(size != sizeof(rp_calib_params_t)) {
        fclose(fp);
        return 13; // Failed to Read Calibration Parameters
    }
    fclose(fp);

    return 0;
}


int calib_LoadFromFactoryZone(){
    rp_calib_params_t calib_values;
    int ret_val = calib_ReadParams(&calib_values,true);
    if (ret_val != 0)
        return ret_val;

    ret_val = calib_WriteParams(calib_values,false);
    if (ret_val != 0)
        return ret_val;

    return calib_Init();
}

int calib_WriteParams(rp_calib_params_t calib_params,bool use_factory_zone) {
    FILE   *fp;
    size_t  size;

    /* open EEPROM device */
    fp = fopen(eeprom_device, "w+");
    if(fp == NULL) {
        return 1; // Failed to Open EEPROM Device
    }

    /* ...and seek to the appropriate storage offset */
    int offset = use_factory_zone ? eeprom_calib_factory_off : eeprom_calib_off;
    if(fseek(fp, offset, SEEK_SET) < 0) {
        fclose(fp);
        return 12; // Failed to Find Calibration Parameters
    }

    /* write data to EEPROM component */
    size = fwrite(&calib_params, sizeof(char), sizeof(rp_calib_params_t), fp);
    if(size != sizeof(rp_calib_params_t)) {
        fclose(fp);
        return 13; // Failed to Read Calibration Parameters
    }
    fclose(fp);

    return 0; // Success
}

int calib_SetParams(rp_calib_params_t calib_params){
    calib = calib_params;
    return 0; // Success
}

rp_calib_params_t getDefaultCalib(){
    rp_calib_params_t calib;
		calib.id[0] = 'D';
		calib.id[1] = 'A';
		calib.id[2] = 'Q';
		calib.id[3] = '\0'; 		
		calib.version = CALIB_VERSION;
		calib.set_flags = 0;
		calib.dac_ch1_offs = 0.0;
		calib.dac_ch1_fs = 1.0;
		calib.dac_ch2_offs = 0.0;
		calib.dac_ch2_fs = 1.0;
		calib.adc_ch1_fs = 1.0/8192.0;
		calib.adc_ch1_offs = 0.0;
		calib.adc_ch2_fs = 1.0/8192.0;
		calib.adc_ch2_offs = 0.0;
    return calib;
}

int calib_validate(rp_calib_params_t * calib_params) {
	rp_calib_params_t def = getDefaultCalib();
	// If unknown EEPROM data or not set, we use default values
	bool useDefault = (strncmp(def.id, calib_params->id, 4) != 0 || calib_params->version != CALIB_VERSION);
	// Update Header
	if (useDefault) {
		strncpy(calib_params->id, def.id, 4);
		calib_params->version = CALIB_VERSION;
	}
	
	// ADC Calibration
	if (useDefault || !(calib_params->set_flags & (1 << 0))) {
		calib_params->adc_ch1_fs = def.adc_ch1_fs;
		calib_params->set_flags &= ~(1 << 0);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 1))) {
		calib_params->adc_ch1_offs = def.adc_ch1_offs;
		calib_params->set_flags &= ~(1 << 1);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 2))) {
		calib_params->adc_ch2_fs = def.adc_ch2_fs;
		calib_params->set_flags &= ~(1 << 2);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 3))) {
		calib_params->adc_ch2_offs = def.adc_ch2_offs;
		calib_params->set_flags &= ~(1 << 3);
	}

	// DAC Calibration
	if (useDefault || !(calib_params->set_flags & (1 << 4))) {
		calib_params->dac_ch1_fs = def.dac_ch1_fs;
		calib_params->set_flags &= ~(1 << 4);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 5))) {
		calib_params->dac_ch1_offs = def.dac_ch1_offs;
		calib_params->set_flags &= ~(1 << 5);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 6))) {
		calib_params->dac_ch2_fs = def.dac_ch2_fs;
		calib_params->set_flags &= ~(1 << 6);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 7))) {
		calib_params->dac_ch2_offs = def.dac_ch2_offs;
		calib_params->set_flags &= ~(1 << 7);
	}
	return 0;
}

int calib_apply() {
	setCalibDACScale(calib.dac_ch1_fs, 0);
	setCalibDACOffset(calib.dac_ch1_offs, 0);
	setCalibDACScale(calib.dac_ch2_fs, 1);
	setCalibDACOffset(calib.dac_ch2_offs, 1);
	return 0;
}

int calib_setADCOffset(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return -3;
	}
	if (channel == 0) {
		calib_params->adc_ch1_offs = value;
		calib_params->set_flags |= (1 << 1);
	}
	else if (channel == 1) {
		calib_params->adc_ch2_offs = value;
		calib_params->set_flags |= (1 << 3);
	}
	return 0;
}

int calib_setADCScale(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return -3;
	}
	if (channel == 0) {
		calib_params->adc_ch1_fs = value;
		calib_params->set_flags |= (1 << 0);
	}
	else if (channel == 1) {
		calib_params->adc_ch2_fs = value;
		calib_params->set_flags |= (1 << 2);
	}
	return 0;
}

int calib_setDACOffset(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return -3;
	}
	if (channel == 0) {
		calib_params->dac_ch1_offs = value;
		calib_params->set_flags |= (1 << 5);
	}
	else if (channel == 1) {
		calib_params->dac_ch2_offs = value;
		calib_params->set_flags |= (1 << 7);
	}
	return 0;
}

int calib_setDACScale(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return -3;
	}
	if (channel == 0) {
		calib_params->dac_ch1_fs = value;
		calib_params->set_flags |= (1 << 4);
	}
	else if (channel == 1) {
		calib_params->dac_ch2_fs = value;
		calib_params->set_flags |= (1 << 6);
	}
	return 0;
}


void calib_SetToZero() {
    calib = getDefaultCalib();
}

// From https://github.com/RedPitaya/RedPitaya/blob/e7f4f6b161a9cbbbb3f661228a6e8c5b8f34f661/api/src/common.c#L172
/**
* @brief Converts scale voltage to calibration Full scale. Result is usually written to EPROM calibration parameters.
*
* @param[in] voltageScale Scale value in voltage
* @retval Scale in volts
*/
uint32_t cmn_CalibFullScaleFromVoltage(float voltageScale) {
    return (uint32_t) (voltageScale / 100.0 * ((uint64_t)1<<32));
}
