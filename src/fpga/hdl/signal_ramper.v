`timescale 1ns / 1ps

module signal_ramper (
    input  wire [47:0] s_axis_tdata_phase,
    input  wire s_axis_tvalid_phase,
    input clk,
    input aresetn,
    input enableRamping,
    input startRampDown,
    output [15:0] ramp
);

reg [12:0] phase = 0; // 0...8191
reg [12:0] phasePrev = 0;
reg phaseRising;
reg phaseRisingDelay;

reg [2:0] state;
localparam [2:0]
    stateRampUp = 2'b000,
    stateNormal = 2'b001,
    stateReqDown = 2'b010,
    stateRampDown = 2'b011,
    stateDone = 2'b100;

reg [15:0] rampTemp0;
reg [15:0] rampTemp1;

assign phase[12:0] = s_axis_tdata_phase[47:35];
assign phaseRising = (phasePrev <= phase);

always @(posedge clk)
begin
    phasePrev <= phase;
    phaseRisingDelay <= phaseRising;
    if (~aresetn)
    begin
        state = stateRampUp;
    end
end

always @*
begin
    case(state)
    stateDone : begin 
        rampTemp0 <= 0;
    end
    stateRampUp : begin 
        rampTemp0 <= phase;
        if (~phaseRising) begin
            state <= stateNormal; 
        end
    end
    stateNormal : begin
        rampTemp0 <= 8192;
        if (startRampDown) begin
            state <= stateReqDown;
        end
    end
    stateReqDown : begin
        rampTemp0 <= 8192;
        if (~phaseRisingDelay & phaseRising) begin
            state <= stateRampDown;
        end
    end
    stateRampDown : begin
        rampTemp0 <= 8192 - phase;
        if (~phaseRising) begin
            state <= stateDone;
        end
    end
    endcase
end

always @*
begin
    if (enableRamping)
    begin
        rampTemp1 <= rampTemp0;
    end else begin
        rampTemp1 <= 8192;
    end
end

assign ramp = rampTemp1;

endmodule