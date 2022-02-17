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
	reg signed [AXIS_TDATA_WIDTH-1:0] dac_out_temp_1;
	reg signed [AXIS_TDATA_WIDTH-1:0] dac_out_temp_2;
	reg signed [AXIS_TDATA_WIDTH-1:0] dac_out_temp_3;
	reg signed [AXIS_TDATA_WIDTH-1:0] dac_out_temp_4;
    reg signed [DAC_WIDTH-1:0] phase;
    reg signed [DAC_WIDTH-1:0] phase_delayed;
    reg signed [15:0] A, AIncrement;
    
    wire [4-1:0] trapezoidCond;
	reg [4-1:0] lastTrapezoidCond;
	
	assign trapezoidCond[0] = (phase > -8191+A);
	assign trapezoidCond[1] = (phase >= -A);
	assign trapezoidCond[2] = (phase > A);
	assign trapezoidCond[3] = (phase >= 8191-A);
	
	reg justChangedCond;

    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            dac_out <= 0;
            dac_out_temp_0 <= 0;
			dac_out_temp_1 <= -8191;
			dac_out_temp_2 <= 0;
			dac_out_temp_3 <= 8191;
			dac_out_temp_4 <= 0;
            phase <= 0;
            phase_delayed <= 0;
            A <= cfg_data[31:16];
            AIncrement <= cfg_data[47:32]; // 2*8191 / (2*A);
	        signal_type <= cfg_data[3:0];
	        lastTrapezoidCond <= 4'b0000;
			justChangedCond <= 0;
        end
        else
        begin
            phase <= (s_axis_tdata_phase >>> (AXIS_TDATA_PHASE_WIDTH-DAC_WIDTH));
            phase_delayed <= phase;
			
			if (lastTrapezoidCond != trapezoidCond)
			begin
				justChangedCond <= 1;
				lastTrapezoidCond <= trapezoidCond;
			end
			
			if (justChangedCond == 1)
			begin
				justChangedCond <= 0;
			end
            
            case (signal_type)
            	0 : begin // Sine
            	    dac_out_temp_0 <= s_axis_tdata;
                    dac_out <= dac_out_temp_0;
            	end
            	1 : begin // Trapezoid
            	    case ({justChangedCond, lastTrapezoidCond})
					5'b10000 : begin
						dac_out_temp_0 <= -8191-phase_delayed;
						dac_out <= AIncrement*dac_out_temp_4;
					end
					5'b00000 : begin
						dac_out_temp_0 <= -8191-phase_delayed;
						dac_out <= AIncrement*dac_out_temp_0;
					end
					5'b10001 : begin
						//dac_out_temp_1 <= -8191;
						dac_out <= AIncrement*dac_out_temp_0;
					end
					5'b00001 : begin
						//dac_out_temp_1 <= -8191;
						dac_out <= dac_out_temp_1;
					end
					5'b10011 : begin
						dac_out_temp_2 <= phase_delayed;
						dac_out <= dac_out_temp_1;
					end
					5'b00011 : begin
						dac_out_temp_2 <= phase_delayed;
						dac_out <= AIncrement*dac_out_temp_2;
					end
					5'b10111 : begin
						//dac_out_temp_3 <= 8191;
						dac_out <= AIncrement*dac_out_temp_2;
					end
					5'b00111 : begin
						//dac_out_temp_3 <= 8191;
						dac_out <= dac_out_temp_3;
					end
					5'b11111 : begin
						dac_out_temp_4 <= 8191-phase_delayed;
						dac_out <= dac_out_temp_3;
					end
					5'b01111 : begin
						dac_out_temp_4 <= 8191-phase_delayed;
						dac_out <= AIncrement*dac_out_temp_4;
					end
					default : begin
						dac_out <= 0;
					end
				    endcase
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
            	/*4 : begin // Sawtooth (reverse)
            	    dac_out_temp_0 <= -phase;
                    dac_out <= dac_out_temp_0;
            	end*/
            endcase
       end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = dac_out;

endmodule
