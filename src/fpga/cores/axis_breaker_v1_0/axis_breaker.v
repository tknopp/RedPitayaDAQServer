
`timescale 1 ns / 1 ps

module axis_breaker #
(
  parameter integer AXIS_TDATA_WIDTH = 32
)
(
  // System signals
  input  wire                        aclk,
  input  wire                        aresetn,

  // Slave side
  output wire                        s_axis_tready,
  input  wire [AXIS_TDATA_WIDTH-1:0] s_axis_tdata,
  input  wire                        s_axis_tvalid,

  // Master side
  input  wire                        m_axis_tready,
  output wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
  output wire                        m_axis_tvalid
);

  reg int_enbl_reg, int_enbl_next;

  wire  int_tvalid_wire;

  always @(posedge aclk)
  begin
    if(~aresetn)
    begin
      int_enbl_reg <= 1'b0;
    end
    else
    begin
      int_enbl_reg <= 1'b1;
    end
  end

  assign int_tvalid_wire = int_enbl_reg & s_axis_tvalid;
  assign s_axis_tready = int_enbl_reg & m_axis_tready;
  assign m_axis_tdata = s_axis_tdata;
  assign m_axis_tvalid = int_tvalid_wire;

endmodule
