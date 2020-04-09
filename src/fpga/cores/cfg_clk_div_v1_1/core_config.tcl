set display_name {CFG Clock Divider}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter WIDTH {WIDTH} {Required width of the register.}
core_parameter N {N} {Divider/2.}
core_parameter CONFIGURABLE {CONFIGURABLE} {Define if the cfg port or the N Parameter is taken}
core_parameter CFG_DATA_WIDTH {CFG Data Width} {CFG Data Width}


set_property VENDOR {referencedesigner.com} $core
set_property VENDOR_DISPLAY_NAME {referencedesigner.com} $core
set_property COMPANY_URL {http://www.referencedesigner.com/tutorials/verilogexamples/verilog_ex_04.php} $core
