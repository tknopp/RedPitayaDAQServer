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
| RP:ADC:DECimation | decimation value [8, ..., n]| Set the decimation factor of the sampling rate| C | RP:ADC:DEC 8 | 
| RP:ADC:DECimation? | | Return the decimation factor | C, M, T | |
| RP:TRIGger:MODe | server mode (CONFIGURATION, MEASUREMENT) | Set the server mode | C | RP:TRIG:MOD CONFIGURATION |
| RP:TRIGger:MODe? |  | Return the server mode | C, M, T | RP:TRIG:MOD? |


## DAC Configuration

| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| |  |  |  | |

## Sequence Configuration
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| |  |  |  | |


## Transmission
| Command | Arguments | Description | Mode | Example |
| :--- | :--- | :--- | :---: | :--- |
| RP:TRIGger |  |  | M | |
| RP:TRIGger? |  |  | C, M, T | |
| RP:TRIGger:ALiVe |  | | M | |
| RP:TRIGger:ALiVe? |  | | C, M, T | |
| RP:ADC:WP:CURRent? |  | | M, T | |
| RP:ADC:DATa? |  |  | M | |
| RP:ADC:DATa:PIPElined? |  |  | M | |