`timescale 1ns / 1ps

module sequence_slice(
    input clk,
    input aresetn,
    input[127:0] seq_data,
    output signed [15:0] dac_value_0,
    output signed [15:0] dac_value_1,
    output [10:0] pdm_value_0,
    output [10:0] pdm_value_1,
    output [10:0] pdm_value_2,
    output [10:0] pdm_value_3,
    output [1:0] enable_dac,
    output [1:0] resync_dac,
    output [3:0] enable_pdm,
    output [1:0] enable_dac_ramp_down
);

reg [127:0] seq_data_int;
    
always @(posedge clk)
begin
    if (~aresetn)
    begin 
        seq_data_int <= 0;
    end
    else
    begin
        seq_data_int <= seq_data;
    end
end

// Values
assign dac_value_0[15:0] = {{2{seq_data_int[13]}}, seq_data_int[13:0]};
assign dac_value_1[15:0] = {{2{seq_data_int[31]}}, seq_data_int[29:16]};

assign pdm_value_0[10:0] = seq_data_int[42:32];
assign pdm_value_1[10:0] = seq_data_int[58:48];
assign pdm_value_2[10:0] = seq_data_int[74:64];
assign pdm_value_3[10:0] = seq_data_int[90:80];

// Flags
assign enable_dac[1:0] = seq_data_int[97:96];
assign enable_pdm[3:0] = seq_data_int[101:98];
assign resync_dac[0] = seq_data_int[14];
assign resync_dac[1] = seq_data_int[30];
assign enable_dac_ramp_down[0] = seq_data_int[112];
assign enable_dac_ramp_down[1] = seq_data_int[113];

endmodule