`timescale 1ns / 1ps

module clk_div 
#( 
parameter WIDTH = 17,
parameter N = 50,
parameter CONFIGURABLE = "FALSE",
parameter CFG_DATA_WIDTH= 32
)
(clk,reset, clk_out, cfg_data);
 //System Signals

  input clk;
  input reset;
  output clk_out;
 // Config input
  input  wire [CFG_DATA_WIDTH-1:0] cfg_data;

 //internal

  reg [WIDTH-1:0] r_reg;
  wire [WIDTH-1:0] r_nxt;
  reg clk_track;
  wire clk_int_unbuffered;
  wire clk_int_buffered;

BUFG div_clk_inst (.I(clk_int_unbuffered), .O(clk_int_buffered));
generate
    if(CONFIGURABLE == "TRUE")
    begin : CONFIGURABLE
     always @(posedge clk or posedge reset)
      begin
        if (reset)
           begin
              r_reg <= 0;
        clk_track <= 1'b0;
           end
        else if (r_nxt == cfg_data)
           begin
             r_reg <= 0;
             clk_track <= ~clk_track;
           end
       
        else 
            r_reg <= r_nxt;
      end
    end
    else
    begin : FIXED
      always @(posedge clk or posedge reset)
      begin
        if (reset)
           begin
              r_reg <= 0;
      	clk_track <= 1'b0;
           end
       
        else if (r_nxt == N)
       	   begin
      	     r_reg <= 0;
      	     clk_track <= ~clk_track;
      	   end
       
        else 
            r_reg <= r_nxt;
      end
    end
endgenerate

assign r_nxt = r_reg+1;
assign clk_int_unbuffered = clk_track;	      
assign clk_out = clk_int_buffered;

endmodule
