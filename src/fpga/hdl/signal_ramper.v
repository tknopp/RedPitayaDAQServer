`timescale 1ns / 1ps

module signal_ramper (
    input wire [47:0] s_axis_tdata_phase,
    input wire s_axis_tvalid_phase,
    input clk,
    input aresetn,
    input enableRamping,
    input startRampDown,
    output [15:0] ramp,
    output [1:0] rampState
);

reg [12:0] phase; // 0...8191
reg [12:0] phasePrev;
reg phaseRising;
reg phaseRisingDelay;

reg [1:0] state, stateNext;
localparam [1:0]
    stateRampUp = 2'b10,
    stateNormal = 2'b00,
    stateRampDown = 2'b11,
    stateDone = 2'b01;

reg signed [15:0] rampTemp0;
reg signed [15:0] rampTemp1;
reg signed [15:0] rampStateTemp;

always @(posedge clk)
begin
    phase <= (s_axis_tdata_phase >> 35);
    phaseRising <= (phasePrev <= phase);
    phasePrev <= phase;
    phaseRisingDelay <= phaseRising;
    if (~aresetn)
    begin
        state <= stateRampUp;
    end else begin
        state <= stateNext;
    end
end

always @*
begin
    case(state)
        stateDone : begin 
            rampTemp0 <= 0;
            stateNext <= stateDone;
        end
        stateRampUp : begin 
            if (~phaseRising) begin
                rampTemp0 <= 8191;
                stateNext <= stateNormal; 
            end
            else begin
                rampTemp0 <= phase;
                stateNext <= stateRampUp;
            end
        end
        stateNormal : begin
            rampTemp0 <= 8191;
            if (startRampDown) begin
                stateNext <= stateRampDown;
            end
            else begin
                stateNext <= stateNormal;
            end
        end
        stateRampDown : begin
            if (~phaseRising) begin
                rampTemp0 <= 0; // Otherwise last bit of rampDown would be 8191 - 0
                stateNext <= stateDone;
            end
            else begin
                rampTemp0 <= 8191 - phase;
                stateNext <= stateRampDown;
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
        rampTemp1 <= 8191;
    end
end

assign ramp = rampTemp1;
assign rampState = state;

endmodule
