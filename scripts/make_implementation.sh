default_part="xc7z010clg400-1"
part=${1:=$default_part}

vivado -nolog -nojournal -mode batch -source scripts/runSynthAndImpl.tcl -tclargs ${part}
mkdir -p bitfiles
cp build/fpga/${part}/firmware/RedPitayaDAQServer.runs/impl_1/system_wrapper.bit bitfiles/daq_${part}.bit
