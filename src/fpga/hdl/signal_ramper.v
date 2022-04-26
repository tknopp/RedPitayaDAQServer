`timescale 1ns / 1ps

module signal_ramper (
    input wire [47:0] s_axis_tdata_phase,
    input wire s_axis_tvalid_phase,
    input clk,
    input aresetn,
    input enableRamping,
    input startRampDown,
    output [15:0] ramp
    //output signed [15:0] rampState
);

reg [12:0] phase; // 0...8191
reg [12:0] phasePrev;
reg phaseRising;
reg phaseRisingDelay;

reg [2:0] state, stateNext;
localparam [2:0]
    stateRampUp = 3'b000,
    stateNormal = 3'b001,
    stateReqDown = 3'b010,
    stateRampDown = 3'b011,
    stateDone = 3'b100;

reg signed [15:0] rampTemp0;
reg signed [15:0] rampTemp1;
reg signed [15:0] rampStateTemp;

always @(posedge clk)
begin
    phase <= (s_axis_tdata_phase >> 36);
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
            rampTemp0 <= phase;
            if (~phaseRising) begin
                stateNext <= stateNormal; 
            end
            else begin
                stateNext <= stateRampUp;
            end
        end
        stateNormal : begin
            rampTemp0 <= 8191;
            if (startRampDown) begin
                stateNext <= stateReqDown;
            end
            else begin
                stateNext <= stateNormal;
            end
        end
        stateReqDown : begin
            rampTemp0 <= 8191;
            if (~phaseRisingDelay & phaseRising) begin
                stateNext <= stateRampDown;
            end
            else begin
                stateNext <= stateReqDown;
            end
        end
        stateRampDown : begin
            rampTemp0 <= 8191 - phase;
            if (~phaseRising) begin
                stateNext <= stateDone;
            end
            else begin
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
    //rampTemp1 <= phase;
    //case(state)
    //    stateDone : begin
    //        rampStateTemp <= 4000;
    //    end
    //    stateRampUp : begin 
    //        rampStateTemp <= 2000;
    //    end
    //    stateNormal : begin
    //        rampStateTemp <= 0;
    //    end
    //    stateReqDown : begin
    //        rampStateTemp <= -2000;
    //    end
    //    stateRampDown : begin
    //        rampStateTemp <= -4000;
    //    end
    //endcase
end

assign ramp = rampTemp1;
//assign rampState = rampStateTemp;

endmodule
