`timescale 1ns / 1ps

module hbridge_signalgen #
(
    parameter integer AXIS_TDATA_PHASE_WIDTH = 16,
    parameter integer CFG_DATA_WIDTH = 16
)
(
    // DDS Input
    input  wire [AXIS_TDATA_PHASE_WIDTH-1:0] s_axis_tdata_phase,
    input  wire s_axis_tvalid_phase,
    
    input [CFG_DATA_WIDTH-1:0] cfg_data,
    
    
    input clk,
    input aresetn,
    output H1, H2
);

    reg signed [AXIS_TDATA_PHASE_WIDTH-1:0] phase;
    reg signed [CFG_DATA_WIDTH-1:0] A;
    reg h1, h2;

	
    always @(posedge clk)
    begin
        A <= cfg_data>>1;
        
        if (~aresetn)
        begin
            h1 <= 0;
            h2 <= 0;
            phase <= 0;
        end
        else
        begin
            phase <= s_axis_tdata_phase >>> (AXIS_TDATA_PHASE_WIDTH - CFG_DATA_WIDTH);
            //4096 = (1<<<(CFG_DATA_WIDTH-2))

            if (phase < 4096-A)
            begin
                h1 <= 0;
                h2 <= 0;
            end
            else if (phase < 4096+A)
            begin
                h1 <= 0;
                h2 <= 1;
            end
            else if (phase < 12288-A)
            begin
                h1 <= 0;
                h2 <= 0;
            end
            else if (phase < 12288+A)
            begin
                h1 <= 1;
                h2 <= 0;
            end
            else
            begin
                h1 <= 0;
                h2 <= 0;
            end

         end
         
    end
    
assign H1 = h1;
assign H2 = h2;

endmodule