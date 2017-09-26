`timescale 1ns / 1ps

module axis_select #
(
    parameter integer AXIS_TDATA_WIDTH = 16
)
(
    // Selectable channel 1
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                               s_axis_tready_channel_1,
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_channel_1,
    input  wire                               s_axis_tvalid_channel_1,
    
    // Selectable channel 2
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                               s_axis_tready_channel_2,
    input  wire signed [AXIS_TDATA_WIDTH-1:0] s_axis_tdata_channel_2,
    input  wire                               s_axis_tvalid_channel_2,
    
    input wire selection,
    
    // Synthesized output
    (* X_INTERFACE_PARAMETER = "FREQ_HZ 125000000" *)
    output wire                        m_axis_tvalid,
    output wire [AXIS_TDATA_WIDTH-1:0] m_axis_tdata,
    input wire                         m_axis_tready
);

assign m_axis_tvalid = (selection) ? s_axis_tvalid_channel_2 : s_axis_tvalid_channel_1;
assign m_axis_tdata = (selection) ? s_axis_tdata_channel_2 : s_axis_tdata_channel_1;

assign s_axis_tready_channel_1 = (selection) ? 1'b0 : m_axis_tready;
assign s_axis_tready_channel_2 = (selection) ? m_axis_tready : 1'b0;

endmodule
