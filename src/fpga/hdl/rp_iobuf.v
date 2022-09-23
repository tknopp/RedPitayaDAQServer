`timescale 1ns / 1ps

module rp_iobuf #
(
)
(
    input clk,
    input val_out,
    input direction, // 3-state enable input, high=input, low=output
    inout val_tri,
    output val_in_clocked
);

wire val_in;

IOBUF #(
.DRIVE(8),
.IOSTANDARD("LVCMOS33"),
.SLEW("FAST")
) IOBUF_watchdog (
.I(val_out),
.IO(val_tri),
.O(val_in),
.T(direction) // 3-state enable input, high=input, low=output
);

// Double-register input
reg val_in_int_pre = 0;
reg val_in_int = 0;
always @(posedge clk)
begin
  val_in_int_pre <= val_in;
  val_in_int <= val_in_int_pre;
end

assign val_in_clocked = val_in_int;

endmodule