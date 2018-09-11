`timescale 1ns / 1ps

module signal_generator #
(
    parameter integer AXIS_TDATA_WIDTH = 16,
    parameter integer AXIS_TDATA_PHASE_STANDARD_WIDTH = 32,
    parameter integer AXIS_TDATA_PHASE_RASTERIZED_WIDTH = 16,
    parameter integer AXIS_TDATA_OUT_WIDTH = 32,
    parameter integer AMPLITUDE_WIDTH = 16,
    parameter integer DAC_WIDTH = 14,
    parameter integer CFG_DATA_WIDTH = 64
)
(
    // DDS Input
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_standard_A,
    input  wire s_axis_tvalid_standard_A,
    input  wire signed [AXIS_TDATA_PHASE_STANDARD_WIDTH-1:0] s_axis_tdata_phase_standard_A,
    input  wire s_axis_tvalid_phase_standard_A,
    input  wire [AMPLITUDE_WIDTH-1:0] amplitude_A,
    
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_standard_B,
    input  wire s_axis_tvalid_standard_B,
    input  wire signed [AXIS_TDATA_PHASE_STANDARD_WIDTH-1:0] s_axis_tdata_phase_standard_B,
    input  wire s_axis_tvalid_phase_standard_B,
    input  wire [AMPLITUDE_WIDTH-1:0] amplitude_B,

    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_rasterized_A,
    input  wire s_axis_tvalid_rasterized_A,
    input  wire [AXIS_TDATA_PHASE_RASTERIZED_WIDTH-1:0] s_axis_tdata_phase_rasterized_A,
    input  wire s_axis_tvalid_phase_rasterized_A,
    
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_rasterized_B,
    input  wire s_axis_tvalid_rasterized_B,
    input  wire [AXIS_TDATA_PHASE_RASTERIZED_WIDTH-1:0] s_axis_tdata_phase_rasterized_B,
    input  wire s_axis_tvalid_phase_rasterized_B,
    
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
    wire dc_sign_A;
    wire dc_sign_B;
	
    assign signal_type_A = cfg_data[2:0];
    assign signal_type_B = cfg_data[5:3];
    assign dac_mode_A = cfg_data[6];
    assign dac_mode_B = cfg_data[7];
    assign dc_sign_A = cfg_data[32];
    assign dc_sign_B = cfg_data[33];
    
    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out_A;
    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out_B;
    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out_temp_A;
    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out_temp_B;
    reg signed [DAC_WIDTH-1:0] phase_A;
    reg signed [DAC_WIDTH-1:0] phase_B;
    reg signed [DAC_WIDTH+AMPLITUDE_WIDTH-1:0] phase_times_amplitude_A;
    reg signed [DAC_WIDTH+AMPLITUDE_WIDTH-1:0] phase_times_amplitude_B;
	
    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            dac_out_A <= 0;
            dac_out_B <= 0;
            dac_out_temp_A <= 0;
            dac_out_temp_B <= 0;
            phase_A <= 0;
            phase_B <= 0;
            phase_times_amplitude_A <= 0;
            phase_times_amplitude_B <= 0;
        end
        else
        begin
            //// Channel A
            
            // Switch between standard and rasterized
            if (dac_mode_A == 0)
            begin
                phase_A <= (s_axis_tdata_phase_standard_A >>> (AXIS_TDATA_PHASE_STANDARD_WIDTH-DAC_WIDTH));
            end
            else
            begin
                phase_A <= (s_axis_tdata_phase_rasterized_A >>> (AXIS_TDATA_PHASE_RASTERIZED_WIDTH-DAC_WIDTH));
            end
                
            phase_times_amplitude_A <= phase_A*$signed({1'b0, amplitude_A});
            
            if (signal_type_A == 0) // Sine
            begin
                if (dac_mode_A == 0)
                begin
                    dac_out_temp_A <= s_axis_tdata_standard_A;
                end
                else
                begin
                    dac_out_temp_A <= s_axis_tdata_rasterized_A;
                end
                
                dac_out_A <= dac_out_temp_A;
            end
            else if (signal_type_A == 1) // DC
            begin
                if (dc_sign_A == 0)
                begin
                    dac_out_temp_A <= amplitude_A;
                end
                else
                begin
                    dac_out_temp_A <= ~amplitude_A+1;
                end
                
                dac_out_A <= dac_out_temp_A;
            end
            else if (signal_type_A == 2) // Square wave
            begin
                if (phase_A < 0)
                begin
                    dac_out_temp_A <= amplitude_A;
                end
                else
                begin
                    dac_out_temp_A <= ~amplitude_A+1;
                end
                
                dac_out_A <= dac_out_temp_A;
            end
            else if (signal_type_A == 3) // Triangle
            begin
                if (phase_A < 0)
                begin
                    dac_out_temp_A <= (phase_times_amplitude_A >>> (AMPLITUDE_WIDTH-4));
                    dac_out_A <= -dac_out_temp_A-$signed({1'b0, amplitude_A});
                end
                else
                begin
                    dac_out_temp_A <= (phase_times_amplitude_A >>> (AMPLITUDE_WIDTH-4));
                    dac_out_A <= dac_out_temp_A-$signed({1'b0, amplitude_A});
                end
            end
            else if (signal_type_A == 4) // Sawtooth
            begin
                dac_out_temp_A <= (phase_times_amplitude_A >>> (AMPLITUDE_WIDTH-3));
		        dac_out_A <= dac_out_temp_A;
            end
            
            
            //// Channel B
            
            // Switch between standard and rasterized
            if (dac_mode_B == 0)
            begin
                phase_B <= (s_axis_tdata_phase_standard_B >>> (AXIS_TDATA_PHASE_STANDARD_WIDTH-DAC_WIDTH));
            end
            else
            begin
                phase_B <= (s_axis_tdata_phase_rasterized_B >>> (AXIS_TDATA_PHASE_RASTERIZED_WIDTH-DAC_WIDTH));
            end
                
            phase_times_amplitude_B <= phase_B*$signed({1'b0, amplitude_B});
            
            if (signal_type_B == 0) // Sine
            begin
                if (dac_mode_B == 0)
                begin
                    dac_out_temp_B <= s_axis_tdata_standard_B;
                end
                else
                begin
                    dac_out_temp_B <= s_axis_tdata_rasterized_B;
                end
                
                dac_out_B <= dac_out_temp_B;
            end
            else if (signal_type_B == 1) // DC
            begin
                if (dc_sign_B == 0)
                begin
                    dac_out_temp_B <= amplitude_B;
                end
                else
                begin
                    dac_out_temp_B <= ~amplitude_B+1;
                end
                
                dac_out_B <= dac_out_temp_B;
            end
            else if (signal_type_B == 2) // Square wave
            begin
                if (phase_B < 0)
                begin
                    dac_out_temp_B <= amplitude_B;
                end
                else
                begin
                    dac_out_temp_B <= ~amplitude_B+1;
                end
                
                dac_out_B <= dac_out_temp_B;
            end
            else if (signal_type_B == 3) // Triangle
            begin
                if (phase_B < 0)
                begin
                    dac_out_temp_B <= (phase_times_amplitude_B >>> (AMPLITUDE_WIDTH-4));
                    dac_out_B <= -dac_out_temp_B-$signed({1'b0, amplitude_B});
                end
                else
                begin
                    dac_out_temp_B <= (phase_times_amplitude_B >>> (AMPLITUDE_WIDTH-4));
                    dac_out_B <= dac_out_temp_B-$signed({1'b0, amplitude_B});
                end
            end
            else if (signal_type_B == 4) // Sawtooth
            begin
                dac_out_temp_B <= (phase_times_amplitude_B >>> (AMPLITUDE_WIDTH-3));
                dac_out_B <= dac_out_temp_B;
            end
        end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = {dac_out_B, dac_out_A};

endmodule
