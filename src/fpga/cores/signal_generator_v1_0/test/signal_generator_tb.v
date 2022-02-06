`timescale 1ns/1ns

module test;
  parameter integer AXIS_TDATA_WIDTH = 16;
  parameter integer AXIS_TDATA_PHASE_WIDTH = 16;
  parameter integer DAC_WIDTH = 14;
  parameter integer CFG_DATA_WIDTH = 64;

  /* Make a reset that pulses once. */
  reg aresetn = 0;
  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #4 clk = !clk;
  
  wire                        m_axis_tvalid;
  wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata;
  
  initial begin
	$dumpfile("signal_generator.vcd");
	$dumpvars(2, test);
     # 11 aresetn = 1;
     # 20000 $finish;
  end
  
  signal_generator sg1 (m_axis_tvalid, m_axis_tdata, clk, aresetn);
endmodule // test