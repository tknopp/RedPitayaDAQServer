# Changelog

## 0.11.0

### Breaking Changes
- **Breaking**: Updated ADC and DAC pipeline requires a new ADC and DAC calibration after the update!
- **Breaking**: When not using the ADC calibration the integer values will now be in the range of [-32768, 32767] instead of [-8192, 8191]

### Updated ADC Pipeline
- The decimating pipeline after the ADC now uses the full 16-bit accuracy decreasing the quantization noise which becomes dominant over the ADC noise at high decimations (>256)
- The FIR filter added in v0.6.0 can now be switched on and off using `firEnabled!`. For all standard applications the filter should be left on for improved anti-aliasing and flatter frequency response. The filter can be turned off for applications where the delay introduced by the filter is unwanted, e.g. time-based multiplexing

### Updated DAC Pipeline
- increased amplitude resolution of waveform signal components to 16-bit, decreasing the discretization of the sine amplitude from 122 µV to 15 µV
- increase resolution of DAC pipeline to 16-bit until the final output quantization for improved accuracy when combining different components
- prevent potential overflow in DAC pipeline when adding multiple components
- reintroduced signal limiter, which was mistakenly removed in a previous release
- removed hard limit of 1 V from amplitude components, as the DAC might be able to produce higher amplitudes depending on the calibration

### General Updates
- extended instant reset to ramp down the outputs if ramping is enabled instead of cutting
- (re)added SCPI interface to enable instant reset
- added 3-bit counter output with configurable counter speed outputting on DIO2_N (LSB) to DIO4_N (MSB)
- Improved passing of error messages from SCPI server to the Julia client
- added `calibReset!(rp)` to reset ADC and DAC calibration to default
- added `serverversion(rp)` to query the version of the server running of the RedPitaya
- improved `imgversion` to not error on server versions prior to the introduction
- added two examples on FIR switching


