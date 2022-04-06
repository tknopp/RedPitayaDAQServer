`timescale 1ns / 1ps

module signal_composer(
    input clk,
    input [15:0] wave0,
    input [15:0] wave1,
    input [15:0] wave2,
    input [15:0] wave3,
    input valid0,
    input valid1,
    input valid2,
    input valid3,
    input [15:0] offset,
    input [15:0] seq,
    input dyn_offset_disable,
    input disable_dac,
    output signal_valid,
    output [15:0] signal_out
    );

reg [15:0] signal_int = 0;
reg valid_int = 0;

always @(posedge clk)
begin
    signal_int <= 0;
    if (~disable_dac)
    begin
        signal_int <= signal_int + wave0 + wave1 + wave2 + wave3;
        if (~dyn_offset_disable)
        begin
            signal_int <= signal_int + seq + offset;
        end
    end
    valid_int = valid0 & valid1 & valid2 & valid3;
end

assign signal_valid = valid_int;
assign signal_out = signal_int;

endmodule
