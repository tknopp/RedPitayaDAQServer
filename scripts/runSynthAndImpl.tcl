if { $argc == 0 } {
    set part_name "xc7z010clg400-1"
} else {
    set part_name [lindex $argv 0]
}

if {![catch {open "/proc/cpuinfo"} f]} {
    set cores [regexp -all -line {^processor\s} [read $f]]
    close $f
} else {
    set cores 2
}
puts "Running with $cores jobs"

open_project "build/fpga/$part_name/firmware/RedPitayaDAQServer.xpr"
reset_run synth_1
launch_runs synth_1 -jobs ${cores}
wait_on_run synth_1
launch_runs impl_1 -jobs ${cores}
wait_on_run impl_1
launch_runs impl_1 -to_step write_bitstream -jobs ${cores}
wait_on_run impl_1
close_project
exit
