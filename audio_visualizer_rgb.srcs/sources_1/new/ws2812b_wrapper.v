// ws2812b_wrapper.v - Reed Foster
// verilog wrapper so ws2812b controller can be instantiated in block diagram

module ws2812b_wrapper #(
  parameter int COLOR_BITS = 24,
  parameter int T0HI = 40,  // at 100MHz clock, 0.4us is 40 clock cycles
  parameter int T1HI = 80,
  parameter int T0LO = 85,
  parameter int T1LO = 45,
  parameter int TRES = 5500
) (
  input clk, reset_n,
  // axis interface
  input [COLOR_BITS-1:0] s_axis_tdata,
  input s_axis_tvalid,
  input s_axis_tlast,
  output s_axis_tready,
  // ws2812b interface
  output dout
);

ws2812b_sv #(
  .COLOR_BITS(COLOR_BITS),
  .T0HI(T0HI),
  .T1HI(T1HI),
  .T0LO(T0LO),
  .T1LO(T1LO),
  .TRES(TRES)
) (
  .clk(clk),
  .reset(~reset_n),
  .s_axis_tdata(s_axis_tdata),
  .s_axis_tvalid(s_axis_tvalid),
  .s_axis_tlast(s_axis_tlast),
  .s_axis_tready(s_axis_tready),
  .dout(dout)
);

endmodule
