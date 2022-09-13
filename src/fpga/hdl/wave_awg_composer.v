`timescale 1ns / 1ps

module wave_awg_composer(
    input odd,
    input aclk,
    input aresetn,
    input [31:0] wave_in,
    output [15:0] wave_out
);

reg [15:0] wave_int;

always @(posedge aclk)
begin
    if (~aresetn)
    begin
        wave_int <= 0;
    end 
    else
    begin
        if (odd)
        begin
            wave_int <= wave_in[31:16];
        end else begin
            wave_int <= wave_in[15:0];
        end
    end
end

assign wave_out = wave_int;

endmodule