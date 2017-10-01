export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/RedPitayaDAQServer/build/lib

rm /var/log/daq_server.log

/root/RedPitayaDAQServer/build/server/daq_server >| /var/log/daq_server.log

exit 0
