set display_name {Sequence Bram Reader}

set core [ipx::current_core]

set_property DISPLAY_NAME $display_name $core
set_property DESCRIPTION $display_name $core

set_property VENDOR {mgraeser} $core
set_property VENDOR_DISPLAY_NAME {Matthias Graeser} $core
set_property COMPANY_URL {https://github.com/tknopp/RedPitayaDAQServer} $core

core_parameter BRAM_DATA_WIDTH {AXI DATA WIDTH} {Width of the BRAM data bus.}
core_parameter BRAM_ADDR_WIDTH {AXI ADDR WIDTH} {Width of the BRAM address bus.}
core_parameter STS_DATA_WIDTH {STS DATA WIDTH} {Width of the status data.}

set bus [ipx::add_bus_interface BRAM_PORTA $core]
set_property ABSTRACTION_TYPE_VLNV xilinx.com:interface:bram_rtl:1.0 $bus
set_property BUS_TYPE_VLNV xilinx.com:interface:bram:1.0 $bus
set_property INTERFACE_MODE master $bus
foreach {logical physical} {
  RST  bram_porta_rst
  CLK  bram_porta_clk
  ADDR bram_porta_addr
  DOUT bram_porta_rddata
} {
  set_property PHYSICAL_NAME $physical [ipx::add_port_map $logical $bus]
}

set bus [ipx::get_bus_interfaces bram_porta_clk]
set parameter [ipx::add_bus_parameter ASSOCIATED_BUSIF $bus]
set_property VALUE BRAM_PORTA $parameter