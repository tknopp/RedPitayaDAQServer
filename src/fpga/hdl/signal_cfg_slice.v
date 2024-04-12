`timescale 1ns / 1ps

module signal_cfg_slice(
    input [831:0] cfg_data,
    output [47:0] ramp_freq,
    output [15:0] offset,
    output [15:0] calib_scale,
    output [15:0] calib_offset,
    output [15:0] calib_limit_lower,
    output [15:0] calib_limit_upper,
    output [47:0] comp_0_cfg,
    output [15:0] comp_0_amp,
    output [47:0] comp_0_freq,
    output [47:0] comp_0_phase,
    output [47:0] comp_1_cfg,
    output [15:0] comp_1_amp,
    output [47:0] comp_1_freq,
    output [47:0] comp_1_phase,
    output [47:0] comp_2_cfg,
    output [15:0] comp_2_amp,
    output [47:0] comp_2_freq,
    output [47:0] comp_2_phase,
    output [47:0] comp_3_cfg,
    output [15:0] comp_3_amp,
    output [47:0] comp_3_freq,
    output [47:0] comp_3_phase
    );

assign ramp_freq[47:0] = cfg_data[47:0];
assign offset[15:0] = cfg_data[63:48];

// 0 bit gap
assign comp_0_cfg[47:0] = cfg_data[111:64];
assign comp_0_amp[15:0] = cfg_data[127:112];
assign comp_0_freq[47:0] = cfg_data[175:128];
assign calib_scale[15:0] = cfg_data[191:176];
assign comp_0_phase[47:0] = cfg_data[239:192];
assign calib_offset[15:0] = cfg_data[255:240];

// 0 bit gap
assign comp_1_cfg[47:0] = cfg_data[303:256];
assign comp_1_amp[15:0] = cfg_data[319:304];
assign comp_1_freq[47:0] = cfg_data[367:320];
assign calib_limit_lower[15:0] = cfg_data[383:368];
assign comp_1_phase[47:0] = cfg_data[431:384];
assign calib_limit_upper[15:0] = cfg_data[447:432];

// 0 bit gap
assign comp_2_cfg[47:0] = cfg_data[495:448];
assign comp_2_amp[15:0] = cfg_data[511:496];
assign comp_2_freq[47:0] = cfg_data[559:512];
// 15 bit gap
assign comp_2_phase[47:0] = cfg_data[623:576];

// 15 bit gap
assign comp_3_cfg[47:0] = cfg_data[687:640];
assign comp_3_amp[15:0] = cfg_data[703:688];
assign comp_3_freq[47:0] = cfg_data[751:704];
// 15 bit gap
assign comp_3_phase[47:0] = cfg_data[815:768];

endmodule