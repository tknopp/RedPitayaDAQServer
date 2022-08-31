`timescale 1ns / 1ps

module signal_composer(
    input clk,
    input signed [15:0] wave0,
    input signed [15:0] wave1,
    input signed [15:0] wave2,
    input signed [15:0] wave3,
    input valid0,
    input valid1,
    input valid2,
    input valid3,
    input signed [15:0] offset,
    input signed [15:0] seq,
    input disable_dac,
    output signal_valid,
    output signed [15:0] signal_out
    );

reg signed [15:0] signal_int = 0;
reg signed [15:0] signal_temp0 = 0;
reg signed [15:0] signal_temp1 = 0;
reg signed [15:0] signal_temp2 = 0;
reg signed [15:0] signal_temp3 = 0;
reg signed [15:0] signal_temp4 = 0;
reg valid_int = 0;
reg valid_temp0 = 0;
reg valid_temp1 = 0;

always @(posedge clk)
begin
    signal_temp0 <= wave0 + wave1;
    signal_temp1 <= wave2 + wave3;
    valid_temp0 <= valid0 & valid1;
    valid_temp1 <= valid2 & valid3;
    signal_temp2 <= signal_temp0 + signal_temp1;
    signal_temp3 <= seq + offset; 
    if  (~disable_dac)
    begin
        signal_temp4 <= signal_temp2 + signal_temp3;
    end else begin
        signal_temp4 <= 0;
    end
    signal_int <= signal_temp4;
    valid_int <= valid_temp0 & valid_temp1;
end

assign signal_valid = valid_int;
assign signal_out = signal_int;

endmodule
