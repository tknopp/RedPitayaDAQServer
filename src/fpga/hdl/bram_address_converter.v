`timescale 1ns / 1ps

module bram_address_converter #
(
    parameter integer ELEMENT_SHIFT_SIZE = 2,
    parameter integer ELEMENT_ADDR_WIDTH = 13
)
(
    input [ELEMENT_ADDR_WIDTH -1:0] elAddr,
    output [31:0] addr,
    input clk
);

reg [31:0] addr_int;

always @(posedge clk)
begin
    addr_int <= {{(32-ELEMENT_ADDR_WIDTH-ELEMENT_SHIFT_SIZE){1'b0}}, (elAddr[ELEMENT_ADDR_WIDTH -1:0] << ELEMENT_SHIFT_SIZE)};
end

assign addr = addr_int;

endmodule
