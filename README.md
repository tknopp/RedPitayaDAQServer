# RedPitayaDAQServer
This project aims at combining several Red Pitayas into a synchronized data acquisition platform. The work of Koheron [1] has been extended to also synchronize the fast ADCs. With the help of some of Pavel Demin's work [2] a server provides access to the two fast ADCs and the two fast DACs as well as the four slow ADCs and four slow DACs. For usage as a signal generator for sensitive equipment, a watchdog mode and an instant stop trigger are provided.

Please see the wiki for further information on building, usage and specifications.

Since this is a project we use for our own purposes and provide it as a courtesy, we do not accept any liability for damages or injuries due to the usage of this project.

[1] https://www.koheron.com/blog/2016/11/29/red-pitaya-cluster
[2] https://github.com/pavel-demin/red-pitaya-notes

## Installing

Clone the code to the `/root` folder of each Red Pitaya. Currently some scripts use an absolute patch and therefore expect the repository to be cloned in that directory.

In order to build the project type `make` in `/root/RedPitayaDAQServer`

TODO

## Starting daq_server

The daq_server is best start the daq server type

```
export LD_LIBRARY_PATH=/root/RedPitayaDAQServer/build/lib
/root/RedPitayaDAQServer/build/server/daq_server
```

into the terminal. There is also a systemd service script that can be installed by executing

```
cp /root/RedPitayaDAQServer/scripts/daq_server.service /etc/systemd/system/
```

The daq_server can then be started using

```
systemctl start daq_server
```

To enable it at startup type

```
systemctl enable daq_server
```

## DAQ server

TODO
