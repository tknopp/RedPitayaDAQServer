
set project_name [lindex $argv 0]

open_project build/linux-image/tmp/$project_name.xpr

write_hw_platform -fixed -force -file build/linux-image/tmp/$project_name.xsa

close_project
