# Development Tips

On this slide some development hints are summarized. These might change regularely if things
are properly integrated into the framework.

## Alpine Linux

* The Alpine linux as currently a root folder with only 185.8M free space, which disallows installing more
applications. To change this one can do
```
mount -o remount,size=1G /
```
* Right now no debugger is installed. This can be change after increasing / using:
```
apk add gdb
```

## DHCP Server

One possible configuration to run single or a cluster of RedPitayas is to directly connect them with the measurement computer. In case of a cluster one can use a switch such that only a single network connector is required. In case that the measurement computer has no free ethernet port one can use a USB network adapter.

In order to get this setup running you need to install a dhcp server and give the measurement computer a static IP address (e.g. 192.168.1.1). Then you can configure the dhcp server by modifying the configuration file /etc/dhcp/dhcpd.conf where you should create a network with a certain range (e.g. 192.168.1.100-105). You also have the opportunity to map a certain RedPitaya to a certain IP address by specifying the MAC address. You may also need to specify DNS servers.

The following commands are useful when you have connection problems
```
nmap -sP 192.168.1.0/24 
journalctl -f -u isc-dhcp-server
```
If you need internet at your RedPitaya you need to configure the firewall to allow this using iptables. In this repository there is in the `scripts` directory a script `rp-internet.sh` where you need to change the network adapters to allow traffic going from the internet network adapter to the RedPitaya network adapter.