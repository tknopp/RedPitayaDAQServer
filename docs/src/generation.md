# Signal Generation
Once the acquisition is triggered, each RedPitaya also starts producing signals on their output channels. Each RedPitaya features six such channels, two of those are the 16-bit DAC channel and four of those are digital pins using PDM, see [Connections](connections.md). The output signals are composed of two parts: parameterized waveforms and repeating arbitrary LUT tables. The latter are called sequences. The resulting signal of the DAC channel can be described as: 

```math
S_i(t) = seq_i(t) + o_i + a_{i,1}w(t, f_{i,1}, \varphi_{i, 1}) +\sum_{j=2}^{4}a_{i,j} \sin(2\pi f_{i,j}t + \varphi_{i, j}),
```
## Waveforms
Each of the 16-bit DAC channel can output a compositve waveform with four components. Each component can be parametrized by its amplitude, frequency and phase, which can all be changed via SCPI commands. Furthermore, the first component also offers different waveforms (sine, square, sawtooth), while the remaining components only offer a sine waveform.

Additionally, each channel also has an offset parameter and a calibration offset. The calibration offset is stored in the RedPitayas EEPROM and is applied in the background.

## Sequences
