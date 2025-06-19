`timescale 1ns / 1ps

module bypass_multiplexer #
(
    parameter integer DATA_WIDTH = 16
)
(
    input [DATA_WIDTH - 1:0] insignal0,
    input [DATA_WIDTH - 1:0] insignal1,
    output [DATA_WIDTH -1:0] outsignal,
    input idx,
    input clk,
    input aresetn
);

reg [DATA_WIDTH -1:0] signal;

always @(posedge clk)
begin
    if (~aresetn) begin
        signal <= 0;
    end else if (idx) begin
        signal <= insignal0;
    end else begin
        signal <= insignal1;
    end
end

assign outsignal = signal;

endmodule
