`timescale 1 ns / 1 ps

module sequence_bram_reader #
(
  parameter integer BRAM_DATA_WIDTH = 32,
  parameter integer BRAM_ADDR_WIDTH = 10,
  parameter integer STS_DATA_WIDTH =10
)
(
  // System signals
  input  wire                       aclk,
  input  wire                       aresetn,
  input wire 						updateclk,
 
 // BRAM port
  output wire                       bram_porta_clk,
  output wire                       bram_porta_rst,
  output wire [BRAM_ADDR_WIDTH-1:0] bram_porta_addr,
  input  wire [BRAM_DATA_WIDTH-1:0] bram_porta_rddata,

  //STS input
  input wire [STS_DATA_WIDTH-1:0] sts_data,
  //OUTPUT DATA
  output wire [BRAM_DATA_WIDTH-1:0] sequence_data,
  output wire [BRAM_DATA_WIDTH-1:0] sequence_data_next
  );


reg [BRAM_ADDR_WIDTH-1:0] bram_porta_addr_reg, bram_porta_addr_next;
reg [BRAM_DATA_WIDTH-1:0] int_bram_rdata_reg,int_bram_rdata_reg_next;
reg [STS_DATA_WIDTH-1:0] int_sts_reg,int_sts_next;


   always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      bram_porta_addr_reg <= {(BRAM_ADDR_WIDTH){1'b0}};
      int_bram_rdata_reg <= {(BRAM_DATA_WIDTH){1'b0}};
      int_bram_rdata_reg_next <= {(BRAM_DATA_WIDTH){1'b0}};
      int_sts_reg <= {(STS_DATA_WIDTH){1'b0}};
    end
    else
    begin
      bram_porta_addr_reg <= bram_porta_addr_next;
      int_bram_rdata_reg <= int_bram_rdata_reg_next;
      int_bram_rdata_reg_next <= bram_porta_rddata;
      int_sts_reg <= int_sts_next;
    end
  end 


  always @ (posedge updateclk)
  begin
    		bram_porta_addr_next = sts_data;
  end

    assign bram_porta_addr = bram_porta_addr_reg;
 	assign bram_porta_clk = aclk;
    assign bram_porta_rst = ~aresetn;
    assign sequence_data_next = int_bram_rdata_reg_next;
    assign sequence_data = int_bram_rdata_reg;


endmodule
