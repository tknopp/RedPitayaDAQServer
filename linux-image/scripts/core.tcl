
set core_name [lindex $argv 0]

set part_name [lindex $argv 1]

set build_dir "build/linux-image"

set elements [split $core_name _]
set project_name [join [lrange $elements 0 end-2] _]
set version [string trimleft [join [lrange $elements end-1 end] .] v]

file delete -force $build_dir/tmp/cores/$core_name $build_dir/tmp/cores/$project_name.cache $build_dir/tmp/cores/$project_name.hw $build_dir/tmp/cores/$project_name.xpr $build_dir/tmp/cores/$project_name.ip_user_files

create_project -part $part_name $project_name $build_dir/tmp/cores

add_files -norecurse [glob linux-image/cores/$core_name/*.v]

ipx::package_project -import_files -root_dir $build_dir/tmp/cores/$core_name

set core [ipx::current_core]

set_property VERSION $version $core
set_property NAME $project_name $core
set_property LIBRARY {user} $core
set_property VENDOR {pavel-demin} $core
set_property VENDOR_DISPLAY_NAME {Pavel Demin} $core
set_property COMPANY_URL {https://github.com/pavel-demin/red-pitaya-notes} $core
set_property SUPPORTED_FAMILIES {zynq Production} $core

proc core_parameter {name display_name description} {
  set core [ipx::current_core]

  set parameter [ipx::get_user_parameters $name -of_objects $core]
  set_property DISPLAY_NAME $display_name $parameter
  set_property DESCRIPTION $description $parameter

  set parameter [ipgui::get_guiparamspec -name $name -component $core]
  set_property DISPLAY_NAME $display_name $parameter
  set_property TOOLTIP $description $parameter
}

source linux-image/cores/$core_name/core_config.tcl

rename core_parameter {}

ipx::create_xgui_files $core
ipx::update_checksums $core
ipx::save_core $core

close_project
