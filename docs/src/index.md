# RedPitayaDAQServer

*Advanced DAQ Tools for the RedPitaya (STEMlab 125-14)*

## Introduction

This project contains software to be used with the STEMlab 125-14 device from RedPitaya. It allows for continuous generation and measurement of signals with up to 15.625 MS/s, which is not possible with the standard image of the RedPitaya. In addition, the software allows to synchronize a cluster of multiple RedPitayas. This project contains the following parts:
* Alpine Linux image for the RedPitaya
* FPGA image
* Client library (implemented in C) that can be used on the RedPitaya
* SCPI Server for accessing the functionality over TCP/IP
* SCPI Clients to access the server

The code repositories is contained in this [repository](https://github.com/tknopp/RedPitayaDAQServer).


## License / Terms of Usage

The source code of this project is licensed under the MIT license. This implies that
you are free to use, share, and adapt it. However, please give appropriate credit
by citing the project.

## Contact

If you have problems using the software, find mistakes, or have general questions please use
the [issue tracker](https://github.com/tknopp/RedPitayaDAQServer/issues) to contact us.

## Contributors

* [Tobias Knopp](https://www.tuhh.de/ibi/people/tobias-knopp-head-of-institute.html)
* [Niklas Hackelberg](https://www.tuhh.de/ibi/people/niklas-hackelberg.html)
* [Jonas Schumacher](https://www.imt.uni-luebeck.de/institute/staff/jonas-schumacher.html)
* [Matthias Gräser](https://www.tuhh.de/ibi/people/matthias-graeser.html)

## Credit

This package is partly based on work of Koheron [1] and Pavel Demin [2]

[1] https://www.koheron.com/blog/2016/11/29/red-pitaya-cluster
[2] https://github.com/pavel-demin/red-pitaya-notes
