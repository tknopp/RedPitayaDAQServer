export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/root/RedPitayaDAQServer/build/lib

rm /var/log/daq_server.log

/root/apps/RedPitayaDAQServer/build/server/daq_server_scpi 

exit 0
