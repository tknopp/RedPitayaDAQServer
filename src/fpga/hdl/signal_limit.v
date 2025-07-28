`timescale 1ns / 1ps


module signal_limit(
    input clk,
    input signed [18:0] signal_in,
    input signed [15:0] limit_upper,
    input signed[15:0] limit_lower,
    output [15:0] limited_signal
    );
   
reg signed [15:0] signal_result;

always @(posedge clk)
begin
    if (signal_in > limit_upper) begin
        signal_result <= limit_upper;
    end else if (signal_in < limit_lower) begin
        signal_result <= limit_lower;
    end else begin
        signal_result <= signal_in[15:0];
    end
end

assign limited_signal = {{2{signal_result[15]}}, signal_result[15:2]};
endmodule
