`timescale 1ns / 1ps

module sequence_stepper(
    input [63:0] writePointer,
    input [31:0] stepSize,
    input clk,
    input aresetn,
    output [31:0] seq_counter
);

reg [31:0] stepSize_int;
reg [31:0] seq_counter_state;
reg [31:0] sample_counter;
reg wp_prev, wp_next;

always @(posedge clk)
begin
    stepSize_int <= stepSize;
    wp_next <= writePointer[0];
    if (~aresetn) begin
        seq_counter_state <= 0;
        sample_counter <= stepSize_int;
        wp_prev <= 0;
    end else begin
        wp_prev <= wp_next;
        if (wp_prev != wp_next) begin
        
            if (sample_counter == 0) begin
                sample_counter <= stepSize_int;
                seq_counter_state <= seq_counter_state + 1;
            end else begin
                sample_counter <= sample_counter - 1;
                seq_counter_state <= seq_counter_state;
            end
        
        end else begin
            sample_counter <= sample_counter;
            seq_counter_state <= seq_counter_state;
        end
    end
end

assign seq_counter = seq_counter_state;

endmodule
