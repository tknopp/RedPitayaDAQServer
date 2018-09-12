`timescale 1ns / 1ps

module dio #
(
    // No parameters
)
(
    inout DIO_0,
    inout DIO_1,
    inout DIO_2,
    inout DIO_3,
    inout DIO_4,
    inout DIO_5,
    inout DIO_6,
    inout DIO_7,

    output DIO_0_in,
    output DIO_1_in,
    output DIO_2_in,
    output DIO_3_in,
    output DIO_4_in,
    output DIO_5_in,
    output DIO_6_in,
    output DIO_7_in,
    
    input [8-1:0] value,
    input [8-1:0] state,
    
    input clk,
    input aresetn
);

    wire DIO_0_out;
    wire DIO_1_out;
    wire DIO_2_out;
    wire DIO_3_out;
    wire DIO_4_out;
    wire DIO_5_out;
    wire DIO_6_out;
    wire DIO_7_out;

    assign DIO_0_out = value[0];
    assign DIO_1_out = value[1];
    assign DIO_2_out = value[2];
    assign DIO_3_out = value[3];
    assign DIO_4_out = value[4];
    assign DIO_5_out = value[5];
    assign DIO_6_out = value[6];
    assign DIO_7_out = value[7];

    // Buffer Tristate inputs
    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_0 (
    .I(DIO_0_out),
    .IO(DIO_0),
    .O(DIO_0_in),
    .T(state[0]) // 3-state enable input, high=input, low=output
    );
    
    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_1 (
    .I(DIO_1_out),
    .IO(DIO_1),
    .O(DIO_1_in),
    .T(state[1]) // 3-state enable input, high=input, low=output
    );

    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_2 (
    .I(DIO_2_out),
    .IO(DIO_2),
    .O(DIO_2_in),
    .T(state[2]) // 3-state enable input, high=input, low=output
    );

    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_3 (
    .I(DIO_3_out),
    .IO(DIO_3),
    .O(DIO_3_in),
    .T(state[3]) // 3-state enable input, high=input, low=output
    );

    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_4 (
    .I(DIO_4_out),
    .IO(DIO_4),
    .O(DIO_4_in),
    .T(state[4]) // 3-state enable input, high=input, low=output
    );

    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_5 (
    .I(DIO_5_out),
    .IO(DIO_5),
    .O(DIO_5_in),
    .T(state[5]) // 3-state enable input, high=input, low=output
    );

    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_6 (
    .I(DIO_6_out),
    .IO(DIO_6),
    .O(DIO_6_in),
    .T(state[6]) // 3-state enable input, high=input, low=output
    );

    IOBUF #(
    .DRIVE(8),
    .IOSTANDARD("LVCMOS33"),
    .SLEW("FAST")
    ) IOBUF_DIO_7 (
    .I(DIO_7_out),
    .IO(DIO_7),
    .O(DIO_7_in),
    .T(state[7]) // 3-state enable input, high=input, low=output
    );

endmodule
