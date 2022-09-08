`timescale 1ns / 1ps

module dds_bram_slice #
(
    parameter integer COUNTER_SIZE = 13
)
(
    input wire [47:0] s_axis_tdata_phase,
    input wire s_axis_tvalid_phase,
    input clk,
    input aresetn,
    output [COUNTER_SIZE-1:0] counter
);

reg [COUNTER_SIZE-1:0] temp;


always @(posedge clk)
begin 
    if (~aresetn)
    begin
        temp <= 0;
    end else begin
        temp <= (s_axis_tdata_phase >>> (47-COUNTER_SIZE));
    end
end

assign out = temp;


endmodule