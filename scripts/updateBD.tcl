
open_project ./build/fpga/firmware/RedPitayaDAQServer.xpr
remove_files  ./build/fpga/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system/hdl/system_wrapper.v
file delete -force ./build/fpga/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system/hdl/system_wrapper.v
remove_files  ./build/fpga/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system/system.bd
file delete -force ./build/fpga/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system
source src/fpga/bd/bd.tcl
make_wrapper -files [get_files build/fpga/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse build/fpga/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system/hdl/system_wrapper.v
update_compile_order -fileset sources_1
close_project
exit