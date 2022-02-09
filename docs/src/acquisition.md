# Data Acqusition

The data acqusition of the RedPitayaDAQServer project is based on two data flows to and from the upper 128 MB of the RedPitaya memory. This memory region acts as a ring buffer for the acquired samples and can be queried by clients using SCPI commands.

Signal acquisition within a cluster is based on a shared clock and trigger signal distributed via cables between the RedPitayas. Once triggered, all FPGAs continuously write the samples from their ADC channel to the sample ring-buffer with each clock tick. Both ADC channels on a RedPitaya are written to the buffer at the same time and their 16-bit samples are concatenated into one 32-bit value. The sampling rate of the system can be adjusted by setting a decimation parameter and the decimation itself is realized with a CIC filter.

Internally, the FPGA keeps track of a 64-bit writepointer register pointing into the ring-buffer and increments this value with each new sample pair. Additionally, the writepointer also counts the number of buffer overflows. As the size of the buffer region is a power of two, these two components of the writepointer can be interpreted as one 64-bit number counting the samples from acquisition start. For the 128 MB buffer, this means that the lower 25 bits of the writepointer are the buffer location and the remaining bits are the overflow counter.

As the writepointer is reset and incremented based on a shared clock and trigger signal, it is synchronized across all FPGA images in a cluster. The logic implemented with the reprogrammable hardware is also the only logic of the RedPitayaDAQServer with predictable timing behaviour. All other components of the system implement their (timing related) logic in reference to the current writepointer values. With a known sampling rate, the writepointer can also be seen as the clock of the server and client components.

## Sample Transmission

To retrieve samples from the server a client can supply a similar pointer, a readpointer, together with the number of samples to retrieve. The server then extracts the buffer position from the readpointer and transmits the requested amount of samples over the data socket. This transmission happens either way, even if the samples are overwritten. However, the server uses the whole readpointer, including the buffer overflows, to check if the requested samples were overwritten.

If the distance between the write- and readpointer is larger than the buffer size the `overflow` status flag is set. If during the transmission the requested samples are overwritten the `corrupted` flag is set. These flags can be queried individually or together in a status byte via SCPI commands.

This distance can not only be used to see if samples were overwritten, but also to track how well the client is able to keep up with the FPGA during a series of sample transmissions. If this distance increases over time, the FPGA is creating more samples than the server can transmit to the client. To allow a client to track this value, this distance is stored as a 64-bit value `deltaRead` for the latest transmission and can be queried. Additionally, the server also tracks the duration of the transmission as writepointer "clock ticks" as a 64-bit value `deltaSend`, which is just the difference between the writepointer at the start and end of a transmission.

## Considerations for Sample Transmission
There are several things to consider when attempting to retrieve samples at a high sampling rate, larger cluster sizes or for longer periods of time. Most of the following points were implemented/considered in the Julia reference implementation, but would become relevant when implementing custom clients.

As the server will always transmit samples just based on the buffer position of a readpointer, if a client wants to only receive certain samples it needs to wait for them to exist in the buffer. This requires querying the writepointer until it is larger than the desired readpointer.

If the number of requested samples is larger than the buffer, the sample should be requested in smaller chunks as the server would otherwise return samples that were not written yet. In a cluster scenario the i-th chunk should be requested from all RedPitayas in the cluster before requesting the next chunk to avoid "starvation" effects.

The status and performance data of a transmission can only be queried after the transmission has finished, which requires additionaly communication overhead.

To help clients with these issues, the server offers a second type of sample transmission in which samples, status and performance data is pipelined. In such a query a client first transmits a readpointer, together with the number of requested samples and the number of samples belonging to a chunk. The server itself then tracks the writepointer and transmits a chunk as soon as it becomes available and immidiatey follows that up with the status and performance data of the transmission. This way additional communication overheard is reduced and after the inital request a client just needs to read data until the transmission finishes.
## Frames, Periods and Voltage
The samples sent by the server are the 16-bit values of the ADC channel of a RedPitaya. However, one might want to instead work with voltage values or encapsulate samples into a repeating concept like frames. The Julia client library offers functions to convert samples into such a concept or to directly request a number of frames instead of a number of samples.

Here, frames are comprised of periods, which in turn are comprised of samples. During the conversion process the 16-bit binary values can also be converted to floating point numbers representing a voltage if the RedPitaya was calibrated beforehand. In this calibration process, a client can store scale and offset values for each channel in the EEPROM of the RedPitaya. When the client establishes a connection to the server, it reads these values and can use them to translate the 16-bit values into a respective voltage value.