# SCPI Interface

For communication betten the server and the client an [SCPI](https://en.wikipedia.org/wiki/Standard_Commands_for_Programmable_Instruments) with custom commands is used. The following table gives an overview of availalbe commands:

## DIO

| Command        | Arguments    | Description         | Example         |
| :-------------- | :---------------- | :------------------- | :------------------- |
| RP:DIO:DIR      | identifier of pin, direction (IN/OUT)  | Set the direction of the DIO      |  RP:DIO:DIR DIO7_P,IN  |
| RP:DIO      | identifier of pin, value (0/1)  | Set the output of the DIO      |  RP:DIO DIO7_P,1  |
| RP:DIO?      | identifier of pin  | Get the input of the DIO      |  RP:DIO? DIO7_P  |

## ADC Configuration

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:ADC:DECimation | decimation value [8, ..., n]| Set the decimation factor of the base sampling rate| C | RP:ADC:DEC 8 | 
| RP:ADC:DECimation? | | Return the decimation factor | C, M, T | RP:ADC:DEC? |
| RP:TRIGger:MODe | trigger mode (EXTERNAL, INTERNAL) | Set the trigger mode, which trigger the RedPitaya listens to | C | RP:TRIG:MOD INTERNAL |
| RP:TRIGger:MODe? |  | Return the trigger mode | C, M, T | RP:TRIG:MOD? |


## DAC Configuration

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| |  |  |  | |

## Sequence Configuration
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| |  |  |  | |


## Acquisition, Generation and Transmission
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:TRIGger | trigger status (OFF, ON) | Set the internal trigger status | M | RP:TRIG ON |
| RP:TRIGger? |  | Return the trigger status | C, M, T | RP:TRIG? |
| RP:TRIGger:ALiVe | keep alive status (OFF, ON) | Set the keep alive bypass | M | RP:TRIG:ALV OFF |
| RP:TRIGger:ALiVe? |  | Return the keep alive status | C, M, T | RP:TRIG:ALV? |
| RP:ADC:WP:CURRent? |  | Return the current writepointer | M, T | RP:ADC:WP? |
| RP:ADC:DATa? | readpointer, number of samples | Transmit number of samples from the buffer component of the readpointer on | M | RP:ADC:DATa? 400,1024 |
| RP:ADC:DATa:PIPElined? | readpointer, number of samples, chunksize | Transmit number of samples from the readpointer on in chunks of chunksize. After every chunk status and performance data is transmitted. | M | RP:ADC:DAT:PIPE? 400,1024,128 |
| RP:STATus? |  | Transmit status  |  | |
| RP:STATus:OVERwritten? |  |  |  | |
| RP:STATusCORRupted? |  |  |  | |
| RP:STATus:LOSTSteps? |  |  |  | |
| RP:PERF? |  |  |  | |
