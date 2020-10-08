# SCPI Interface

For communication betten the server and the client an [SCPI](https://en.wikipedia.org/wiki/Standard_Commands_for_Programmable_Instruments) with custom commands is used. The following table gives an overview of all commands:

## DIO

| Command        | Arguments    | Description         | Example         |
| :-------------- | :---------------- | :------------------- | :------------------- |
| RP:DIO:DIR      | identifier of pin, direction (IN/OUT)  | Set the direction of the DIO      |  RP:DIO:DIR DIO7_P,IN  |
| RP:DIO      | identifier of pin, value (0/1)  | Set the output of the DIO      |  RP:DIO DIO7_P,1  |
| RP:DIO?      | identifier of pin  | Get the input of the DIO      |  RP:DIO? DIO7_P  |

## Fast ADC

| Command        | Arguments    | Description         | Example         |
| :-------------- | :---------------- | :------------------- | :------------------- |
| RP:ADC:SlowADC     |  |  |  |
| RP:ADC:SlowADC?     |  |  |  |
| RP:ADC:DECimation     |  |  |  |
| RP:ADC:DECimation?     |  |  |  |
| RP:ADC:PERiod     |  |  |  |
| RP:ADC:PERiod?     |  |  |  |
| RP:ADC:PERiods:CURRent     |  |  |  |
| RP:ADC:PERiods:DATa     |  |  |  |
| RP:ADC:FRAme     |  |  |  |
| RP:ADC:FRAme?     |  |  |  |
| RP:ADC:FRAmes:CURRent?     |  |  |  |
| RP:ADC:WP:CURRent?     |  |  |  |
| RP:ADC:FRAmes:DATa     |  |  |  |
| RP:ADC:BUFfer:Size?     |  |  |  |
| RP:ADC:Slow:FRAmes:DATa     |  |  |  |
| RP:ADC:ACQCONNect     |  |  |  |
| RP:ADC:ACQSTATus     |  |  |  |
| RP:ADC:ACQSTATus?     |  |  |  |


## DAC and Sequences

| Command        | Arguments    | Description         | Example         |
| :-------------- | :---------------- | :------------------- | :------------------- |
| RP:DAC:CHannel#:COMPonent#:AMPlitude?     |  |  |  |
| RP:DAC:CHannel#:COMPonent#:AMPlitude     |  |  |  |
| RP:DAC:CHannel#:COMPonent#:Next:AMPlitude?     |  |  |  |
| RP:DAC:CHannel#:COMPonent#:Next:AMPlitude     |  |  |  |
| RP:DAC:CHannel#:COMPonent#:FREQuency?     |  |  |  |
| RP:DAC:CHannel#:COMPonent#:FREQuency     |  |  |  |
| RP:DAC:CHannel#:COMPonent#:PHase?     |  |  |  |
| RP:DAC:CHannel#:COMPonent#:PHase     |  |  |  |
| RP:DAC:CHannel#:OFFset?     |  |  |  |
| RP:DAC:CHannel#:OFFset     |  |  |  |
| RP:DAC:MODe     |  |  |  |
| RP:DAC:MODe?     |  |  |  |
| RP:DAC:CHannel#:SIGnaltype     | signaltype (SINE / SQUARE / TRIANGLE / SAWTOOTH)   | set the signal type  | RP:DAC:CH0:SIG SINE |
| RP:DAC:CHannel#:SIGnaltype?     |  |  |  |
| RP:DAC:CHannel#:JumpSharpness     |  |  |  |
| RP:DAC:CHannel#:JumpSharpness?     |  |  |  |
| RP:ADC:SlowDAC     |  |  |  |
| RP:ADC:SlowDAC?     |  |  |  |
| RP:ADC:SlowDACLUT     |  |  |  |
| RP:ADC:SlowDACEnable     |  |  |  |
| RP:ADC:SlowDACLostSteps?     |  |  |  |
| RP:ADC:SlowDACPeriodsPerFrame     |  |  |  |
| RP:ADC:SlowDACPeriodsPerFrame?     |  |  |  |
| RP:PDM:ClockDivider    |  |  |  |
| RP:PDM:ClockDivider?    |  |  |  |
| RP:PDM:CHannel#:NextValue    |  |  |  |
| RP:PDM:CHannel#:NextValueVolt    |  |  |  |
| RP:PDM:CHannel#:NextValue? | | | |


## Misc

| Command        | Arguments    | Description         | Example         |
| :-------------- | :---------------- | :------------------- | :------------------- |
| RP:XADC:CHannel#?     |  |  |  |
| RP:WatchDogMode     |  |  |  |
| RP:WatchDogMode?     |  |  |  |
| RP:RamWriterMode     |  |  |  |
| RP:RamWriterMode?     |  |  |  |
| RP:PassPDMToFastDAC     |  |  |  |
| RP:PassPDMToFastDAC?     |  |  |  |
| RP:KeepAliveReset     |  |  |  |
| RP:KeepAliveReset?     |  |  |  |
| RP:Trigger:MODe     |  |  |  |
| RP:Trigger:MODe?     |  |  |  |
| RP:MasterTrigger     |  |  |  |
| RP:InstantResetMode     |  |  |  |
| RP:InstantResetMode?     |  |  |  |
| RP:PeripheralAResetN?    |  |  |  |
| RP:FourierSynthAResetN?    |  |  |  |
| RP:PDMAResetN?    |  |  |  |
| RP:XADCAResetN?    |  |  |  |
| RP:TriggerStatus?    |  |  |  |
| RP:WatchdogStatus?    |  |  |  |
| RP:InstantResetStatus?    |  |  |  |
