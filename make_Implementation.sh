vivado -mode batch -source scripts/runSynthAndImpl.tcl
cp ./build/fpga/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bit ./bitfiles/master.bit