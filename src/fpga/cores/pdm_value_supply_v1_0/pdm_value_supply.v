`timescale 1ns / 1ps

module pdm_value_supply #
(
  parameter integer CFG_DATA_WIDTH = 16,
  parameter integer PDM_VALUE_WIDTH = 11
)
(
    // System signals
    input  wire                       aclk,
    input  wire                       aresetn,
    input  wire                       pdm_clk,
    
    // PDM data
    input wire [CFG_DATA_WIDTH-1:0] pdm_channel_1_nxt,
    input wire [CFG_DATA_WIDTH-1:0] pdm_channel_2_nxt,
    input wire [CFG_DATA_WIDTH-1:0] pdm_channel_3_nxt,
    input wire [CFG_DATA_WIDTH-1:0] pdm_channel_4_nxt,
    
    // Sampled PDM data
    output wire [PDM_VALUE_WIDTH-1:0] pdm_channel_1,
    output wire [PDM_VALUE_WIDTH-1:0] pdm_channel_2,
    output wire [PDM_VALUE_WIDTH-1:0] pdm_channel_3,
    output wire [PDM_VALUE_WIDTH-1:0] pdm_channel_4,
    
    output wire [4*CFG_DATA_WIDTH-1:0] pdm_sts
);

reg [PDM_VALUE_WIDTH-1:0] pdm_channel_1_int = 0;
reg [PDM_VALUE_WIDTH-1:0] pdm_channel_2_int = 0;
reg [PDM_VALUE_WIDTH-1:0] pdm_channel_3_int = 0;
reg [PDM_VALUE_WIDTH-1:0] pdm_channel_4_int = 0;

// Read and supply the pdm data
always @(posedge pdm_clk)
begin
    pdm_channel_1_int <= pdm_channel_1_nxt[PDM_VALUE_WIDTH-1:0];
    pdm_channel_2_int <= pdm_channel_2_nxt[PDM_VALUE_WIDTH-1:0];
    pdm_channel_3_int <= pdm_channel_3_nxt[PDM_VALUE_WIDTH-1:0];
    pdm_channel_4_int <= pdm_channel_4_nxt[PDM_VALUE_WIDTH-1:0];
end

assign pdm_channel_1 = pdm_channel_1_int;
assign pdm_channel_2 = pdm_channel_2_int;
assign pdm_channel_3 = pdm_channel_3_int;
assign pdm_channel_4 = pdm_channel_4_int;

assign pdm_sts = {pdm_channel_4_int, pdm_channel_3_int, pdm_channel_2_int, pdm_channel_1_int};

endmodule
