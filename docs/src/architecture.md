# Architecture

The RedPitayaDAQServer project is implemented as a distributed system in which one client connects to a cluster of RedPitaya boards. The project has four software components:
* FPGA image running the RedPitayas
* C library encapsulating access to the FPGA image
* Server running on the CPU of the RedPitayas
* [Client](client.md) Julia reference library 
  
The FPGA image is responsible for [generating](generation.md) and [acquiring](acquisition.md) sychronized out- and input signals. The server acts as an intermediary to the FPGA over a TCP/IP connection, which allows remote clients to configure the FPGA image and retrieve samples. Furthermore, the server also maintains a thread that takes part in signal generation.

The Julia client library can be used to implement a data acqusition client application, which controls a (cluster of) RedPitaya(s). This Julia library acts as a reference, but in principle it is possible to write clients in any programming language, as the communication is language agnostic.

## Communication
The various components of the distributed system communicate over different interfaces. Communication within a RedPitaya is based on memory-mapped I/O, while communication between the server and a client is based on SCPI commands over a TCP/IP connection, usually over Ethernet. Lastly communication between RedPitayas is limited to signals distributed over cables as described in [Cluster](cluster.md).
### FPGA and CPU
The FPGA image is directly connected to certain memory regions that can be memory mapped on the CPU side of the RedPitaya. Both the CPU and the FPGA image access the reserved main memory region as a sample buffer. The C library `rp-daq-lib` located in `src/lib/` encapsulates these memory accesses into a convenient C library. It is possible to use this C library directly when no communication with the host system is required, i.e. if one wants to write the acquired data into a file. When making changes to the FPGA image one may need to adapt the `rp-daq-lib` C library.

The server itself uses the `rp-daq-lib` library to interface with the FPGA image.

### Client and Server
The server on each RedPitaya has two TCP sockets to which a client needs to connect. The first is the command socket on port 5025 and the second is the data socket on port 5026. Over the former, a client can send SCPI commands to the server and receive replies, while the latter is used for sending binary data such as the samples acquired by the ADCs.

SCPI commands are ASCII strings, such as `RP:ADC:DECimation`, which the server translates into C function calls. As an example these calls could invoke a function of the `rp-daq-lib` library to set the decimation of the sampling rate or instruct the server to transmit data over the data socket. A list of the available SCPI commands can be found [here](scpi.md).

At any point a server is only connected to one client and establishing a new connection stops any current signal generation and acquisition.