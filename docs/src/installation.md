# Installation
The RedPitayaDAQServer project uses a custom RedPitaya image that was derived from the [red-pitaya-notes](https://github.com/pavel-demin/red-pitaya-notes) project. It consists of an Alpine Linux with some development tools installed, as well as the server and the FPGA images. The Linux image reserves the upper 128 MB of main memory for the FPGA, which is used as a buffer for recording the data from the ADCs. The latest releases of the project can be downloaded [here](https://github.com/tknopp/RedPitayaDAQServer/releases).

To install the project on a RedPitaya, format an SD card in FAT32 and enable the bootable flag. On Linux this can be done with:
```
sudo fdisk /dev/sdb
```
on the correct device. In the prompt create a new partition with `n` and change its type to FAT32 with the `t` command and the hex code `b`. With the command `a` the bootable flag can be toggled. Finish formatting with the `w` command.

Afterwards a file system can be created with:
```
sudo mkfs -t vfat /dev/sdb1
```
To finish installing the RedPitaya, simply unzip one of the releases and copy the files into the now empty and formatted SD card.

When the RedPitaya is now booted, the server should start. One can then use a client to connect, at which point the FPGA image is loaded. 

The client library provided with the project is not an executable program, but it can be used to implement one. The library encapsulates the communication with the server and implements various optimizations. As the communication with the server is language agnostic one could therefore implement their own client in a different language. The Julia reference client library found in `src/client/julia`, the [SCPI commands](scpi.md) and the sections on the signal [acquisition](acqusition.md) and [generation](generation.md) are starting points for such a custom client.

## Julia Client
To use the provided Julia client library you need to install RedPitayaDAQServer Julia package within Julia. To this end 
download Julia 1.5 or later and go into the package manager mode by intering `]`.
Then with 
```
add RedPitayaDAQServer
```
the latest release of the Julia client is added. To install a different version, please consult the [Pkg documentation](https://pkgdocs.julialang.org/dev/managing-packages/#Adding-packages). The Julia client and the RedPitaya image should be from the same release to avoid errors due to communication protocol changes.

To try out the Julia examples one can either download them from Github directly, clone the whole repository or use the alternative way of installing Julia packages described [here](installation.md#julia-client-library).
# Updating
The Julia client offers function to automatically update the server and FPGA of a RedPitaya. More on this can be found [here](client.md#utility). Note that this process deletes all data in the `RedPitayaDAQServer` folder on the RedPitaya.
# Network Connection
The system as provided here should not be made accessible from the internet since it uses a default public password and ssh-key.

One possible configuration to run single or a cluster of RedPitayas is to directly connect them with the measurement computer. In case of a cluster one can use a switch such that only a single network connector is required. In case that the measurement computer has no free ethernet port one can use a USB network adapter.


In order to get this setup running you need to install a dhcp server on the measurement computer, such as `dhcpd`, and give the measurement computer a static IP address (e.g. 192.168.1.1). This can be installed with 
```
sudo apt-get install isc-dhcp-server
```

One can then edit the `/etc/dhcp/dhcpd.conf` configuration file with a setup similar to the following example:
```
subnet 192.168.1.0 netmask 255.255.255.0 {
        interface ????;

        #range dynamic-bootp 192.168.1.100 192.168.1.102;
        option broadcast-address 192.168.1.255;
        option routers 192.168.1.1;

        host rp1 {
                hardware ethernet 00:26:32:F0:70:83;
                fixed-address 192.168.1.100;
        }

        host rp2 {
                hardware ethernet 00:26:32:F0:92:97;
                fixed-address 192.168.1.101;
        }

        host rp3 {
                hardware ethernet 00:26:32:F0:61:F5;
                fixed-address 192.168.1.102;
        }
}
```
The example defines three fixed IP addresses for three RedPitayas based on their MAC addresses. You may also need to specify DNS servers or alternatively create a network with a range of IPs (e.g. 192.168.1.100-105).

Afterwards with
```
service isc-dhcp-server start
```
or 
```
service isc-dhcp-server restart 
```
one can start the DHCP service and should see the RedPitayas using the DHCP protocol to get their IP addresses with:
```
journalctl -f -u isc-dhcp-server
```
This displays the latest log messages of the DHCP service. 

If you need internet at your RedPitaya you need to configure the firewall to allow this using iptables. In this repository there is in the `scripts` directory a script `rp-internet.sh` where you need to change the network adapters to allow traffic going from the internet network adapter to the RedPitaya network adapter.
# Building Components

## Linux Image and FPGA Images
If you want to build the Linux image or the FPGA bitfiles yourself, you can install Xilinx Vitis and Vivado (2021.2) in an Ubuntu environment (bare metal or virtual machine). Then run

```
sudo apt-get update

sudo apt-get --no-install-recommends install \
  build-essential bison flex git curl ca-certificates sudo \
  xvfb fontconfig libxrender1 libxtst6 libxi6 make \
  bc u-boot-tools device-tree-compiler libncurses5-dev \
  libssl-dev qemu-user-static binfmt-support zip \
  squashfs-tools dosfstools parted debootstrap zerofree
```

in order to get the essential tools. Afterwards clone the project with

```
git clone https://github.com/tknopp/RedPitayaDAQServer
```

Then switch into this directory. You can build the whole project using
```
make all
```

With 
```
make daq_bitfiles
```
one can build both the 7010 and the 7020 versions of the FPGA image. For different build targets consult the Makefiles.

Note: `make` has to be run as root if you want to build the Linux image, since `chroot` requires `root` privileges.

## Server

To build the RedPitaya server connect the RedPitaya to your local network and access the device via ssh:
```
ssh root@rp-f?????.local
```
where ????? is the ID that is printed on the RedPitaya. The default password is `root`.
After logging into the RedPitaya go to the folder
```
/root/apps/
```
and clone the RedPitayaDAQServer project if it does not exist already:
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
and enter `make server`. This will compile the library, the server, and some example applications. After you restart the RedPitaya the DAQ server will automatically run and you can access it via TCP.
## Developing Julia Client Library
Another option when installing the Julia client is to add the package with the  `dev` command:
```
dev RedPitayaDAQServer
```
in the package mode `]`.

This installs the package in development mode and puts the files into `~/.julia/dev/RedPitayaDAQServer/`. There you can the also modify the files, which is handy when trying out the examples. You need to manually `git pull` if you want to get updates, i.e. Julia will not update developed packages automatically.