`timescale 1ns / 1ps

module sequence_stepper(
    input [63:0] writepointer,
    input [15:0] stepSize,
    input clk,
    input aresetn,
    output [31:0] step_counter 
);

reg [63:0] end_of_step, next_end_of_step;
reg [31:0] step_counter_reg, step_counter_next;

always @(posedge clk)
begin
    if (~aresetn) begin
        step_counter_reg <= 0;
        step_counter_next <= 0;
        end_of_step <= stepSize;
        next_end_of_step <= stepSize;
    end else begin
        step_counter_reg <= step_counter_next;
        end_of_step <= next_end_of_step;
        if (end_of_step < writepointer) begin
            next_end_of_step <= end_of_step + stepSize;
            step_counter_next <= step_counter_reg + 1;
        end else begin
            next_end_of_step <= next_end_of_step;
            step_counter_next <= step_counter_reg;
        end
    end
end

assign step_counter = step_counter_reg;

endmodule