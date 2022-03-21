# SCPI Interface

For communication betten the server and the client an [SCPI](https://en.wikipedia.org/wiki/Standard_Commands_for_Programmable_Instruments) with custom commands is used. In the following tables an overview of the available commands and their behaviour is given. The Julia [Client](client.md) library encapsulates these commands into function calls, abstracting their communication details and also combining commands to manage a cluster of RedPitayas at the same time.

As a safe guard the server has different modes and certain commands are only available in certain modes. As an example, during an acquisition changing the sampling rate would result in unclear behaviour. To stop such a scenario the decimation can only be set in the `CONFIGURATION` mode and an acquisition can only be triggered in the `ACQUISITION` mode. The available modes are `CONFIGURATION`, `ACQUISITION` and `TRANSMISSION`. The former two are set by the client and the latter is set by the server during sample transmission.

After each SCPI command the server replies with `true` or `false` on the command socket depending on whether the given command was successfully excecuted. The exception to this rule are the commands which themselves just query values from the server.

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
The server maintains a list of sequences. When the server is `ACQUSITION` mode a client can configure a sequence. If the current configured sequence fits the desired sequence, a client can intstruct the server to append the configured sequence to its list. Before a trigger is set the current sequence list needs to be prepared to take effect. This starts filling the FPAG buffer with the sequence values. During an active trigger the buffer is periodically updated by the server. If the server recognizes the end of a sequence, it sets the amplitudes of the waveform components to 0.
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:DAC:SEQ:CLocKdivider | divider | Set the clock divider with which the sequence advances | C | |
| RP:DAC:SEQ:CLocKdivider? | | Return the clock divider | C | |
| RP:DAC:SEQ:SAMPlesperstep | samples per step | Set the clock divider such that the sequence advances every given number of samples. | C | |
| RP:DAC:SEQ:SAMPlesperstep? |  | Return the number of samples per step |  | |
| RP:DAC:SEQ:CHan | numChan (1, 2, 3, 4) | Set the number of sequence channel. Holds for all sequences in the list | C | |
| RP:DAC:SEQ:CHan? |  | Return the number of sequence channel |  | |
| RP:DAC:SEQ:STEPs | steps | Set the number of steps of the configured sequence | C | |
| RP:DAC:SEQ:STEPs? |  | Return the number of steps of the configured sequence | C | |
| RP:DAC:SEQ:LUT:ARBITRARY |  | Instruct the server to receive a LUT over the data socket | C | |
| RP:DAC:SEQ:RaMPing | steps, totalSteps | Set ramp up/down and ramp up/down total steps  | C | |
| RP:DAC:SEQ:RaMPing:STEPs | steps | Set ramp up/down steps  |  | |
| RP:DAC:SEQ:RaMPing:TOTAL | totalSteps | Set ramp up/down total steps  | C | |
| RP:DAC:SEQ:RaMPing:UP | steps, totalSteps | Set ramp up steps and total steps | C | |
| RP:DAC:SEQ:RaMPing:UP:STEPs | steps | Set ramp up steps to the given steps | C | |
| RP:DAC:SEQ:RaMPing:UP:STEPs? | | Return the number of ramp up steps | C | |
| RP:DAC:SEQ:RaMPing:UP:TOTAL | totalSteps | Set ramp up total steps to the geiven total steps | C | |
| RP:DAC:SEQ:RaMPing:UP:TOTAL? |  | Return the number of ramp up total steps | C | |
| RP:DAC:SEQ:RaMPing:DOWN | steps, totalSteps | Set ramp down steps and total steps | C | |
| RP:DAC:SEQ:RaMPing:DOWN:STEPs | steps | Set ramp down steps | C | |
| RP:DAC:SEQ:RaMPing:DOWN:STEPs? |  | Return ramp down steps | C | |
| RP:DAC:SEQ:RaMPing:DOWN:TOTAL | totalSteps | Set ramp down total steps | C | |
| RP:DAC:SEQ:RaMPing:DOWN:TOTAL? |  | Return ramp down total steps | C | |
| RP:DAC:SEQ:REPetitions | repetitions | Set the number of times a sequence is repeated | C | |
| RP:DAC:SEQ:REPetitions? |  | Return the number of times the sequence is repeated | C | |
| RP:DAC:SEQ:RESETafter | reset(0,1) | Set to true if between the current sequence and the next the phase should be reset | C | |
| RP:DAC:SEQ:RESETafter? |  | Return the phase reset flag of the sequence | C | |
| RP:DAC:SEQ:APPend |  | Append the current configured sequence to the sequence list | C | |
| RP:DAC:SEQ:POP |  | Remove the latest entry from the sequence list | C | |
| RP:DAC:SEQ:CLEAR |  | Clear the sequence list | C | |
| RP:DAC:SEQ:PREPare |  | Prepare the sequence list | C | |




## Acquisition and Transmission
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:TRIGger | trigger status (OFF, ON) | Set the internal trigger status | M | RP:TRIG ON |
| RP:TRIGger? |  | Return the trigger status | Any | RP:TRIG? |
| RP:TRIGger:ALiVe | keep alive status (OFF, ON) | Set the keep alive bypass | M | RP:TRIG:ALV OFF |
| RP:TRIGger:ALiVe? |  | Return the keep alive status | Any | RP:TRIG:ALV? |
| RP:ADC:WP:CURRent? |  | Return the current writepointer | M, T | RP:ADC:WP? |
| RP:ADC:DATa? | readpointer, number of samples | Transmit number of samples from the buffer component of the readpointer over the data socket. Return true on the command socket if transmission is started. | M | RP:ADC:DATa? 400,1024 |
| RP:ADC:DATa:PIPElined? | readpointer, number of samples, chunksize | Transmit number of samples from the readpointer on in chunks of chunksize over the data socket. After every chunk status and performance data is transmitted over the data socket. Return true if pipeline was started. | M | RP:ADC:DAT:PIPE? 400,1024,128 |
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
