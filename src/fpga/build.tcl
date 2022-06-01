
################################################################
# This is the script for rebuilding the project.
# Please run the IP core generation first.
################################################################

if { $argc == 0 } {
	set part_name "xc7z010clg400-1"
} else {
	set part_name [lindex $argv 0]
}

# Create project
create_project RedPitayaDAQServer build/fpga/$part_name/firmware -part $part_name

# Suppress warnings for long filenames, since we are using Linux only
set_msg_config -id {BD 41-1753} -suppress

# Add HDL
add_files -scan_for_includes src/fpga/hdl

# Add constraints
add_files -fileset constrs_1 src/fpga/constraints/

# Import IPs
set_property ip_repo_paths build/fpga/$part_name/cores [current_project]
update_ip_catalog

# Recreate blockdesign
source src/fpga/bd/signal_calib.tcl
source src/fpga/bd/signal_ramp.tcl
source src/fpga/bd/waveform_gen.tcl
source src/fpga/bd/bd.tcl

# Create HDL wrapper for blockdesign
make_wrapper -files [get_files build/fpga/$part_name/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse build/fpga/$part_name/firmware/RedPitayaDAQServer.srcs/sources_1/bd/system/hdl/system_wrapper.v
update_compile_order -fileset sources_1

# Enable creation of .bin file
set_property STEPS.WRITE_BITSTREAM.ARGS.BIN_FILE true [get_runs impl_1]
