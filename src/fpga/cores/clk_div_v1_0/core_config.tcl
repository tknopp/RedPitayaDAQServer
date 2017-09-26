set display_name {Clock Divider}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

core_parameter WIDTH {WIDTH} {Required width of the register.}
core_parameter N {N} {Divider/2.}

set_property VENDOR {referencedesigner.com} $core
set_property VENDOR_DISPLAY_NAME {referencedesigner.com} $core
set_property COMPANY_URL {http://www.referencedesigner.com/tutorials/verilogexamples/verilog_ex_04.php} $core
