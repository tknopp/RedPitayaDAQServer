# Architecture

The RedPitayaDAQServer project has an architecture where the following three parts are communicating through different protocols:
* FPGA on the RedPitaya
* Server running on the CPU of the RedPitaya
* Client on the host computer

## FPGA - Server Interface

The FPGA image is directly connected to certain memory regions that can be memory mapped on the CPU of the RedPitaya. The C library `rp-daq-lib` located in `src/lib/` encapsulates these memory accessed into a convenient C library. It is possible to use this C library directly when no communication with the host system is required, i.e. if one wants to write the acquired data into a file. When making changes to the FPGA image one may need to adapt the `rp-daq-lib` C library.

## Client - Server Interface

The DAQ server uses the `rp-daq-lib` C library and allows to access its functions via TCP/IP.
The server has three main purposes:
* It translates from TCP commands to C commands
* It sends the data acquired with the fast ADCs to the client. Not all data is send but only the data requested by the client
* It maintains a controller thread for feeding the slow DACs in a fully synchronized fashion.

## Application - Client Interface

In principle it is possible to write the client in any programming language. The RedPitayaDAQServer offers a simple client implemented in Python and a more sophisticated client implemented in Julia.
