# SCPI Interface

For communication betten the server and the client an [SCPI](https://en.wikipedia.org/wiki/Standard_Commands_for_Programmable_Instruments) interface with custom commands is used. In the following tables an overview of the available commands and their behaviour is given. The Julia [Client](client.md) library encapsulates these commands into function calls, abstracting their communication details and also combining commands to manage a cluster of RedPitayas at the same time.

As a safe guard the server has different communcation modes and certain commands are only available in certain modes. To give an example, during an acquisition changing the sampling rate would result in unclear behaviour. To stop such a scenario the decimation can only be set in the `CONFIGURATION` mode and an acquisition can only be triggered in the `ACQUISITION` mode. The available modes are `CONFIGURATION`, `ACQUISITION` and `TRANSMISSION` (C, A, T, 😺). The former two are set by the client and the latter is set by the server during sample transmission.

After each SCPI command the server replies with `true` or `false` on the command socket depending on whether the given command was successfully excecuted. The exception to this rule are the commands which themselves just query values from the server.

## ADC Configuration

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:ADC:DECimation | decimation value [8, ..., n]| Set the decimation factor of the base sampling rate| C | RP:ADC:DEC 8 | 
| RP:ADC:DECimation? | | Return the decimation factor | Any | RP:ADC:DEC? |
| RP:TRIGger:MODe | trigger mode (EXTERNAL, INTERNAL) | Set the trigger mode, which trigger the RedPitaya listens to | C | RP:TRIG:MOD INTERNAL |
| RP:TRIGger:MODe? |  | Return the trigger mode | Any | RP:TRIG:MOD? |

## DAC Configuration

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:DAC:CHannel#:COMPonent#:SIGnaltype | channel (0, 1), (0, 1, 2, 3), signal type (SINE, TRIANGLE, SAWTOOTH) | Set signal type of first component for given channel | Any | RP:DAC:CH0:SIG SINE |
| RP:DAC:CHannel#:COMPonent#:SIGnaltype? | channel (0, 1), component (0, 1, 2, 3) | Return signal type of first component of given channel | Any | RP:DAC:CH1:SIG? |
| RP:DAC:CHannel#:OFFset | channel (0, 1), offset [-1, ..., 1] | Set offset for given channel | Any | RP:DAC:CH1:OFF 0.1 |
| RP:DAC:CHannel#:OFFset? | channel (0, 1) | Return offset of given channel | Any | RP:DAC:CH0:OFF?  |
| RP:DAC:CHannel#:COMPonent#:AMPlitude | channel (0, 1), component (0, 1, 2, 3),  amplitude[0, ..., 1] | Set amplitude of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:AMPlitude? | channel (0, 1), component (0, 1, 2, 3) | Return amplitude of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:FREQuency | channel (0, 1), component (0, 1, 2, 3), frequency | Set frequency of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:FREQuency? | channel (0, 1), component (0, 1, 2, 3) | Return frequency of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:PHAse | channel (0, 1), component (0, 1, 2, 3), phase | Set phase of given channel and component | Any | |
| RP:DAC:CHannel#:COMPonent#:PHAse? | channel (0, 1), component (0, 1, 2, 3) | Return phase of given channel and component | Any | |
| RP:DAC:CHannel#:RAMPing | channel (0, 1), ramping period | Set length of ramping period | C |  |
| RP:DAC:CHannel#:RAMPing? | channel (0, 1) | Get length of ramping period | Any | |
| RP:DAC:CHannel#:RAMPing:ENable | channel (0, 1) ramping status (OFF, ON)| Enable/disable ramping factor on given channel | C |  |
| RP:DAC:CHannel#:RAMPing:ENable? | channel (0, 1) | Return enable ramping status of given channel | Any |  |
| RP:DAC:CHannel#:RAMPing:DoWN | channel (0, 1), ramp down status (OFF, ON) | Enable/disable ramp down flag for given channel | A, T |  |
| RP:DAC:CHannel#:RAMPing:DoWN? | channel (0, 1) | Get ramp down flag for given channel | Any |  |
| RP:DAC:RAMPing:STATus? | | Return the ramping status | Any | |


## Sequence Configuration
The server maintains three acquisition sequences. When the server is in the`CONFIGURATION` mode a client can configure a set of three sequences. If the current configured sequences fits the desired signal, a client can intstruct the server to set the sequences. This moves the configuration sequences to the acquisition sequences and writes the first values to the FPGA buffer.

During an active trigger the buffer is periodically updated by the server. If the server recognizes the end of a sequence, it sets the amplitudes of the waveform components to 0.

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:DAC:SEQ:CLocKdivider | divider | Set the clock divider with which the sequence advances | C | |
| RP:DAC:SEQ:CLocKdivider? | | Return the clock divider | Any | |
| RP:DAC:SEQ:SAMPlesperstep | samples per step | Set the clock divider such that the sequence advances every given number of samples. | C | |
| RP:DAC:SEQ:SAMPlesperstep? |  | Return the number of samples per step | Any | |
| RP:DAC:SEQ:CHan | numChan (1, 2, 3, 4) | Set the number of sequence channel | C | |
| RP:DAC:SEQ:CHan? |  | Return the number of sequence channel |  | |
| RP:DAC:SEQ:LUT | steps, repetitions | Instruct the server to receive a LUT over the data socket | C | RP:DAC:SEQ:LUT 10,2 |
| RP:DAC:SEQ:LUT:ENaBle |  | Instruct the server to receive an enable LUT over the data socket of the same shape as the regular LUT| C | |
| RP:DAC:SEQ:LUT:UP | steps, repetitions | Instruct the server to receive a ramp up LUT over the data socket | C | |
| RP:DAC:SEQ:LUT:DOWN | steps, repetitions | Instruct the server to receive a ramp down LUT over the data socket | C | |
| RP:DAC:SEQ:CLEAR |  | Clear the set sequence values from the FPGA buffer | C | |
| RP:DAC:SEQ:SET |  | Set the current configured sequence as the acquisition sequence | C | |




## Acquisition and Transmission
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:TRIGger | trigger status (OFF, ON) | Set the internal trigger status | A | RP:TRIG ON |
| RP:TRIGger? |  | Return the trigger status | Any | RP:TRIG? |
| RP:TRIGger:ALiVe | keep alive status (OFF, ON) | Set the keep alive bypass | A | RP:TRIG:ALV OFF |
| RP:TRIGger:ALiVe? |  | Return the keep alive status | Any | RP:TRIG:ALV? |
| RP:ADC:WP:CURRent? |  | Return the current writepointer | A, T | RP:ADC:WP? |
| RP:ADC:DATa? | readpointer, number of samples | Transmit number of samples from the buffer component of the readpointer over the data socket. Return true on the command socket if transmission is started. | A | RP:ADC:DATa? 400,1024 |
| RP:ADC:DATa:PIPElined? | readpointer, number of samples, chunksize | Transmit number of samples from the readpointer on in chunks of chunksize over the data socket. After every chunk status and performance data is transmitted over the data socket. Return true if pipeline was started. | A | RP:ADC:DAT:PIPE? 400,1024,128 |
| RP:STATus? |  | Transmit status as one byte with flags from lower bits: overwritten, corrupted, lost steps, master trigger, sequence active | Any | RP:STAT? |
| RP:STATus:OVERwritten? |  | Transmit overwritten flag | Any | RP:STAT:OVER? |
| RP:STATus:CORRupted? |  | Transmit corrupted flag | Any | RP:STAT:CORR? |
| RP:STATus:LOSTSteps? |  | Transmit lost steps flag | Any | RP:STAT:LOSTS? |
| RP:PERF? |  | Transmit ADC and DAC performance data | Any | RP:PERF? |

## Calibration
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
|RP:CALib:ADC:CHannel#:OFFset | channel (0, 1), offset | Store the ADC offset value for given channel in EEPROM  | C | RP:CAL:ADC:CH0:OFF 0.2 |
|RP:CALib:ADC:CHannel#:OFFset? | channel (0, 1) | Return the ADC offset value for given channel from EEPROM | Any | RP:CAL:ADC:CH1:OFF? |
|RP:CALib:ADC:CHannel#:SCAle | channel (0, 1), scale| Store the ADC scale value for given channel in EEPROM | C | RP:CAL:ADC:CH1:SCA 1.0 |
|RP:CALib:ADC:CHannel#:SCAle? | channel (0, 1) | Return the ADC scale value for given channel from EEPROM | Any | RP:CAL:ADC:CH1:SCA? |
|RP:CALib:DAC:CHannel#:OFFset | channel (0, 1), offset | Store the DAC offset value for given channel in EEPROM  | C | RP:CAL:DAC:CH0:OFF 0.2 |
|RP:CALib:DAC:CHannel#:OFFset? | channel (0, 1) | Return the DAC offset value for given channel from EEPROM | Any | RP:CAL:DAC:CH1:OFF? |
|RP:CALib:DAC:CHannel#:SCAle | channel (0, 1), scale| Store the DAC scale value for given channel in EEPROM | C | RP:CAL:DAC:CH1:SCA 1.0 |
|RP:CALib:DAC:CHannel#:SCAle? | channel (0, 1) | Return the DAC scale value for given channel from EEPROM | Any | RP:CAL:DAC:CH1:SCA? |

## DIO

| Command        | Arguments    | Description         | Example         |
| :-------------- | :---------------- | :------------------- | :------------------- |
| RP:DIO:DIR      | identifier of pin, direction (IN/OUT)  | Set the direction of the DIO      |  RP:DIO:DIR DIO7_P,IN  |
| RP:DIO      | identifier of pin, value (0/1)  | Set the output of the DIO      |  RP:DIO DIO7_P,1  |
| RP:DIO?      | identifier of pin  | Get the input of the DIO      |  RP:DIO? DIO7_P  |
