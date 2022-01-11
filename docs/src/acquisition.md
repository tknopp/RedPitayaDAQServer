# Data Acqusition

The data acqusition of the RedPitayaDAQServer project is based on two data flows to and from the upper 128 MB of the RedPitaya memory. This memory region acts as a ring buffer for the acquired samples and can be queried by clients using SCPI commands.

Once triggered to start via the master trigger, each FPGA in a cluster continously writes the sampled signals into their respective buffers. Both ADC channels on a RedPitaya are written to the buffer at the same time and the 16-bit samples are concatenated into one 32-bit value. The sampling rate of the system can be adjusted by setting a decimation parameter. Decimation is realized by using a CIC filter.

Internally the FPGA keeps track of a 64-bit writepointer register pointing into the ring buffer and increments this value with each new sample pair. Additionally the writepointer also counts the number of buffer overflows. As the size of the buffer region is a power of two, the lower 25 bits of the writepointer are the buffer location and the remaining bits are the overflow counter. The writepointer can be directly interpreted as the total number of samples written since the data acquisition was started. The current writepointer value can be queried by a SCPI command.

In the SCPI commands for sample retrieval a client can supply a similar pointer, a readpointer, to the server together with the number of samples to retrieve. The server then extracts the buffer position from the readpointer and transmits the requested amount of samples over the data socket. This transmission happens either way, even if the samples are overwritten. However, the server uses the whole readpointer, including the buffer overflows, to check if the requested samples were overwritten.

If the distance between the write- and readpointer is larger than the buffer size the `overflow` status flag is set. If during the transmission the requested samples are overwritten the `corrupted` flag is set. These flags can be queried individually or together in a status byte via SCPI commands.

## Considerations for Sample Retrieval
There are several things to consider when attempting to retrieve samples at a high sampling rate, larger cluster sizes or for longer periods of time. Most of the following points were implemented/considered in the Julia reference implementation, but would become relevant when implementing new clients.

As the server will always transmit samples just based on the buffer position of a readpointer, if a client wants to only receive certain samples it needs to wait for them to exist in the buffer. This requires querying the writepointer until it is larger than the desired readpointer.

If the number of requested samples is larger than the buffer, the sample should be requested in smaller chunks as the server would otherwise return samples that were not written yet. In a cluster scenario the i-th chunk should be requested from all RedPitayas in the cluster before requesting the next chunk.

## Considerations for Frame Retrieval/Julia Client
Producer/Consumer