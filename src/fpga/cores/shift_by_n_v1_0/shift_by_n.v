`timescale 1ns / 1ps

module shift_by_n #
(
    parameter integer N = 1,
    parameter integer INPUT_WIDTH = 16,
    parameter integer OUTPUT_WIDTH = 16
)
(
    input signed [INPUT_WIDTH-1:0] input_vector,
    output signed [OUTPUT_WIDTH-1:0] input_shifted_by_n
);
    
assign input_shifted_by_n = input_vector >>> N;

endmodule
