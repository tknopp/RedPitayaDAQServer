set display_name {Signal Generator}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter AXIS_TDATA_WIDTH {AXIS_TDATA_WIDTH} {Width of the AXI data bus.}
core_parameter AXIS_TDATA_PHASE_WIDTH {AXIS_TDATA_PHASE_WIDTH} {Width of the phase data.}
core_parameter AXIS_TDATA_OUT_WIDTH {AXIS_TDATA_OUT_WIDTH} {Width of the output AXI data bus.}
core_parameter AMPLITUDE_WIDTH {AMPLITUDE_WIDTH} {Width of the signal amplitude.}
core_parameter DAC_WIDTH {DAC_WIDTH} {Width of a single DAC channel.}
core_parameter CFG_DATA_WIDTH {CFG_DATA_WIDTH} {Width of the configuration data.}

set_property VENDOR {jbeuke} $core
set_property VENDOR_DISPLAY_NAME {Jonas Beuke} $core
set_property COMPANY_URL {https://github.com/tknopp/RedPitayaDAQServer} $core
