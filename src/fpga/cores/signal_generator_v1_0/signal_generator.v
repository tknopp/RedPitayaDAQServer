`timescale 1ns / 1ps

module signal_generator #
(
    parameter integer AXIS_TDATA_WIDTH = 16,
    parameter integer AXIS_TDATA_PHASE_WIDTH = 32,
    parameter integer AXIS_TDATA_OUT_WIDTH = 32,
    parameter integer AMPLITUDE_WIDTH = 16,
    parameter integer DAC_WIDTH = 14,
    parameter integer CFG_DATA_WIDTH = 32
)
(
    // DDS Input
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_standard_A,
    input  wire [AXIS_TDATA_PHASE_WIDTH-1:0] phase_A,
    input  wire [AMPLITUDE_WIDTH-1:0] amplitude_A,
    input  wire s_axis_tvalid_standard_A,
    
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_standard_B,
    input  wire [AXIS_TDATA_PHASE_WIDTH-1:0] phase_B,
    input  wire [AMPLITUDE_WIDTH-1:0] amplitude_B,
    input  wire s_axis_tvalid_standard_B,

    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_rasterized_A,
    input  wire s_axis_tvalid_rasterized_A,
    
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_rasterized_B,
    input  wire s_axis_tvalid_rasterized_B,
    
    input [CFG_DATA_WIDTH-1:0] cfg_data,
    
    // Synthesized output
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                        	m_axis_tvalid,
    output wire [AXIS_TDATA_OUT_WIDTH-1:0] m_axis_tdata,
    
    input clk,
    input aresetn
);

    wire [3-1:0] signal_type_A;
    wire [3-1:0] signal_type_B;
    wire dac_mode_A;
    wire dac_mode_B;
	
    assign signal_type_A = cfg_data[2:0];
    assign signal_type_B = cfg_data[5:3];
    assign dac_mode_A = cfg_data[6:6];
    assign dac_mode_B = cfg_data[7:7];

    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out_A;
    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out_B;
	
    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            // Channel A
            if (signal_type_A == 0) // Sine
            begin
                if (dac_mode_A == 0)
                begin
                    dac_out_A <= s_axis_tdata_standard_A;
                end
                else
                begin
                    dac_out_A <= s_axis_tdata_rasterized_A;
                end
            end
            else if (signal_type_A == 1) // DC
            begin
                dac_out_A = amplitude_A;
            end
            else if (signal_type_A == 2) // Square wave
            begin
                if (phase_A < 0)
                begin
                    dac_out_A <= amplitude_A;
                end
                else
                begin
                    dac_out_A <= -amplitude_A;
                end
            end
            else if (signal_type_A == 3) // Triangle
            begin
                if (phase_A < 0)
                begin
                    dac_out_A <= phase_A;
                end
                else
                begin
                    dac_out_A <= -phase_A;
                end
            end
            else if (signal_type_A == 4) // Sawtooth
            begin
		        dac_out_A <= phase_A;
            end
            
            // Channel B
            if (signal_type_A == 0) // Sine
            begin
                if (dac_mode_A == 0)
                begin
                    dac_out_A <= s_axis_tdata_standard_A;
                end
                else
                begin
                    dac_out_A <= s_axis_tdata_rasterized_A;
                end
            end
            else if (signal_type_A == 1) // DC
            begin
                dac_out_A = amplitude_A;
            end
            else if (signal_type_A == 2) // Square wave
            begin
                if (phase_A < 0)
                begin
                    dac_out_A <= amplitude_A;
                end
                else
                begin
                    dac_out_A <= -amplitude_A;
                end
            end
            else if (signal_type_A == 3) // Triangle
            begin
                if (phase_A < 0)
                begin
                    dac_out_A <= phase_A;
                end
                else
                begin
                    dac_out_A <= -phase_A;
                end
            end
            else if (signal_type_A == 4) // Sawtooth
            begin
                dac_out_A <= phase_A;
            end
        end
        else
        begin
            dac_out_A <= 0;
            dac_out_B <= 0;
        end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = {dac_out_B, dac_out_A};

endmodule
