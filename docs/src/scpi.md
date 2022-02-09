# SCPI Interface

For communication betten the server and the client an [SCPI](https://en.wikipedia.org/wiki/Standard_Commands_for_Programmable_Instruments) with custom commands is used. The following table gives an overview of availalbe commands:
## ADC Configuration

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:ADC:DECimation | decimation value [8, ..., n]| Set the decimation factor of the base sampling rate| C | RP:ADC:DEC 8 | 
| RP:ADC:DECimation? | | Return the decimation factor | Any | RP:ADC:DEC? |
| RP:TRIGger:MODe | trigger mode (EXTERNAL, INTERNAL) | Set the trigger mode, which trigger the RedPitaya listens to | C | RP:TRIG:MOD INTERNAL |
| RP:TRIGger:MODe? |  | Return the trigger mode | Any | RP:TRIG:MOD? |
|RP:CALib:ADC:CHannel#:OFFset | channel (0, 1), offset [0, ..., 1] | Store the ADC offset value for given channel in EEPROM  | C | RP:CAL:ADC:CH0:OFF 0.2 |
|RP:CALib:ADC:CHannel#:OFFset? | channel (0, 1) | Return the ADC offset value for given channel from EEPROM | Any | RP:CAL:ADC:CH1:OFF? |
|RP:CALib:ADC:CHannel#:SCAle | channel (0, 1), scale [0, ..., 1]| Store the ADC scale value for given channel in EEPROM | C | RP:CAL:ADC:CH1:SCA 1.0 |
|RP:CALib:ADC:CHannel#:SCAle? | channel (0, 1) | Return the ADC scale value for given channel from EEPROM | Any | RP:CAL:ADC:CH1:SCA? |

## DAC Configuration

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:DAC:CHannel#:SIGnaltype | channel (0, 1), signal type (SINE, SQUARE, TRIANGLE, SAWTOOTH) | Set signal type of first component for given channel | Any | RP:DAC:CH0:SIG SQUARE |
| RP:DAC:CHannel#:SIGnaltype? | channel (0, 1) | Return signal type of first component of given channel | Any | RP:DAC:CH1:SIG? |
| RP:DAC:CHannel#:JUMPsharpness | channel (0, 1) |  | Any | |
| RP:DAC:CHannel#:JUMPsharpness? | channel (0, 1) |  | Any | |
| RP:DAC:CHannel#:OFFset | channel (0, 1), offset [-1, ..., 1] | Set offset for given channel | Any | RP:DAC:CH1:OFF 0.1 |
| RP:DAC:CHannel#:OFFset? | channel (0, 1) | Return offset of given channel | Any | RP:DAC:CH0:OFF?  |
| RP:DAC:CHannel#:COMPonent#:AMPlitude | channel (0, 1), component (0, 1, 2, 3),  amplitude[0, ..., 1] | Set amplitude of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:AMPlitude? | channel (0, 1), component (0, 1, 2, 3) | Return amplitude of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:FREQuency | channel (0, 1), component (0, 1, 2, 3), frequency | Set frequency of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:FREQuency? | channel (0, 1), component (0, 1, 2, 3) | Return frequency of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:PHAse | channel (0, 1), component (0, 1, 2, 3), phase | Set phase of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:PHAse? | channel (0, 1), component (0, 1, 2, 3) | Return phase of given channel and component | Any | |

## Sequence Configuration
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| |  |  |  | |


## Acquisition and Transmission
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:TRIGger | trigger status (OFF, ON) | Set the internal trigger status | M | RP:TRIG ON |
| RP:TRIGger? |  | Return the trigger status | Any | RP:TRIG? |
| RP:TRIGger:ALiVe | keep alive status (OFF, ON) | Set the keep alive bypass | M | RP:TRIG:ALV OFF |
| RP:TRIGger:ALiVe? |  | Return the keep alive status | Any | RP:TRIG:ALV? |
| RP:ADC:WP:CURRent? |  | Return the current writepointer | M, T | RP:ADC:WP? |
| RP:ADC:DATa? | readpointer, number of samples | Transmit number of samples from the buffer component of the readpointer on | M | RP:ADC:DATa? 400,1024 |
| RP:ADC:DATa:PIPElined? | readpointer, number of samples, chunksize | Transmit number of samples from the readpointer on in chunks of chunksize. After every chunk status and performance data is transmitted. | M | RP:ADC:DAT:PIPE? 400,1024,128 |
| RP:STATus? |  | Transmit status as one byte with flags from lower bits: overwritten, corrupted, lost steps, master trigger, sequence active | Any | RP:STAT? |
| RP:STATus:OVERwritten? |  | Transmit overwritten flag | Any | RP:STAT:OVER? |
| RP:STATus:CORRupted? |  | Transmit corrupted flag | Any | RP:STAT:CORR? |
| RP:STATus:LOSTSteps? |  | Transmit lost steps flag | Any | RP:STAT:LOSTS? |
| RP:PERF? |  | Transmit ADC and DAC performance data | Any | RP:PERF? |


## DIO

| Command        | Arguments    | Description         | Example         |
| :-------------- | :---------------- | :------------------- | :------------------- |
| RP:DIO:DIR      | identifier of pin, direction (IN/OUT)  | Set the direction of the DIO      |  RP:DIO:DIR DIO7_P,IN  |
| RP:DIO      | identifier of pin, value (0/1)  | Set the output of the DIO      |  RP:DIO DIO7_P,1  |
| RP:DIO?      | identifier of pin  | Get the input of the DIO      |  RP:DIO? DIO7_P  |
