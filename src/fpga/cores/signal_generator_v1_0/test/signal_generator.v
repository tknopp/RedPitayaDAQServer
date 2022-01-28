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
    reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp_0;
	reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp_1;
	reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp_2;
	reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp_3;
	reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp_4;
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
	
	// Reference
	reg [AXIS_TDATA_WIDTH-1:0] dac_out2;
    reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp2;
	reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp2_delayed;
	reg [AXIS_TDATA_WIDTH-1:0] dac_out_temp2_delayed2;
	
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
            phase <= -8191;
			phase_delayed <= -8191;
            A <= 80;
            AIncrement <= 100; // 2*8191 / (2*A);
			signal_type <= 1;
			lastTrapezoidCond <= 4'b0000;
			justChangedCond <= 0;
        end
        else
        begin
            phase <= phase+10;
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

            if (signal_type == 1) // Trapezoid
            begin
				case ({justChangedCond, lastTrapezoidCond})
					5'b10000 : begin
						$display("10000 phase = %d, temp = %d", phase_delayed, dac_out_temp_0);
						dac_out_temp_0 <= -8191-phase_delayed;
						dac_out <= AIncrement*dac_out_temp_4;
					end
					5'b00000 : begin
						$display("00000 phase = %d, temp = %d", phase_delayed, dac_out_temp_0);
						dac_out_temp_0 <= -8191-phase_delayed;
						dac_out <= AIncrement*dac_out_temp_0;
					end
					5'b10001 : begin
						$display("10001 phase = %d, temp = %d", phase_delayed, dac_out_temp_1);
						//dac_out_temp_1 <= -8191;
						dac_out <= AIncrement*dac_out_temp_0;
					end
					5'b00001 : begin
						$display("00001 phase = %d, temp = %d", phase_delayed, dac_out_temp_1);
						//dac_out_temp_1 <= -8191;
						dac_out <= dac_out_temp_1;
					end
					5'b10011 : begin
						$display("0011 phase = %d, temp = %d", phase_delayed, dac_out_temp_2);
						dac_out_temp_2 <= phase_delayed;
						dac_out <= dac_out_temp_1;
					end
					5'b00011 : begin
						$display("0011 phase = %d, temp = %d", phase_delayed, dac_out_temp_2);
						dac_out_temp_2 <= phase_delayed;
						dac_out <= AIncrement*dac_out_temp_2;
					end
					5'b10111 : begin
						$display("0111 phase = %d, temp = %d", phase_delayed, dac_out_temp_3);
						//dac_out_temp_3 <= 8191;
						dac_out <= AIncrement*dac_out_temp_2;
					end
					5'b00111 : begin
						$display("0111 phase = %d, temp = %d", phase_delayed, dac_out_temp_3);
						//dac_out_temp_3 <= 8191;
						dac_out <= dac_out_temp_3;
					end
					5'b11111 : begin
						$display("1111 phase = %d, temp = %d", phase_delayed, dac_out_temp_4);
						dac_out_temp_4 <= 8191-phase_delayed;
						dac_out <= dac_out_temp_3;
					end
					5'b01111 : begin
						$display("1111 phase = %d, temp = %d", phase_delayed, dac_out_temp_4);
						dac_out_temp_4 <= 8191-phase_delayed;
						dac_out <= AIncrement*dac_out_temp_4;
					end
					default : begin
						$display("default phase = %d", phase_delayed);
						dac_out <= 0;
					end
				endcase
			
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
                
				dac_out_temp2_delayed <= dac_out_temp2;
				dac_out_temp2_delayed2 <= dac_out_temp2_delayed;
                dac_out2 <= dac_out_temp2_delayed;
			end
            else if (signal_type == 2) // Triangle
            begin
                if (phase <= -4095 )
                begin
                    dac_out_temp_0 <= -2*(phase+8191);
                end
                else if (phase >= 4095)
                begin
                    dac_out_temp_0 <= 2*(8191-phase);
				end
			else 
                begin
                    dac_out_temp_0 <= 2*phase;
                end
                
                dac_out <= dac_out_temp_0;
	    end
            if (signal_type == 3) // Sawtooth
            begin
                dac_out_temp_0 <= phase;
				dac_out_temp2_delayed <= dac_out_temp_0;
                dac_out <= dac_out_temp2_delayed;
            end
       end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = dac_out;

endmodule