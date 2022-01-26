module signal_generator #
(
    parameter integer AXIS_TDATA_WIDTH = 16,
    parameter integer AXIS_TDATA_PHASE_WIDTH = 16,
    parameter integer DAC_WIDTH = 14,
    parameter integer CFG_DATA_WIDTH = 64
)
(
    // Synthesized output
    output wire                        m_axis_tvalid,
    output wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    
    input clk,
    input aresetn
);

    reg [3:0] signal_type;
    
    reg [AXIS_TDATA_WIDTH-1:0] dac_out;
    reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp;
	reg [AXIS_TDATA_WIDTH-1:0] dac_out2;
    reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp2;
    reg signed [DAC_WIDTH-1:0] phase;
    reg signed [15:0] A, AIncrement;
	
	wire [4-1:0] trapezoidCond;
	
	assign trapezoidCond[0] = (phase > -8191+A);
	assign trapezoidCond[1] = (phase >= -A);
	assign trapezoidCond[2] = (phase >= A);
	assign trapezoidCond[3] = (phase >= 8191-A+2);
	
    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            dac_out <= 0;
            dac_out_temp <= 0;
            phase <= -8191;
            A <= 1638;
            AIncrement <= 5; // 2*8191 / (2*A);
			signal_type <= 1;
        end
        else
        begin
            phase <= phase+5;

            if (signal_type == 1) // Trapezoid
            begin
				case (trapezoidCond)
					4'b0000 : begin
						dac_out_temp <= AIncrement*(-8191-phase);
					end
					4'b0001 : begin
						dac_out_temp <= -8191;
					end
					4'b0011 : begin
						dac_out_temp <= AIncrement*phase;
					end
					4'b0111 : begin
						dac_out_temp <= 8191;
					end
					4'b1111 : begin
						dac_out_temp <= AIncrement*(8191-phase);
					end
					default : begin
						dac_out_temp <= 0;
					end
				endcase
				
				dac_out <= dac_out_temp;
			
                if (phase < -A && phase > -(8191-A))
                begin
                    dac_out_temp2 <= -8191;
                end
                else if (phase > A && phase < (8191-A) )
                begin
                    dac_out_temp2 <= 8191;
                end
                else if (phase <= A && phase >= -A)
                begin
                    dac_out_temp2 <= AIncrement*phase;
                end
                else if (phase <= -(8191-A) )
                begin
                    dac_out_temp2 <= -AIncrement*(phase+8191);
                end
                else if (phase >= (8191-A))
                begin
                    dac_out_temp2 <= AIncrement*(8191-phase);
                end
                
                dac_out2 <= dac_out_temp2;
			end
            else if (signal_type == 2) // Triangle
            begin
                if (phase <= -4095 )
                begin
                    dac_out_temp <= -2*(phase+8191);
                end
                else if (phase >= 4095)
                begin
                    dac_out_temp <= 2*(8191-phase);
	        end
		else 
                begin
                    dac_out_temp <= 2*phase;
                end
                
                dac_out <= dac_out_temp;
	    end
            if (signal_type == 3) // Sawtooth
            begin
                dac_out_temp <= phase;
                dac_out <= dac_out_temp;
            end
       end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = dac_out;

endmodule