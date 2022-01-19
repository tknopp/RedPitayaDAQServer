# Installation

## Alpine Linux Image

The RedPitayaDAQServer project uses a custom RedPitaya image that was derived from the [red-pitaya-notes](https://github.com/pavel-demin/red-pitaya-notes) project. It consists of an Alpine Linux with some development tools installed. Additionally the image reserves the upper 128 MB of main memory for the FPGA, which is used as a buffer for recording the data from the fast ADCs. The linux image can be downloaded [here](https://media.tuhh.de/ibi/2020.09RedPitayaDAQServerImage.zip). Just unzip the zip file and copy the content on an empty SD card that is formatted in FAT32. When you insert the SD card into the RedPitaya you should see a blinking LED.

## Setting Up the Server

Next you need to install the server application. To this end, connect the RedPitaya to you local network and access the device via ssh:
```
ssh root@rp-f?????.local
```
where ????? is the ID that is printed on the RedPitaya. The default password is `root`.
After logging into the RedPitaya go to the folder
```
/root/apps/
```
and clone the RedPitayaDAQServer project:
```
git clone https://github.com/tknopp/RedPitayaDAQServer
```
Sometimes you might need to make the file system writable by entering
```
mount -o remount,rw /dev/mmcblk0p1
```

Then cd into RedPitayaDAQServer
```
cd /root/apps/RedPitayaDAQServer
```
and enter `make`. This will compile the library, the server, and some example applications. After you restart the RedPitaya the DAQ server will automatically run and you can access it via TCP.


## Setting Up the Julia Client Library

For the Julia client library you need to install RedPitayaDAQServer within Julia. To this end
download Julia 1.5 or later and go into the package manager mode by intering ]. Then there are two
options to install the client library.

 * add RedPitayaDAQServer:src/client/julia
 * dev RedPitayaDAQServer:src/client/julia

The first is installing the currently published version. The second is installing in development mode and put the files to `~/dev/RedPitayaDAQServer/` where you can the also modify the files, which is handy when trying out the examples. Right now we recommend to `dev` the package. You need to `git pull` from `~/dev/RedPitayaDAQServer/` if you want to get updates, i.e. Julia will not update developed packages automatically.

The client library is not an executable data acquisition program, but it can be used to implement one. The library encapsulates the communication with the server and implements various optimizations. As the communication with the server is language agnostic and one could therefore implement their own client in a different language. The Julia reference client library found in `src/client/julia`, the [SCPI commands](scpi.md) and the sections on the signal [acquisition](acqusition.md) and [generation](generation.md) are starting points for such a custom client.d