`timescale 1ns / 1ps

module sequence_stepper(
    input [63:0] writepointer,
    input [15:0] stepSize,
    input clk,
    input aresetn,
    output [31:0] step_counter 
);

reg [63:0] stepEnd, nextEnd;
reg [31:0] step_counter_reg, step_counter_next;

always @(posedge clk)
begin
    if (~aresetn) begin
        step_counter_reg <= 0;
        stepEnd <= stepSize;
    end else begin
        step_counter_reg <= step_counter_next;
        stepEnd <= nextEnd; 
    end
end

always @*
begin
    if (stepEnd < writepointer) begin
        nextEnd <= stepEnd + stepSize;
        step_counter_next <= step_counter_reg + 1;
    end else begin
        nextEnd <= nextEnd;
        step_counter_next <= step_counter_reg;
    end
end

assign step_counter = step_counter_reg;

endmodule
