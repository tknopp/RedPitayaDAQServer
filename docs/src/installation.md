# Installation

## Alpine Linux Image

The RedPitayaDAQServer project uses a custom RedPitaya image that was derived from the [red-pitaya-notes](https://github.com/pavel-demin/red-pitaya-notes) project. It consists of an Alpine Linux with some development tools installed. Additionally the image reserves the upper 128 MB of main memory for the FPGA, which is used as a buffer for recording the data from the fast ADCs. The linux image can be downloaded [here](https://media.tuhh.de/ibi/2020.04RedPitayaDAQServerImage.zip). Just unzip the zip file and copy the content on an empty SD card that is formatted in FAT32. When you insert the SD card into the RedPitaya you should see a blinking LED.

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
