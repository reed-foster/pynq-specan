// sample_buffer_wrapper.v - Reed Foster
// verilog wrapper for instantiation in block diagram

module sample_buffer_wrapper #(
  parameter int DWIDTH = 24,
  parameter int SAMPLE_DEPTH = 2048
) (
  input wire clk, reset_n,

  input [DWIDTH-1:0] s_axis_tdata,
  input s_axis_tvalid,
  output s_axis_tready,

  output [DWIDTH-1:0] m_axis_tdata,
  output m_axis_tvalid,
  output m_axis_tlast,
  input m_axis_tready
);

sample_buffer_sv #(
  .DWIDTH(DWIDTH),
  .SAMPLE_DEPTH(SAMPLE_DEPTH)
) sample_buffer_sv_i (
  .clk(clk),
  .reset(~reset_n),
  s_axis_tdata(s_axis_tdata),
  s_axis_tvalid(s_axis_tvalid),
  s_axis_tready(s_axis_tready),
  m_axis_tdata(m_axis_tdata),
  m_axis_tvalid(m_axis_tvalid),
  m_axis_tlast(m_axis_tlast),
  m_axis_tready(m_axis_tready)
);

endmodule
