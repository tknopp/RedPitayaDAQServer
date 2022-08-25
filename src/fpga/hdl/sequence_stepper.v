`timescale 1ns / 1ps

module sequence_stepper(
    input [63:0] writepointer,
    input [15:0] stepSize,
    input clk,
    input aresetn,
    output [63:0] step_counter 
);

reg [63:0] writepointerBase;
reg [15:0] wpIncr;
reg [0:0] stepIncr;
reg [63:0] step_counter_reg;

always @(posedge clk)
begin
    if (~aresetn) begin
        step_counter_reg <= 0;
        writepointerBase <= 0;
    end else begin
        step_counter_reg <= step_counter_reg + stepIncr;
        writepointerBase <= writepointerBase + wpIncr; 
    end
end

always @*
begin
    if (writepointerBase + stepSize < writepointer) begin
        wpIncr <= stepSize;
        stepIncr <= 1;
    end else begin
        stepIncr <= 0;
        wpIncr <= 0;
    end
end

assign step_counter = step_counter_reg;

endmodule
