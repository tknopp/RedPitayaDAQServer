default_part="xc7z010clg400-1"
part=${1:=$default_part}

vivado -mode batch -source scripts/runSynthAndImpl.tcl ${part}
mkdir ../bitfiles
cp ../build/fpga/${part}/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bit ../bitfiles/daq_${part}.bit
