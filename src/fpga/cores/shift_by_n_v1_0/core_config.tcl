set display_name {Shift to right by n}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

set_property VENDOR {jbeuke} $core
set_property VENDOR_DISPLAY_NAME {Jonas Beuke} $core
set_property COMPANY_URL {https://github.com/tknopp/RedPitayaDAQServer} $core

core_parameter N {N} {Number of bit positions to shift to the right.}
core_parameter INPUT_WIDTH {INPUT_WIDTH} {Width of the input.}
core_parameter OUTPUT_WIDTH {OUTPUT_WIDTH} {Width of the ouput.}
