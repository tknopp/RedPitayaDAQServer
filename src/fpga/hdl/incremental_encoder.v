`timescale 1ns / 1ps

module incremental_encoder #
(
    parameter integer COUNTER_WIDTH = 16
)
(
    input clk,
    input aresetn,
    output [1:0] data,
    output [COUNTER_WIDTH-1:0] counter,
    inout incremental_encoder_1,
    inout incremental_encoder_2
);

wire incremental_encoder_1_in;
wire incremental_encoder_2_in;

wire incremental_encoder_1_out;
wire incremental_encoder_2_out;

// Buffer Tristate inputs
IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_trigger (
.I(incremental_encoder_1_out),
.IO(incremental_encoder_1),
.O(incremental_encoder_1_in),
.T(1'b1) // 3-state enable input, high=input, low=output
);

IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_watchdog (
.I(incremental_encoder_2_out),
.IO(incremental_encoder_2),
.O(incremental_encoder_2_in),
.T(1'b1) // 3-state enable input, high=input, low=output
);

// Register Inputs
reg incremental_encoder_1_int = 0;
reg incremental_encoder_2_int = 0;
reg [COUNTER_WIDTH-1:0] counter_int = 0;
always @(posedge clk)
begin
    if (~aresetn)
    begin
        incremental_encoder_1_int <= 0;
        incremental_encoder_2_int <= 0;
        counter_int <= 0;
    end
    else
    begin
        incremental_encoder_1_int <= incremental_encoder_1_in;
        incremental_encoder_2_int <= incremental_encoder_2_in;
        counter_int <= counter_int+1;
    end
end

assign data[1:0] = {{incremental_encoder_2_int}, {incremental_encoder_1_int}};
assign counter = counter_int;

endmodule


