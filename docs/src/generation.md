# Signal Generation
Once the acquisition is triggered, each RedPitaya also starts producing signals on their output channels. Each RedPitaya features six such channels, two of those are the 16-bit DAC channel and four of those are digital pins using PDM, see [Connections](connections.md). The output signals are composed of three parts: parameterized waveforms ``W_i(t)``, an offset ``o_i`` and repeating arbitrary LUT tables. The latter are called sequences ``seq_i(t)``. The resulting signal of the DAC channel can be described as: 

```math
S_i(t) = seq_i(t) + o_i + W_i(t)
```
## Waveforms
Each of the 16-bit DAC channel can output a compositve waveform with four components. Each component can be parametrized by its amplitude ``a_{i,j}``, frequency ``f_{i,j}`` and phase ``\varphi_{i,j}``, which can all be changed via SCPI commands. Furthermore, each component also offers different waveforms ``w_{i,j}``(sine, triangle, sawtooth):
```math
W_i(t) = \sum_{j=1}^{4}a_{i,j} w_{i,j}(2\pi f_{i,j}t + \varphi_{i, j})
```
## Ramping
The signals output on the DAC channel can also be multiplied with an increasing/decreasing ramping factor ``r(t)``. Ramping and the ramping duration can be enabled and set on a per channel basis. The increasing factor starts from 0 and goes to 1 from the acquisition start on. The decreasing factor goes from 1 to 0.

```math
S_i'(t) = r(t)S(t)
```

The ramp down has to be started either by a SCPI command or by a flag from a sequence. Disabling the acquisition trigger removes the ramp down flag, but not the flag that enables ramping itself.

## Sequences
The FPGA image features a LUT containing values for all output channels. This LUT is treated as a ring-buffer through which the image iterates and outputs the values on their respective channel. The image can be configured to increment its LUT access every n samples. One period of a value is also called a step. A sequence is a series of steps and the number of times this series is to be repeated.

As the LUT used by the FPGA image is small in comparison with the main memory and in order to support longer series of steps, the server itselfs maintains a sequence in its main memory and periodically reads the next steps from its sequence and writes them to the LUT of the image.

Comparable to the sample transmission of the acquisition, this updating of the LUT is also a process with timing uncertainty as it is affected by the scheduling and execution of the RedPitayas CPU. While during the sample transmission samples could be lost because they were overwritten, in the signal generation wrong signals could be output because the server was too slow in updating the values. Here, the server tracks similar performance metrics and also features a status flag `lostSteps` for exactly this case. In its current implementation a safe step rate is at 12 kHz.

Sequences and their steps also have additional features. A step can be marked such that during its duration the signal is set to 0. Furthermore, a step can be marked such that it triggers the ramp down. To make this easier to manage the server actually manages three sequences, that can be set individually: A ramp up, regular and ramp down sequence. The ramp up sequence is moved to the FPGA LUT at the acquisition start, followed by the regular sequence. Afterwards the ramp down sequence is started and during its execution the ramp down flag is set.

## Calibration
Similar to the signal acquisition, there are also calibration scale ``c_{i, scale}`` and offset ``c_{i, offset}`` values  for the signal generation. These are stored in the EEPROM of the RedPitaya and can be updated by a client. The calibration values are always applied, even when the master trigger is off.

Thus the total signal can be described as:
```math
S_i''(t) = c_{i, scale} S_i'(t) + c_{i, offset}
```
