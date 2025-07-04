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
void *pdm_sts, *reset_sts, *cfg, *ram, *dio_sts;
uint32_t *counter_trigger_cfg;
uint32_t *counter_trigger_sts;
uint16_t *pdm_cfg;
uint64_t *adc_sts, *dac_cfg;
uint32_t *awg_0_cfg, *awg_1_cfg;
uint32_t *version_sts;
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

double getCalibDACOffset(int channel) {
	if (channel == 0) 
		return calib.dac_ch1_offs;
	else if (channel == 1)
		return calib.dac_ch1_offs;
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


uint32_t getFPGAImageVersion() {
	return *version_sts;
}

uint32_t getServerVersion() {
	return 11;
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
			printf("Bitstream loaded\n");
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
	pdm_cfg = mmap(NULL, 8*sizeof(uint16_t)*PDM_BUFF_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x80000000);
	pdm_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40003000);
	reset_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40005000);
	dio_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40006000);
	counter_trigger_cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40008000);
	counter_trigger_sts = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40007000);
	cfg = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40004000);
	ram = mmap(NULL, sizeof(int32_t)*ADC_BUFF_SIZE, PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, ADC_BUFF_MEM_ADDRESS);
	xadc = mmap(NULL, 16*sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40010000);
	awg_0_cfg = mmap(NULL, AWG_BUFF_SIZE*sizeof(uint32_t)/2, PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x80020000);
	awg_1_cfg = mmap(NULL, AWG_BUFF_SIZE*sizeof(uint32_t)/2, PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x80028000);
	version_sts  = mmap(NULL, sysconf(_SC_PAGESIZE), PROT_READ|PROT_WRITE, MAP_SHARED, mmapfd, 0x40009000);


	
	loadBitstream();
	printf("FPGA Image Version %u\n", getFPGAImageVersion());
	printf("Server Version %u\n", getServerVersion());

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
	getFIREnabled(ON);
	setMasterTrigger(OFF);
	setInstantResetMode(OFF);
	setCounterSamplesPerStep(0);

	stopTx();

	setPhase(0, 0, 0);
	setPhase(0, 0, 1);
	setPhase(0, 0, 2);
	setPhase(0, 0, 3);
	setPhase(0, 1, 0);
	setPhase(0, 1, 1);
	setPhase(0, 1, 2);
	setPhase(0, 1, 3);

	setOffset(0, 0);
	setOffset(0, 1);

	return 0;
}

// fast DAC

uint16_t getAmplitude(int channel, int component) {
	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 3) {
		return INVALID_COMPONENT;
	}

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + AMPLITUDE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel);
	uint16_t amplitude = (uint16_t)(register_value >> 48);
	return amplitude;
}

int setAmplitudeVolt(double amplitude, int channel, int component) {

	double scaledAmplitude = amplitude*DAC_BASESCALE*getCalibDACScale(channel, false)*2.0; // The factor of two is corrected in the FPGA, but allows more discrete amplitude values
	if (scaledAmplitude < 0 || scaledAmplitude > 2.0*DAC_BASESCALE){
		return INVALID_VALUE;
	}
	return setAmplitude((uint16_t)(scaledAmplitude), channel, component);
}

int setAmplitude(uint16_t amplitude, int channel, int component) {

	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 3) {
		return INVALID_COMPONENT;
	}

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + AMPLITUDE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((uint64_t) amplitude) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + AMPLITUDE_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET*channel) = register_value;

	return 0;
}

int16_t getOffset(int channel) {
	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	uint64_t register_value = *(dac_cfg + CHANNEL_OFFSET*channel);
	int16_t offset = (int16_t)(register_value >> 48);

	return offset;
}

int setOffsetVolt(double offset, int channel) {

	double scaledOffset = offset*DAC_BASESCALE*getCalibDACScale(channel,false);
	if (scaledOffset < -DAC_BASESCALE || scaledOffset > DAC_BASESCALE){
		return INVALID_VALUE;
	}
	return setOffset((int16_t)scaledOffset, channel);
}

int setOffset(int16_t offset, int channel) {

	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	uint64_t register_value = *(dac_cfg + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) offset) << 48) & ~MASK_LOWER_48);

	*(dac_cfg + CHANNEL_OFFSET*channel) = register_value;

	return 0;
}

double getFrequency(int channel, int component) {
	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 3) {
		return INVALID_COMPONENT;
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
		return INVALID_VALUE;
	}

	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 3) {
		return INVALID_COMPONENT;
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
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 3) {
		return INVALID_COMPONENT;
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
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 3) {
		return INVALID_COMPONENT;
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
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 2) {
		return INVALID_COMPONENT;
	}

	if((signal_type != SIGNAL_TYPE_SINE)
			&& (signal_type != SIGNAL_TYPE_SQUARE)
			&& (signal_type != SIGNAL_TYPE_TRIANGLE)
			&& (signal_type != SIGNAL_TYPE_SAWTOOTH)) {
		return INVALID_VALUE;
	}
	
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel);
	uint64_t mask = 0x000000000000ffff;
	register_value = (register_value & ~mask) | (signal_type & mask);
	*(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel) = register_value;

	return 0;
}

int getSignalType(int channel, int component) {
	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	if(component < 0 || component > 2) {
		return INVALID_COMPONENT;
	}

	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + COMPONENT_OFFSET*component + CHANNEL_OFFSET * channel);
	uint64_t mask = 0x000000000000ffff;
	int value = (int) (register_value & mask);
	return value;
}

int setCalibDACScale(float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	int16_t scale = (int16_t)(value*8191.0);
	if (scale < -8191 || scale >= 8192) {
		return INVALID_VALUE;
	}
	// Config scale is stored in first component freq
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) scale) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}

int setCalibDACOffset(float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	float scaledValue = value*DAC_BASESCALE*getCalibDACScale(channel,false);

	if (scaledValue < -DAC_BASESCALE || scaledValue > DAC_BASESCALE){
		return INVALID_VALUE;
	}

	int16_t offset = (int16_t)scaledValue;

	// Config offset is stored in first component phase
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) offset) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*0 + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}

int setCalibDACLowerLimit(float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}
	
	float scaledValue = (value+getCalibDACOffset(channel))*DAC_BASESCALE*getCalibDACScale(channel,false) ; //todo check if + or -

	if (scaledValue < -DAC_BASESCALE){
		scaledValue = -DAC_BASESCALE;
	}
	else if (scaledValue>DAC_BASESCALE){
		scaledValue = DAC_BASESCALE;
	}
	
	
	int16_t limit = (int16_t)scaledValue;
	
	// Config lower limit is stored in second component freq
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*1 + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) limit) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + FREQ_OFFSET + COMPONENT_OFFSET*1 + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}


int setCalibDACUpperLimit(float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}
	
	float scaledValue = (value+getCalibDACOffset(channel))*DAC_BASESCALE*getCalibDACScale(channel,false); //todo check if + or -

	if (scaledValue < -DAC_BASESCALE){
		scaledValue = -DAC_BASESCALE;
	}
	else if (scaledValue>DAC_BASESCALE){
		scaledValue = DAC_BASESCALE;
	}
	
	int16_t limit = (int16_t)scaledValue;

	// Config upper limit is stored in second component phase
	uint64_t register_value = *(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*1 + CHANNEL_OFFSET*channel);
	register_value = (register_value & MASK_LOWER_48) | ((((int64_t) limit) << 48) & ~MASK_LOWER_48);
	*(dac_cfg + COMPONENT_START_OFFSET + PHASE_OFFSET + COMPONENT_OFFSET*1 + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}

int setArbitraryWaveform(float* values, int channel) {
	uint32_t *awg_cfg = NULL;
	float calib_scale = 0.0;
	if (channel == 0) {
		awg_cfg = awg_0_cfg;
		calib_scale = calib.dac_ch1_fs;
	}
	else if (channel == 1) {
		awg_cfg = awg_1_cfg;
		calib_scale = calib.dac_ch1_fs;
	}
	else {
		return INVALID_CHANNEL;
	}

	int16_t intValues[AWG_BUFF_SIZE];
	// First prepare and check values
	for (int i = 0; i< AWG_BUFF_SIZE; i++) {
		float scaledValue = values[i]*DAC_BASESCALE*calib_scale;
		if (scaledValue < -DAC_BASESCALE || scaledValue > DAC_BASESCALE) {
			return INVALID_VALUE;
		}
		intValues[i] = (int16_t)scaledValue;
	}

	for (int i = 0; i < AWG_BUFF_SIZE/2; i++) {
		// Without cast to uint the sign is mistakenly taken into account
		uint32_t bram_value = ((uint16_t) intValues[2*i+1] << 16 | (uint16_t)intValues[2*i]);
		*(awg_cfg + i) = bram_value;
	}
	return 0;
}


// Fast ADC

int setDecimation(uint16_t decimation) {
	if(!(decimation % 2 == 0)) {
		return INVALID_VALUE;
	}

	if(decimation < 8 || decimation > 8192) {
		return INVALID_VALUE;
	}
    
	uint16_t internalDecimation;
	if(getFIREnabled()) {
		// FIR Compensation filter also decimates by 2
		internalDecimation = decimation/2;
	} else {
        	internalDecimation = decimation;
	}
	
	*((uint16_t *)(cfg + 2)) = internalDecimation;
	return 0;
}

uint16_t getDecimation() {
	uint16_t value = *((uint16_t *)(cfg + 2));
	if(getFIREnabled()) {
		// FIR Compensation filter also decimates by 2
		return value*2;
	} else {
        	return value;
	}	
}

#define BIT_MASK(__TYPE__, __ONE_COUNT__) \
	((__TYPE__) (-((__ONE_COUNT__) != 0))) \
	& (((__TYPE__) -1) >> ((sizeof(__TYPE__) * CHAR_BIT) - (__ONE_COUNT__)))

uint32_t getWritePointer() {
	uint32_t val = getTotalWritePointer();
	uint32_t mask = BIT_MASK(uint64_t, ADC_BUFF_NUM_BITS); // Extract lower bits
	return val&mask;
}

uint32_t getInternalWritePointer(uint64_t wp) {
	uint32_t mask = BIT_MASK(uint64_t, ADC_BUFF_NUM_BITS+1); // Extract lower bits
	return wp&mask;
}

uint32_t getInternalPointerOverflows(uint64_t wp) {
	return wp >> (ADC_BUFF_NUM_BITS + 1);
}

uint32_t getWritePointerOverflows() {
	return getTotalWritePointer() >> ADC_BUFF_NUM_BITS; // Extract upper bits
}

uint64_t getTotalWritePointer() {
	return *adc_sts;
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
		return INVALID_VALUE;
	}

	if(channel < 0 || channel >= 6) {
		return INVALID_CHANNEL;
	}

	int bitpos = channel;
	int offset = 8 * index + 6;
	// The enable bits are in the 6-th slowDAC channel
	// clear the bit
	*((int16_t *)(pdm_cfg + offset)) &= ~(1u << bitpos);
	// set the bit
	*((int16_t *)(pdm_cfg + offset)) |= (value << bitpos);

	return 0;
}

int setResyncDACAll(int8_t value, int channel) {
	for(int i=0; i<PDM_BUFF_SIZE; i++) {
		setResyncDAC(value,channel,i);
	}
	return 0;
}

int setResyncDAC(int8_t value, int channel, int index) {
	if(channel < 0 || channel >= 2) {
		return INVALID_CHANNEL;
	}

	if (value < 0 || value >= 2)
		return INVALID_VALUE;

	int bitpos = 14;
	// Reset bits are in the 14th bit of the respective DAC channel -> 14 and 30
	int offset = 8 * index + channel;
	// clear the bit
	*((int16_t *)(pdm_cfg + offset)) &= ~(1u << bitpos);
	// set the bit
	*((int16_t *)(pdm_cfg + offset)) |= (value << bitpos);
	//printf("%d reset pdm\n", *((int16_t *)(pdm_cfg + 2*(0+4*index))));
	return 0;
}

int setResetDAC(int8_t value, int index) {
	if (value < 0 || value >= 2)
		return INVALID_VALUE;

	int bitpos = 14;
	// Reset bit is in the 1-th channel
	// clear the bit
	*((int16_t *)(pdm_cfg + 2*(0+4*index))) &= ~(1u << bitpos);
	// set the bit
	*((int16_t *)(pdm_cfg + 2*(0+4*index))) |= (value << bitpos);
	//printf("%d reset pdm\n", *((int16_t *)(pdm_cfg + 2*(0+4*index))));
	return 0;
}

int getRampDownDAC(int channel, int index) {
	if(channel < 0 || channel > 1) {
		return false;
	}
	int bitpos = 14 + channel * 1; // 14 or 15
	return (*((int16_t *)(pdm_cfg + 2*(2+4*index))) >> bitpos) & 1;
}

int setRampDownDACAll(int8_t value, int channel) {
	for(int i=0; i<PDM_BUFF_SIZE; i++) {
		setRampDownDAC(value,channel,i);
	}
	return 0;
}

int setRampDownDAC(int8_t value, int channel, int index) {
	if(value < 0 || value >= 2) {
		return INVALID_VALUE;
	}

	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	int bitpos = channel; // 0 or 1
	// Ramp Down bit is in the 7th channel
	// clear the bit
	int offset = 8 * index + 7;
	*((int16_t *)(pdm_cfg + offset)) &= ~(1u << bitpos);
	// set the bit
	*((int16_t *)(pdm_cfg + offset)) |= (value << bitpos);
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

	if(channel < 0 || channel >= 6) {
		return INVALID_CHANNEL;
	}

	//printf("%p   %p   %d \n", (void*)pdm_cfg, (void*)((uint16_t *)(pdm_cfg+2*(channel+4*index))), 2*(channel+4*index) );
	int offset = 8 * index + channel;
	//int16_t temp = *((int16_t *)(pdm_cfg + offset)); 
	*((int16_t *)(pdm_cfg + offset)) = value;
	
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

	if(channel >= 2 ) {
		if (voltage > 1.8) voltage = 1.8;
		if (voltage < 0) voltage = 0;
		val = (voltage / 1.8) * 2038.; // todo: check if number is correct? does is matter?
	} else {
		float scaledVoltage = voltage*DAC_BASESCALE*getCalibDACScale(channel,false)/4.0; // the division by 4 is corrected in the FPGA but is necessary to fit the PDM values into 14 bit to not collide with resync bit
		// clip values to stay within 14-bit signed
		if (scaledVoltage > 8191) scaledVoltage = 8191.0;
		if (scaledVoltage < -8191) scaledVoltage = -8191.0;
		val = (int16_t)scaledVoltage;
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

int getSamplesPerStep() {
	int32_t value = *((int32_t *)(cfg + 4));
	return value/getDecimation();
}

int setSamplesPerStep(int samples) {
	*((int32_t *)(cfg + 4)) = samples*getDecimation();
	return 0;
}

int getCounterSamplesPerStep()  {
	int32_t value = *((int32_t *)(cfg + 12));
	return value/getDecimation();
}

int setCounterSamplesPerStep(int samples)  {
	*((int32_t *)(cfg + 12)) = samples*getDecimation();
	return 0;
}

uint64_t getPDMRegisterValue() {
	uint64_t value = *((uint64_t *)(pdm_cfg));
	return value;
}

uint32_t getPDMTotalWritePointer() {
	uint32_t value = *((uint32_t *)(pdm_sts));
	return value;
}

uint32_t getPDMWritePointer() {
	uint32_t value = getPDMTotalWritePointer();
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
		return INVALID_CHANNEL;
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

	return INVALID_VALUE;
}

int setWatchdogMode(int mode) {
	if(mode == OFF) {
		*((uint8_t *)(cfg + 1)) &= ~2;
	} else if(mode == ON) {
		*((uint8_t *)(cfg + 1)) |= 2;
	} else {
		return INVALID_VALUE;
	}

	return 0;
}

int getFIREnabled() {
	int value = (((int)(*((uint8_t *)(cfg + 1))) & 0x40) );

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}

	return -1;
}

int setFIREnabled(int mode) {
	if(mode == OFF) {
		*((uint8_t *)(cfg + 1)) &= ~128;
	} else if(mode == ON) {
		*((uint8_t *)(cfg + 1)) |= 128;
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

	return INVALID_VALUE;
}

int setRAMWriterMode(int mode) {
	if(mode == ADC_MODE_CONTINUOUS) {
		*((uint8_t *)(cfg + 1)) &= ~1;
	} else if(mode == ADC_MODE_TRIGGERED) {
		*((uint8_t *)(cfg + 1)) |= 1;
	} else {
		return INVALID_VALUE;
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

	return INVALID_VALUE;
}

int setTriggerMode(int mode) {
	if(mode == TRIGGER_MODE_INTERNAL) {
		*((uint8_t *)(cfg + 1)) &= ~16;
	} else if(mode == TRIGGER_MODE_EXTERNAL) {
		*((uint8_t *)(cfg + 1)) |= 16;
	} else {
		return INVALID_VALUE;
	}

	return 0;
}

int getTriggerPropagation() {
	int value = (((int)(*((uint8_t *)(cfg + 1))) & 0x04) >> 2);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}

	return INVALID_VALUE;
}

int setTriggerPropagation(int mode) {
	if(mode == OFF) {
		*((uint8_t *)(cfg + 1)) &= ~4;
	} else if(mode == ON) {
		*((uint8_t *)(cfg + 1)) |= 4;
	} else {
		return INVALID_VALUE;
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

	return INVALID_VALUE;
}

int setMasterTrigger(int mode) {
	if(mode == OFF) {
		setKeepAliveReset(ON);
		//double waitTime = getSamplesPerStep() * getDecimation() / 125e6;
		//usleep( 10*waitTime * 1000000);
		*((uint8_t *)(cfg + 1)) &= ~(1 << 5);
		//usleep( 10*waitTime * 1000000);
		setRAMWriterMode(ADC_MODE_TRIGGERED);
		setKeepAliveReset(OFF);
	} else if(mode == ON) {
			*((uint8_t *)(cfg + 1)) |= (1 << 5);
	} else {
		return INVALID_VALUE;
	}

	return 0;
}

// RAMPING
int getEnableRamping(int channel) {
	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}

	int value = (int)((*((uint8_t *)(cfg + 10)) >> channel) & 1);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}
	return INVALID_VALUE;
}

int setEnableRamping(int mode, int channel) {
	if (mode != OFF && mode != ON) {
		return INVALID_VALUE;
	}

	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
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
		return INVALID_VALUE;
	}

	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
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
		return INVALID_CHANNEL;
	}

	int value = (int)((*((uint8_t *)(cfg + 10)) >> (channel + 2)) & 1);

	if(value == 0) {
		return OFF;
	} else if(value == 1) {
		return ON;
	}
	return INVALID_VALUE;	
}

int setRampingFrequency(double period, int channel) {
	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}
	
	if(period < 0.03 || period >= ((double)BASE_FREQUENCY)) {
		return INVALID_VALUE;
	}

	uint64_t phase_increment = (uint64_t)round(period*pow(2, 48)/((double)BASE_FREQUENCY));

	uint64_t register_value = *(dac_cfg + CHANNEL_OFFSET*channel);
	register_value = (register_value & ~MASK_LOWER_48) | (phase_increment & MASK_LOWER_48);
	*(dac_cfg + CHANNEL_OFFSET*channel) = register_value;
	return 0;
}

double getRampingFrequency(int channel) {
	if(channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
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

	return INVALID_VALUE;
}

int setInstantResetMode(int mode) {
	if(mode == OFF) {
		*((uint8_t *)(cfg + 1)) &= ~8;
	} else if(mode == ON) {
		*((uint8_t *)(cfg + 1)) |= 8;
	} else {
		return INVALID_VALUE;
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

	return INVALID_VALUE;
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
		return INVALID_VALUE;
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

char* getPinFromInternalPINNumber(const uint32_t pinNumber) {
	if(pinNumber == 0) {
		return "DIO7_P";
	} else if(pinNumber == 1) {
		return "DIO7_N";
	} else if(pinNumber == 2) {
		return "DIO6_P";
	} else if(pinNumber == 3) {
		return "DIO6_N";
	} else if(pinNumber == 4) {
		return "DIO5_N";
	} else if(pinNumber == 5) {
		return "DIO4_N";
	} else if(pinNumber == 6) {
		return "DIO3_N";
	} else if(pinNumber == 7) {
		return "DIO2_N";
	} else {
		return "ERR";
	}
}

int getDIOHBridge(const char* pin) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return INVALID_CHANNEL;
	}

	uint32_t register_value = *((uint8_t *)(cfg + 11));
	register_value = ((register_value & (0x1 << (pinInternal))) >> (pinInternal));

	return register_value;
}

int setDIOHBridge(const char* pin, int value) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return INVALID_CHANNEL;
	}

	if(value == DIO_OUT) {
		*((uint8_t *)(cfg + 11)) &= ~(0x1 << (pinInternal));
	} else if(value == DIO_IN) {
		*((uint8_t *)(cfg + 11)) |= (0x1 << (pinInternal));
	} else {
		return INVALID_VALUE;
	}

	return 0;
}


int getDIODirection(const char* pin) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return INVALID_CHANNEL;
	}

	uint32_t register_value = *((uint8_t *)(cfg + 9));
	register_value = ((register_value & (0x1 << (pinInternal))) >> (pinInternal));
	
	if(register_value == DIO_IN) {
		return DIO_IN;
	} else {
		return DIO_OUT;
	}
}

int setDIODirection(const char* pin, int value) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return INVALID_CHANNEL;
	}

	if(value == DIO_OUT) {
		*((uint8_t *)(cfg + 9)) &= ~(0x1 << (pinInternal));
	} else if(value == DIO_IN) {
		*((uint8_t *)(cfg + 9)) |= (0x1 << (pinInternal));
	} else {
		return INVALID_VALUE;
	}

	return 0;
}

int setDIO(const char* pin, int value) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return INVALID_CHANNEL;
	}

	if(value == OFF) {
		*((uint8_t *)(cfg + 8)) &= ~(0x1 << (pinInternal));
	} else if(value == ON) {
		*((uint8_t *)(cfg + 8)) |= (0x1 << (pinInternal));
	} else {
		return INVALID_VALUE;
	}

	return 0;
}

int getDIO(const char* pin) {
	int pinInternal = getInternalPINNumber(pin);
	if(pinInternal < 0) {
		return INVALID_CHANNEL;
	}

	uint32_t register_value = *((uint8_t *)(dio_sts));
	return ((register_value & (0x1 << (pinInternal))) >> (pinInternal));
}

void stopTx() {
	// Stop Fast
	setAmplitude(0, 0, 0);
	setAmplitude(0, 0, 1);
	setAmplitude(0, 0, 2);
	setAmplitude(0, 0, 3);
	setAmplitude(0, 1, 0);
	setAmplitude(0, 1, 1);
	setAmplitude(0, 1, 2);
	setAmplitude(0, 1, 3);

	// Stop AWG
	float reset[AWG_BUFF_SIZE];
	memset(reset, 0, AWG_BUFF_SIZE*sizeof(float));
	setArbitraryWaveform(reset, 0);
	setArbitraryWaveform(reset, 1);

	// Stop Sequence
	for(int d=0; d<5; d++) {
		setPDMAllValuesVolt(0.0, d);
		setEnableDACAll(1,d);
		setResyncDACAll(0,d);
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
int calib_ReadParams(rp_calib_params_t *calib_params, bool use_factory_zone)
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
		calib.adc_ch1_fs = 1.0/32768.0;
		calib.adc_ch1_offs = 0.0;
		calib.adc_ch2_fs = 1.0/32768.0;
		calib.adc_ch2_offs = 0.0;
		calib.dac_ch1_lower = -1.0;
		calib.dac_ch1_upper = 1.0;
		calib.dac_ch2_lower = -1.0;
		calib.dac_ch2_upper = 1.0;
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

	// DAC Limits
	if (useDefault || !(calib_params->set_flags & (1 << 8))) {
		calib_params->dac_ch1_lower = def.dac_ch1_lower;
		calib_params->set_flags &= ~(1 << 8);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 9))) {
		calib_params->dac_ch1_upper = def.dac_ch1_upper;
		calib_params->set_flags &= ~(1 << 9);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 10))) {
		calib_params->dac_ch2_lower = def.dac_ch2_lower;
		calib_params->set_flags &= ~(1 << 10);
	}
	if (useDefault || !(calib_params->set_flags & (1 << 11))) {
		calib_params->dac_ch2_upper = def.dac_ch2_upper;
		calib_params->set_flags &= ~(1 << 11);
	}

	return 0;
}

int calib_apply() {
	setCalibDACScale(1.0, 0);
	setCalibDACOffset(calib.dac_ch1_offs, 0);
	setCalibDACLowerLimit(calib.dac_ch1_lower, 0);
	setCalibDACUpperLimit(calib.dac_ch1_upper, 0);
	setCalibDACScale(1.0, 1);
	setCalibDACOffset(calib.dac_ch2_offs, 1);
	setCalibDACLowerLimit(calib.dac_ch2_lower, 1);
	setCalibDACUpperLimit(calib.dac_ch2_upper, 1);

	// set every output to zero to avoid values written to the registers with old scale factors
	stopTx();
	setOffset(0, 0);
	setOffset(0, 1);
	
	return 0;
}

int calib_setADCOffset(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
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
		return INVALID_CHANNEL;
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
		return INVALID_CHANNEL;
	}
	if (channel == 0) {
		if(value*calib_params->dac_ch1_fs < -1.0 || value*calib_params->dac_ch1_fs > 1.0){
			return INVALID_VALUE;
		}
		calib_params->dac_ch1_offs = value;
		calib_params->set_flags |= (1 << 5);
	}
	else if (channel == 1) {
		if(value*calib_params->dac_ch2_fs < -1.0 || value*calib_params->dac_ch2_fs > 1.0){
			return INVALID_VALUE;
		}
		calib_params->dac_ch2_offs = value;
		calib_params->set_flags |= (1 << 7);
	}
	return 0;
}

int calib_setDACScale(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
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

int calib_setDACLowerLimit(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}
	if (channel == 0) {
		calib_params->dac_ch1_lower = value;
		calib_params->set_flags |= (1 << 8);
	}
	else if (channel == 1) {
		calib_params->dac_ch2_lower = value;
		calib_params->set_flags |= (1 << 10);
	}
	return 0;
}

int calib_setDACUpperLimit(rp_calib_params_t * calib_params, float value, int channel) {
	if (channel < 0 || channel > 1) {
		return INVALID_CHANNEL;
	}
	if (channel == 0) {
		calib_params->dac_ch1_upper = value;
		calib_params->set_flags |= (1 << 9);
	}
	else if (channel == 1) {
		calib_params->dac_ch2_upper = value;
		calib_params->set_flags |= (1 << 11);
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

/**
 * Memory layout for `counter_trigger_cfg` upper bits 0x40008000
 * 
 * 0 ................................................................................................................. 67 bit |
 * reference_counter (32 bit) | presamples (32 bit) | enable (1 bit) | arm (1 bit) | reset (1 bit) | source selection (5 bit) |
 * 
 * Memory layout for `counter_trigger_sts` lower bits 0x40007000
 * 
 * 0 ............................ 33 bit |
 * last_counter (32 bit) | armed (1 bit) |
 **/

int counter_trigger_setEnabled(bool enable) {
	if (!enable) {
		counter_trigger_disarm(); // Always disarm when disabling
	}

	uint32_t register_value = *(counter_trigger_cfg + 2);
	if (enable) {
		register_value = register_value | (1 << 0);
	}
	else {
		register_value = register_value & ~(1 << 0);
	}
	
	*(counter_trigger_cfg + 2) = register_value;
	return 0;
}

bool counter_trigger_isEnabled() {
	uint32_t register_value = *(counter_trigger_cfg + 2);
	register_value = register_value & (1 << 0);
	return (register_value > 0);
}

int counter_trigger_setPresamples(uint32_t presamples) {
	*(counter_trigger_cfg + 1) = presamples;
	return 0;
}

int counter_trigger_getPresamples() {
	return *(counter_trigger_cfg + 1);
}

int counter_trigger_arm() {
	uint32_t register_value = *(counter_trigger_cfg + 2);
	register_value = register_value | (1 << 1);
	*(counter_trigger_cfg + 2) = register_value;
	return 0;
}

int counter_trigger_disarm() {
	uint32_t register_value = *(counter_trigger_cfg + 2);
	register_value = register_value & ~(1 << 1);
	*(counter_trigger_cfg + 2) = register_value;
	return 0;
}

bool counter_trigger_isArmed() {
	uint32_t register_value = *(counter_trigger_sts + 1);
	register_value = register_value & (1 << 0);
	return (register_value > 0);
}

int counter_trigger_setReset(bool reset) {
	if (reset) {
		counter_trigger_disarm(); // Always disarm when resetting
	}

	uint32_t register_value = *(counter_trigger_cfg + 2);
	if (reset) {
		register_value = register_value | (1 << 2);
	}
	else {
		register_value = register_value & ~(1 << 2);
	}
	
	*(counter_trigger_cfg + 2) = register_value;
	return 0;
}

bool counter_trigger_getReset() {
	uint32_t register_value = *(counter_trigger_cfg + 2);
	register_value = register_value & (1 << 2);
	return (register_value > 0);
}

uint32_t counter_trigger_getLastCounter() {
	return *(counter_trigger_sts + 0);
}

int counter_trigger_setReferenceCounter(uint32_t reference_counter) {
	*(counter_trigger_cfg + 0) = reference_counter;
	return 0;
}

uint32_t counter_trigger_getReferenceCounter() {
	return *(counter_trigger_cfg + 0);
}

uint32_t counter_trigger_getSelectedChannelType() {
	uint32_t register_value = *(counter_trigger_cfg + 2);
	return (register_value & (1 << 7)) >> 7;
}

bool counter_trigger_setSelectedChannelType(uint32_t channelType) {
	uint32_t register_value = *(counter_trigger_cfg + 2);
	if (channelType == COUNTER_TRIGGER_ADC)
	{
		*(counter_trigger_cfg + 2) = register_value | (1 << 7);
	}
	else if (channelType == COUNTER_TRIGGER_DIO)
	{
		*(counter_trigger_cfg + 2) = register_value & ~(1 << 7);
	}
	else
	{
		return INVALID_VALUE;
	}

	return 0;
}

char* counter_trigger_getSelectedChannel() {
	uint32_t register_value = *(counter_trigger_cfg + 2);
	uint32_t channelNumber = (register_value & (0b1111 << 3)) >> 3;
	if (counter_trigger_getSelectedChannelType() == COUNTER_TRIGGER_DIO) {
		return getPinFromInternalPINNumber(channelNumber);
	} else { // ADC
		if (channelNumber == 0) {
			return "IN1";
		} else if (channelNumber == 1) {
			return "IN2";
		} else {
			return "ERR";
		}
	}
}

uint32_t counter_trigger_setSelectedChannel(const char* channel) {
	int32_t channelNumber;
	if (counter_trigger_getSelectedChannelType() == COUNTER_TRIGGER_DIO) {
		channelNumber = getInternalPINNumber(channel);
	} else { // ADC
		if (strncmp(channel, "IN1", 3) == 0) {
			channelNumber = 0;
		} else if (strncmp(channel, "IN2", 3) == 0) {
			channelNumber = 1;
		} else {
			channelNumber = -3;
		}
	}

	if (channelNumber < 0) {
		return channelNumber;
	}

	uint32_t register_value = *(counter_trigger_cfg + 2);
	*(counter_trigger_cfg + 2) = (register_value | (0b1111 << 3)) & ((channelNumber << 3) | ~(0b1111 << 3));
	return 0;
}
