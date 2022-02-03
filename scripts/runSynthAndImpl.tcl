if { $argc == 0 } {
	set part_name "xc7z010clg400-1"
} else {
	set part_name [lindex $argv 0]
}

open_project ../build/fpga/$part_name/firmware/RedPitayaDAQServer.xpr
reset_run synth_1
launch_runs synth_1 -jobs 2
wait_on_run synth_1
launch_runs impl_1 -jobs 2
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs 2
wait_on_run impl_1
close_project
exit
