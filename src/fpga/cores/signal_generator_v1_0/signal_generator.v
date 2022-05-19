`timescale 1ns / 1ps

module signal_generator #
(
    parameter integer AXIS_TDATA_WIDTH = 16,
    parameter integer AXIS_TDATA_PHASE_WIDTH = 16,
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
    output wire                        m_axis_tvalid,
    output wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    
    input clk,
    input aresetn
);

    reg [3:0] signal_type;
    
    reg signed [AXIS_TDATA_WIDTH-1:0] dac_out;
    reg signed [AXIS_TDATA_WIDTH-1:0] dac_out_temp_0;
    reg signed [DAC_WIDTH-1:0] phase;

    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            dac_out <= 0;
            dac_out_temp_0 <= 0;
            phase <= 0;
	        signal_type <= cfg_data[3:0];
        end
        else
        begin
            phase <= (s_axis_tdata_phase >>> (AXIS_TDATA_PHASE_WIDTH-DAC_WIDTH));			
            
            case (signal_type)
            	0 : begin // Sine
            	    dac_out_temp_0 <= s_axis_tdata;
                    dac_out <= dac_out_temp_0;
            	end
            	1 : begin // Sawtooth (reverse)
            	    dac_out_temp_0 <= -phase;
                    dac_out <= dac_out_temp_0;
            	end
            	2 : begin // Triangle
            	    dac_out_temp_0 <= (phase << 1);
            	
					if (dac_out_temp_0 <= -8192)
					begin
						dac_out <= -dac_out_temp_0-16384;
					end
					else if (dac_out_temp_0 >= 8190)
					begin
						dac_out <= -dac_out_temp_0+16384;
					end
					else
					begin
						dac_out <= dac_out_temp_0;
					end
            	end
            	3 : begin // Sawtooth
            	    dac_out_temp_0 <= phase;
                    dac_out <= dac_out_temp_0;
            	end
            endcase
       end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = dac_out;

endmodule
