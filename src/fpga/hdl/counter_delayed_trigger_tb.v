`timescale 1ns/1ns

module test;
  localparam integer TRIGGER_COUNTER_WIDTH = 32;
	localparam integer TRIGGER_PRESAMPLES_WIDTH = 32;
  localparam integer ADC_WIDTH = 16;

  /* Make a regular pulsing clock. */
  reg clk = 0;
  always #4 clk = !clk;
  
  reg aresetn = 0;
  reg enable = 1;
  reg arm = 0;
  reg trigger_reset = 0;
  reg [8-1:0] dios = 0;
	reg [ADC_WIDTH-1:0] adc0 = 0;
	reg [ADC_WIDTH-1:0] adc1 = 0;
	reg [5-1:0] source_select = 0;
  reg [TRIGGER_PRESAMPLES_WIDTH-1:0] presamples = 50;
  reg [TRIGGER_COUNTER_WIDTH-1:0] reference_counter = 250;
  
  wire trigger;
  wire armed_status;
  wire [TRIGGER_COUNTER_WIDTH-1:0] last_counter;

  always #4 adc0 = adc0+100;
  always #4 adc1 = adc1+300;
  
  initial begin
    $dumpfile("counter_delayed_trigger.vcd");
    $dumpvars(2, test);
    #  1000 dios[0] = 1;
    #   100 dios[0] = 0;
    #  3000 dios[0] = 1;
    #   100 dios[0] = 0;
    
    #   100 arm = 1;
    #    10 arm = 0;
    
    #  3000 dios[0] = 1;
    #   100 dios[0] = 0;
    
    #  1000 trigger_reset = 1;
    #    10 trigger_reset = 0;
    #   100 arm = 1;
    #    10 arm = 0;
    
    #  1000 enable = 0;
    
    #  3000 dios[0] = 1;
    #   100 dios[0] = 0;

    #  1000 source_select[4] = 1;
    #    10 enable = 1;

    #   100 arm = 1;
    #    10 arm = 0;

    # 10000 enable = 0;
    
    # 15000 aresetn = 1;
    
    # 200000 $finish;
  end
  
  counter_delayed_trigger cdt1 (clk, aresetn, enable, arm, trigger_reset, dios, adc0, adc1, source_select, presamples, reference_counter, trigger, armed_status, last_counter);
endmodule // test