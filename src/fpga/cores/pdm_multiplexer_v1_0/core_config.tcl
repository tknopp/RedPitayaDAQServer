set display_name {PDM_Multiplexer}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

set_property VENDOR {matthiasgraeser} $core
set_property VENDOR_DISPLAY_NAME {Matthias Graeser} $core
set_property COMPANY_URL {http://github.com/tknopp/RedPitayaDAQServer} $core

core_parameter PDM_BUFFER_WIDTH {PDM BUFFER WIDTH} {WORD WIDTH OF THE PDM BUFFER}
core_parameter PDM_DATA_WIDTH {PDM DATA WIDTH} {WORD WIDTH OF ONE PDM DATA PACKAGE}
core_parameter PDM_BUFFER_ADRESS_WIDTH {PDM ADRESS WIDTH} {width of the adress. Should be ln2(pdm_buffer_with)}

