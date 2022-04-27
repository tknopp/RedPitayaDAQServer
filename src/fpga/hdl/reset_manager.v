`timescale 1ns / 1ps

module reset_manager #
(
    parameter integer ALIVE_SIGNAL_LOW_TIME = 100, // in milliseconds
    parameter integer ALIVE_SIGNAL_HIGH_TIME = 10, // in milliseconds
    parameter integer RAMWRITER_DELAY = 1 // in milliseconds

)
(
    input clk,
    input peripheral_aresetn,
    input [7:0] reset_cfg,
    inout trigger,
    inout watchdog,
    inout instant_reset,
    output write_to_ram_aresetn,
    output write_to_ramwriter_aresetn,
    output keep_alive_aresetn,
    output xadc_aresetn,
    output fourier_synth_aresetn,
    output pdm_aresetn,
    output [31:0] reset_sts,
    output [7:0] led,
    input [7:0] ramping_cfg,
    input [2:0] ramp_state_0,
    input [2:0] ramp_state_1,
    output [1:0] ramping_enable,
    output [1:0] start_ramp_down,
    inout reset_ack,
    inout alive_signal,
    inout master_trigger
);

/*
reset_cfg:
Bit 0 => 0: continuous mode; 1: trigger mode
Bit 1 => 0: no watchdog; 1: watchdog mode
Bit 2 => unused
Bit 3 => instant reset mode: 0: disabled; 1: enabled
Bit 4 => 0: internal trigger 1: external trigger
Bit 5 => internal trigger enable/disable, output over DIO5_P
Bit 6 => keep alive reset
Bit 7 => unused

reset_ack: high if reset active (either watchdog failed or instant reset)
*/

/*
ramping_cfg:
Bit 0 => enable ramping channel 0
Bit 1 => enable ramping channel 1
Bit 2 => start ramp down channel 0
Bit 3 => Start ramp down channel 1
Bit 4-7 => unused
*/

localparam integer ALIVE_SIGNAL_LOW_TIME_CYCLES = 12500000;//(125000000/ALIVE_SIGNAL_LOW_TIME)*1000;
localparam integer ALIVE_SIGNAL_HIGH_TIME_CYCLES = 1250000;//(125000000/ALIVE_SIGNAL_HIGH_TIME)*1000;
localparam integer RAMWRITER_DELAY_TIME= 1000000000; //100ms

reg triggerState = 0;
reg masterTriggerState_pre = 0;
reg masterTriggerState = 0;

reg write_to_ram_aresetn_int = 0;
reg xadc_aresetn_int = 0;
reg fourier_synth_aresetn_int = 0;
reg pdm_aresetn_int = 0;
reg keep_alive_aresetn_int = 0;

wire trigger_in;
wire watchdog_in;
wire instant_reset_in;
wire reset_ack_in;
wire alive_signal_in;
wire master_trigger_in;

wire trigger_out;
wire watchdog_out;
wire instant_reset_out;
wire reset_ack_out;
wire alive_signal_out;
wire master_trigger_out;

// Buffer Tristate inputs
IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_trigger (
.I(trigger_out),
.IO(trigger),
.O(trigger_in),
.T(1'b1) // 3-state enable input, high=input, low=output
);

IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_watchdog (
.I(watchdog_out),
.IO(watchdog),
.O(watchdog_in),
.T(1'b1) // 3-state enable input, high=input, low=output
);

IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_instant_reset (
.I(instant_reset_out),
.IO(instant_reset),
.O(instant_reset_in),
.T(1'b1) // 3-state enable input, high=input, low=output
);

// Buffer Tristate outputs
IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_reset_ack (
.I(reset_ack_out),
.IO(reset_ack),
.O(reset_ack_in),
.T(0'b0) // 3-state enable input, high=input, low=output
);

IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_alive_signal (
.I(alive_signal_out),
.IO(alive_signal),
.O(alive_signal_in),
.T(0'b0) // 3-state enable input, high=input, low=output
);

IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_master_trigger (
.I(master_trigger_out),
.IO(master_trigger),
.O(master_trigger_in),
.T(0'b0) // 3-state enable input, high=input, low=output
);

// Double-register inputs
reg trigger_in_int_pre = 0;
reg trigger_in_int = 0;
reg watchdog_in_int_pre = 0;
reg watchdog_in_int = 0;
reg instant_reset_in_int_pre = 0;
reg instant_reset_in_int = 0;
reg peripheral_aresetn_int_pre = 0;
reg peripheral_aresetn_int = 0;
always @(posedge clk)
begin
    trigger_in_int_pre <= trigger_in;
    trigger_in_int <= trigger_in_int_pre;
    watchdog_in_int_pre <= watchdog_in;
    watchdog_in_int <= watchdog_in_int_pre;
    instant_reset_in_int_pre <= instant_reset_in;
    instant_reset_in_int <= instant_reset_in_int_pre;
    peripheral_aresetn_int_pre <= peripheral_aresetn;
    peripheral_aresetn_int <= peripheral_aresetn_int_pre;
end

// Create alive signal
reg alive_signal_int = 0;
reg [27:0] alive_signal_counter = 0;
always @(posedge clk)
begin
    if (alive_signal_counter < (ALIVE_SIGNAL_LOW_TIME_CYCLES + ALIVE_SIGNAL_HIGH_TIME_CYCLES))
    begin
        alive_signal_counter <= alive_signal_counter + 1;
    end
    else
    begin
        alive_signal_counter <= 0;
    end

    if (alive_signal_counter < ALIVE_SIGNAL_LOW_TIME_CYCLES)
    begin
        alive_signal_int <= 0;
    end
    else
    begin
        alive_signal_int <= 1;
    end
end

// Master Trigger State
always @(posedge clk)
begin
    if (reset_cfg[4] == 0) // internal trigger mode
    begin
        triggerState <= reset_cfg[5];
    end
    else
    begin
        triggerState <= trigger_in_int;
    end

    masterTriggerState_pre <= reset_cfg[5];
    masterTriggerState <= masterTriggerState_pre;
end

always @(posedge clk)
begin
    if (~peripheral_aresetn)
    begin
        write_to_ram_aresetn_int <= peripheral_aresetn_int;
        xadc_aresetn_int <= peripheral_aresetn_int;
        fourier_synth_aresetn_int <= peripheral_aresetn_int;
        pdm_aresetn_int <= peripheral_aresetn_int;
    end
    else
    begin
        // Write to RAM
        if (reset_cfg[0] == 0) // continuous mode
        begin
            write_to_ram_aresetn_int <= peripheral_aresetn_int;
            fourier_synth_aresetn_int <= peripheral_aresetn_int;
            pdm_aresetn_int <= peripheral_aresetn_int;
        end
        else // trigger mode
        begin
            // ADC
            write_to_ram_aresetn_int <= triggerState;
            // DAC
            if (instant_reset_in && reset_cfg[3])
            begin
                fourier_synth_aresetn_int <= 1'b0;
                pdm_aresetn_int <= 1'b0;
            end
            else
            begin
                fourier_synth_aresetn_int <= triggerState;
                pdm_aresetn_int <= triggerState;
            end
        end

        // XADC is always running
        xadc_aresetn_int <= peripheral_aresetn_int;
        keep_alive_aresetn_int <= reset_cfg[6];
    end
end

assign write_to_ram_aresetn = write_to_ram_aresetn_int;
assign write_to_ramwriter_aresetn = write_to_ram_aresetn_int;
assign xadc_aresetn = xadc_aresetn_int;
assign fourier_synth_aresetn = fourier_synth_aresetn_int;
assign pdm_aresetn = pdm_aresetn_int;
assign keep_alive_aresetn = keep_alive_aresetn_int;

assign reset_sts[0] = peripheral_aresetn_int;
assign reset_sts[1] = fourier_synth_aresetn_int;
assign reset_sts[2] = pdm_aresetn_int;
assign #(0,RAMWRITER_DELAY_TIME) reset_sts[3] = write_to_ram_aresetn_int;
assign reset_sts[4] = xadc_aresetn_int;
assign reset_sts[5] = trigger_in_int;
assign reset_sts[6] = watchdog_in_int;
assign reset_sts[7] = instant_reset_in_int;
assign reset_sts[8] = triggerState;
assign reset_sts[15:9] = 7'b0;
assign reset_sts[16] = ramping_cfg[0];
assign reset_sts[19:17] = ramp_state_0[2:0];
assign reset_sts[20] = ramping_cfg[1];
assign reset_sts[23:21] = ramp_state_1[2:0];
assign reset_sts[31:24] = 8'b0;

assign led[7:0] = reset_sts[7:0];

assign reset_ack_out = watchdog_in; // Acknowledge received watchdog signal

assign alive_signal_out = alive_signal_int;
assign master_trigger_out = masterTriggerState;

assign ramping_enable[0] = ramping_cfg[0];
assign ramping_enable[1] = ramping_cfg[1];
assign start_ramp_down[0] = ramping_cfg[2];
assign start_ramp_down[1] = ramping_cfg[3];


endmodule
