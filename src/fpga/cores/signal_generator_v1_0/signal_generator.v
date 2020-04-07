`timescale 1ns / 1ps

module signal_generator #
(
    parameter integer AXIS_TDATA_WIDTH = 16,
    parameter integer AXIS_TDATA_PHASE_WIDTH = 16,
    parameter integer AXIS_TDATA_OUT_WIDTH = 32,
    parameter integer DAC_WIDTH = 14,
    parameter integer CFG_DATA_WIDTH = 64
)
(
    // DDS Input
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
    input  wire s_axis_tvalid,
    input  wire [AXIS_TDATA_PHASE_WIDTH-1:0] s_axis_tdata_phase,
    input  wire s_axis_tvalid_phase,
    
    input [CFG_DATA_WIDTH-1:0] cfg_data,
    
    // Synthesized output
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                        	m_axis_tvalid,
    output wire [AXIS_TDATA_OUT_WIDTH-1:0] m_axis_tdata,
    
    input clk,
    input aresetn
);

    wire [3-1:0] signal_type;
    //wire dc_sign;
	
    assign signal_type = cfg_data[2:0];
    //assign dc_sign_A = cfg_data[3];
    
    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out;
    reg [AXIS_TDATA_OUT_WIDTH/2-1:0] dac_out_temp;
    reg signed [DAC_WIDTH-1:0] phase;
	
    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            dac_out <= 0;
            dac_out_temp <= 0;
            phase <= 0;
        end
        else
        begin

            phase <= (s_axis_tdata_phase >>> (AXIS_TDATA_PHASE_WIDTH-DAC_WIDTH));

            if (signal_type == 0) // Sine
            begin
                dac_out_temp <= s_axis_tdata;
                dac_out <= dac_out_temp;
            end
            else if (signal_type == 1) // Square wave
            begin
                if (phase < 0)
                begin
                    dac_out_temp <= ~0;
                end
                else
                begin
                    dac_out_temp <= 0;
                end
                
                dac_out <= dac_out_temp;
            end
        end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = dac_out;

endmodule
