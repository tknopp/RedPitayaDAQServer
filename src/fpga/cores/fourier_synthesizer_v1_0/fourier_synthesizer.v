`timescale 1ns / 1ps

module fourier_synthesizer #
(
    parameter N_MULTIPLICATIONS = 4,
    parameter N_ADDITIONS = 3,
    parameter integer AXIS_TDATA_WIDTH = 16,
    parameter integer DAC_WIDTH = 14,
    parameter integer CFG_DATA_WIDTH = 16
)
(
    // DDS Input
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                               s_axis_tready_channel_1,
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_channel_1,
    input  wire                               s_axis_tvalid_channel_1,
    
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                               s_axis_tready_channel_2,
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_channel_2,
    input  wire                               s_axis_tvalid_channel_2,
        
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                               s_axis_tready_channel_3,
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_channel_3,
    input  wire                               s_axis_tvalid_channel_3,
    
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                               s_axis_tready_channel_4,
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_channel_4,
    input  wire                               s_axis_tvalid_channel_4,
    
    input [CFG_DATA_WIDTH-1:0] amplitude_channel_1,
    input [CFG_DATA_WIDTH-1:0] amplitude_channel_2,
    input [CFG_DATA_WIDTH-1:0] amplitude_channel_3,
    input [CFG_DATA_WIDTH-1:0] amplitude_channel_4,
    
    // Synthesized output
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                        m_axis_tvalid,
    output wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    
    input clk,
    input aresetn
);

    reg signed [2*AXIS_TDATA_WIDTH-1:0]   multiplications [N_MULTIPLICATIONS-1:0];
	reg signed [2*AXIS_TDATA_WIDTH+1-1:0] additions [N_ADDITIONS-1:0];
	reg signed [AXIS_TDATA_WIDTH-1:0]     shifted = 0;
	reg signed [DAC_WIDTH-1:0]            dac_out = 0;
	
	wire signed [CFG_DATA_WIDTH-1+1:0]    amplitude_channel_1_signed;
	wire signed [CFG_DATA_WIDTH-1+1:0]    amplitude_channel_2_signed;
	wire signed [CFG_DATA_WIDTH-1+1:0]    amplitude_channel_3_signed;
	wire signed [CFG_DATA_WIDTH-1+1:0]    amplitude_channel_4_signed;
	
	assign amplitude_channel_1_signed = amplitude_channel_1;
	assign amplitude_channel_2_signed = amplitude_channel_2;
	assign amplitude_channel_3_signed = amplitude_channel_3;
	assign amplitude_channel_4_signed = amplitude_channel_4;
	
	// Set initial values to zero
	initial
	begin: INIT
		integer i;
		for (i=0; i < N_MULTIPLICATIONS; i=i+1)
		begin
			multiplications[i] <= 0;
		end
		
		for (i=0; i < N_ADDITIONS; i=i+1)
		begin
			additions[i] <= 0;
		end
	end
	
	// Calculate the multiplications
    always @(posedge clk)
    begin
        if (s_axis_tvalid_channel_1 == 1)
        begin
            multiplications[0] <= s_axis_tdata_channel_1*amplitude_channel_1_signed;
        end
        else
        begin
            multiplications[0] <= 0;
        end
        
        if (s_axis_tvalid_channel_2 == 1)
        begin
            multiplications[1] <= s_axis_tdata_channel_2*amplitude_channel_2_signed;
        end
        else
        begin
            multiplications[1] <= 0;
        end
        
        if (s_axis_tvalid_channel_3 == 1)
        begin
            multiplications[2] <= s_axis_tdata_channel_3*amplitude_channel_3_signed;
        end
        else
        begin
            multiplications[2] <= 0;
        end
        
        if (s_axis_tvalid_channel_4 == 1)
        begin
            multiplications[3] <= s_axis_tdata_channel_4*amplitude_channel_4_signed;
        end
        else
        begin
            multiplications[3] <= 0;
        end
    end
    
    // Calculate the additions and shift result
    always @(posedge clk)
    begin
        additions[0] <= multiplications[0]+multiplications[1];
        additions[1] <= multiplications[2]+multiplications[3];
        additions[2] <= additions[0]+additions[1];
        shifted <= (additions[2] >>> (AXIS_TDATA_WIDTH-3));
    end
    
    always @(posedge clk)
    begin
        if (~aresetn)
        begin
            dac_out <= 14'h0;
        end
        else
        begin
            if (shifted >= $signed(8192)) // postitive sat
                dac_out <= 14'h1FFF;
            else if (shifted < $signed(-8192)) // negative sat
                dac_out <= 14'h2000;
            else
                dac_out <= shifted[DAC_WIDTH-1:0];
        end
    end
    
    assign m_axis_tvalid = 1;
    assign m_axis_tdata = dac_out;

endmodule
