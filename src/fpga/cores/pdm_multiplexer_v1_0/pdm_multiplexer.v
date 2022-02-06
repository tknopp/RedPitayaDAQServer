`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: University Medical Center Hamburg   
// Engineer: Matthias Gräser
// 
// Create Date: 20.03.2020 17:47:08
// Design Name: Multiplexer RedPitaya for PDM outputs
// Module Name: pdm_multiplexer_v1_0
// Project Name: RedpitayaDAQServer
// Target Devices: RedPitaya
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 1.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module pdm_multiplexer_v1_0 #
(
 parameter integer PDM_BUFFER_WIDTH=128,
 parameter integer PDM_DATA_WIDTH=64,
 parameter integer PDM_BUFFER_ADRESS_WIDTH=7
 )
(

input wire [(PDM_BUFFER_WIDTH*PDM_DATA_WIDTH)-1:0] pdm_data_in,
input wire [PDM_BUFFER_ADRESS_WIDTH-1:0] sample_select ,
output wire [PDM_DATA_WIDTH-1:0] pdm_data_out,

input clk,
input aresetn
);

    reg [PDM_DATA_WIDTH-1:0] pdm_data_out_reg;

    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            pdm_data_out_reg <= 0;
        end
        else
        begin
            pdm_data_out_reg <= pdm_data_in[(sample_select*64) +: 64];
        end
    end

    assign pdm_data_out = pdm_data_out_reg;

endmodule
