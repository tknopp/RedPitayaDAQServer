`timescale 1ns / 1ps

module bram_address_converter #
(
    parameter integer ELEMENT_SHIFT_SIZE = 2,
    parameter integer ELEMENT_ADDR_WIDTH = 13
)
(
    input [ELEMENT_ADDR_WIDTH -1:0] elAddr,
    output [31:0] addr
);

assign addr[31:0] = {{(31-ELEMENT_ADDR_WIDTH-ELEMENT_SHIFT_SIZE){0'b1}}, (elAddr[ELEMENT_ADDR_WIDTH -1:0] << ELEMENT_SHIFT_SIZE)};

endmodule
