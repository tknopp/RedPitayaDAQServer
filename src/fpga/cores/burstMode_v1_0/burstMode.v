`timescale 1ns / 1ps

module BurstMode #
(
parameter integer CFG_DATA_WIDTH= 32
)
(
  // System signals
  input  wire                        clk,
  input  wire                        aresetn,

  // Slave side
  input wire [13:0] dac_data,
  input  wire [CFG_DATA_WIDTH-1:0] cfg_data,
  // Master side
  output wire [13:0] dac_out
);


 //internal

  reg [CFG_DATA_WIDTH-1:0] r_reg;
  wire [CFG_DATA_WIDTH-1:0] r_nxt;
  reg [13:0] dac_int;
     always @(posedge clk)
      begin
        if (~aresetn)
           begin
              r_reg <= 0;
              dac_int = 0;
           end
        else if (cfg_data==0) // continous mode!
          begin
            dac_int <= dac_data;
            r_reg <= 0;
          end
        else if (r_nxt > cfg_data)
           begin
            dac_int = 0;
           end
        else 
          begin
            r_reg <= r_nxt;
            dac_int <= dac_data;
          end
      end
 

assign r_nxt = r_reg+1;
assign dac_out = dac_int;

endmodule
