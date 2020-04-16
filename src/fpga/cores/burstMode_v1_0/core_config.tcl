set display_name {Burst Mode Breaker}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter CFG_DATA_WIDTH {CFG Data Width} {Counter Width for clk Sample Counter}


set_property VENDOR {Matthiasgraeser} $core
set_property VENDOR_DISPLAY_NAME {Matthias Graeser} $core
set_property COMPANY_URL {https://github.com/tknopp/RedPitayaDAQServer/} $core
