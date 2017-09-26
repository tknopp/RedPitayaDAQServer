set display_name {Fourier Synthesizer}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter N_MULTIPLICATIONS {N_MULTIPLICATIONS} {Number of multiplications needed.}
core_parameter N_ADDITIONS {N_ADDITIONS} {Number of additions needed.}
core_parameter AXIS_TDATA_WIDTH {AXIS_TDATA_WIDTH} {Width of the AXI data bus.}
core_parameter DAC_WIDTH {DAC_WIDTH} {Width of the output to the DAC.}
core_parameter CFG_DATA_WIDTH {AXIS_TDATA_WIDTH} {Width of the amplitude values.}

set_property VENDOR {jbeuke} $core
set_property VENDOR_DISPLAY_NAME {Jonas Beuke} $core
set_property COMPANY_URL {https://github.com/tknopp/RedPitayaDAQServer} $core
