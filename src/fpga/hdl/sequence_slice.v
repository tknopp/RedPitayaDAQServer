`timescale 1ns / 1ps

module sequence_slice(
    input[127:0] seq_data,
    output signed [15:0] dac_value_0,
    output signed [15:0] dac_value_1,
    output [10:0] pdm_value_0,
    output [10:0] pdm_value_1,
    output [10:0] pdm_value_2,
    output [10:0] pdm_value_3,
    output [1:0] enable_dac,
    output [3:0] enable_pdm,
    output [1:0] enable_dac_ramp_down
    );

// Values
assign dac_value_0[15:0] = {{2{seq_data[13]}}, seq_data[13:0]};
assign dac_value_1[15:0] = {{2{seq_data[31]}}, seq_data[29:16]};

assign pdm_value_0[10:0] = seq_data[42:32];
assign pdm_value_1[10:0] = seq_data[58:48];
assign pdm_value_2[10:0] = seq_data[74:64];
assign pdm_value_3[10:0] = seq_data[90:80];

// Flags
assign enable_dac[1:0] = seq_data[97:96];
assign enable_pdm[3:0] = seq_data[101:98];
assign enable_dac_ramp_down[0] = seq_data[112];
assign enable_dac_ramp_down[1] = seq_data[113];

endmodule
