`timescale 1ns / 1ps

module sequence_stepper(
    input [31:0] stepSize,
    input clk,
    input aresetn,
    output [31:0] step_counter 
);

reg [63:0] step_counter_local, step_counter_local_next;
reg [31:0] step_counter_reg, step_counter_next;
reg [31:0] step_size_local;

always @(posedge clk)
begin
    if (~aresetn) begin
        step_counter_reg <= 0;
        step_counter_next <= 0;
        step_counter_local <= 0;
        step_counter_local_next <= 0;
        step_size_local <= (stepSize>>1)-1;
    end else begin
        step_counter_reg <= step_counter_next;
        step_counter_local <= step_counter_local_next;
        if (step_counter_local == step_size_local) begin
            step_counter_local_next <= 0;
            step_counter_next <= step_counter_reg + 1;
        end else begin
            step_counter_local_next <= step_counter_local + 1;
            step_counter_next <= step_counter_reg;
        end
    end
end

assign step_counter = step_counter_reg;

endmodule
