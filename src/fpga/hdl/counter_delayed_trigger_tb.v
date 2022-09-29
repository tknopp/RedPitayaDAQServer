`timescale 1ns/1ns

module test;
  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #4 clk = !clk;
  
  reg aresetn = 0;
  reg enable = 1;
  reg arm = 0;
  reg trigger_reset = 0;
  reg counter_reset = 0;
  reg [32-1:0] presamples = 50;
  reg [32-1:0] reference_counter = 250;
  
  wire trigger;
  wire armed_status;
  wire [32-1:0] last_counter;
  
  initial begin
    $dumpfile("counter_delayed_trigger.vcd");
    $dumpvars(2, test);
    #  1000 counter_reset = 1;
    #   100 counter_reset = 0;
    #  3000 counter_reset = 1;
    #   100 counter_reset = 0;
    
    #   100 arm = 1;
    #    10 arm = 0;
    
    #  3000 counter_reset = 1;
    #   100 counter_reset = 0;
    
    #  1000 trigger_reset = 1;
    #    10 trigger_reset = 0;
    #   100 arm = 1;
    #    10 arm = 0;
    
    #  1000 enable = 0;
    
    #  3000 counter_reset = 1;
    #   100 counter_reset = 0;
    
    # 15000 aresetn = 1;
    
    # 20000 $finish;
  end
  
  counter_delayed_trigger cdt1 (clk, aresetn, enable, arm, trigger_reset, counter_reset, presamples, reference_counter, trigger, armed_status, last_counter);
endmodule // test