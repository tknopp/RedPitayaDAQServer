set display_name {AXI4-Stream Select}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter AXIS_TDATA_WIDTH {AXIS_TDATA_WIDTH} {Width of the AXI data bus.}

set_property VENDOR {jbeuke} $core
set_property VENDOR_DISPLAY_NAME {Jonas Beuke} $core
set_property COMPANY_URL {https://github.com/tknopp/RedPitayaDAQServer} $core
