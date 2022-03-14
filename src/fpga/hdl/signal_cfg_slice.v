`timescale 1ns / 1ps

module signal_cfg_slice(
    input [847:0] cfg_data,
    output [15:0] offset,
    output [15:0] comp_0_amp,
    output [63:0] comp_0_cfg,
    output [63:0] comp_0_freq,
    output [63:0] comp_0_phase,
    output [15:0] comp_1_amp,
    output [63:0] comp_1_cfg,
    output [63:0] comp_1_freq,
    output [63:0] comp_1_phase,
    output [15:0] comp_2_amp,
    output [63:0] comp_2_cfg,
    output [63:0] comp_2_freq,
    output [63:0] comp_2_phase,
    output [15:0] comp_3_amp,
    output [63:0] comp_3_cfg,
    output [63:0] comp_3_freq,
    output [63:0] comp_3_phase
    );

assign offset[15:0] = cfg_data[15:0];

assign comp_0_cfg[63:0] = cfg_data[79:16];
assign comp_0_amp[15:0] = cfg_data[95:80];
assign comp_0_freq[63:0] = cfg_data[159:96];
assign comp_0_phase[63:0] = cfg_data[223:160];

assign comp_1_cfg[63:0] = cfg_data[287:224];
assign comp_1_amp[15:0] = cfg_data[303:288];
assign comp_1_freq[63:0] = cfg_data[367:304];
assign comp_1_phase[63:0] = cfg_data[431:368];

assign comp_2_cfg[63:0] = cfg_data[495:432];
assign comp_2_amp[15:0] = cfg_data[511:496];
assign comp_2_freq[63:0] = cfg_data[575:512];
assign comp_2_phase[63:0] = cfg_data[639:576];

assign comp_3_cfg[63:0] = cfg_data[703:638];
assign comp_3_amp[15:0] = cfg_data[719:704];
assign comp_3_freq[63:0] = cfg_data[783:720];
assign comp_3_phase[63:0] = cfg_data[847:784];

endmodule
