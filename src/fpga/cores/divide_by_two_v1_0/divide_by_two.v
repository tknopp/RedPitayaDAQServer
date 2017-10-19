`timescale 1ns / 1ps

module divide_by_two(
    input signed [15:0] input_vector,
    output signed [15:0] input_divided_by_two
);
    
assign input_divided_by_two = input_vector >>> 1;

endmodule
