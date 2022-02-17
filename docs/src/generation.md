# Signal Generation
Once the acquisition is triggered, each RedPitaya also starts producing signals on their output channels. Each RedPitaya features six such channels, two of those are the 16-bit DAC channel and four of those are digital pins using PDM, see [Connections](connections.md). The output signals are composed of two parts: parameterized waveforms and repeating arbitrary LUT tables. The latter are called sequences. The resulting signal of the DAC channel can be described as: 

```math
S_i(t) = seq_i(t) + o_i + a_{i,1}w(t, f_{i,1}, \varphi_{i, 1}) +\sum_{j=2}^{4}a_{i,j} \sin(2\pi f_{i,j}t + \varphi_{i, j}),
```
## Waveforms
Each of the 16-bit DAC channel can output a compositve waveform with four components. Each component can be parametrized by its amplitude, frequency and phase, which can all be changed via SCPI commands. Furthermore, the first component also offers different waveforms (sine, square, sawtooth), while the remaining components only offer a sine waveform.

Additionally, each channel also has an offset parameter and a calibration offset. The calibration offset is stored in the RedPitayas EEPROM and is applied in the background.

## Sequences
The FPGA image features a LUT containing values for all output channels. This LUT is treated as a ring-buffer through which the image iterates and outputs the values on their respective channel. The image can be configured to increment its LUT access every n samples. One period of a value is also called a step.

As the LUT used by the FPGA image is small in comparison with the main memory and to support longer series of steps, the server itselfs maintains a list of sequences. A sequence is a series of steps and the number of times this series is to be repeated. During an acqusition and the parallel signal generation the server periodically reads the next steps from its sequence list and writes them to the LUT of the image.

Comparable to the sample transmission of the acquisition, this updating of the LUT is also a process with timing uncertainty as it is affected by the scheduling and execution of the RedPitayas CPU. While during the sample transmission samples could be lost because they were overwritten, in the signal generation wrong signals could be output because the server was too slow in updating the values. Here, the server tracks similar performance metrics and also features a status flag `lostSteps` for exactly this case. In its current implementation a safe step rate is at 12 kHz.

Sequences and their steps also have additional features. A step can be marked such that during its duration the signal is set to 0. The last step of a sequence can also be marked such that the phase of the waveforms is reset to 0 for the following sequence. This involves adding an additional reset step.