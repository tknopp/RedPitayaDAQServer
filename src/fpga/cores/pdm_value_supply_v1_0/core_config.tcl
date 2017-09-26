set display_name {PDM Value Supply}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter CFG_DATA_WIDTH {CFG_DATA_WIDTH} {Width of the input PDM values from the RAM.}
core_parameter PDM_VALUE_WIDTH {PDM_VALUE_WIDTH} {Width of the ouput PDM values.}

set_property VENDOR {jbeuke} $core
set_property VENDOR_DISPLAY_NAME {Jonas Beuke} $core
set_property COMPANY_URL {https://github.com/tknopp/RedPitayaDAQServer} $core
