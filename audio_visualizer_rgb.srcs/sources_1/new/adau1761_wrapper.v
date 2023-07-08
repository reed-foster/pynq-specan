// adau1761_wrapper.v - Reed Foster
// verilog wrapper for ADAU1761 serdes

module adau1761_wrapper #(
  parameter int BIT_DEPTH = 24
) (
  input clk, reset_n,
  // i2s interface
  input sdata_i,
  output sdata_o,
  input bclk,  // bit clock        (3.072MHz)
  input lrclk, // left-right clock (48kHz)
  // i/o dsp stream interfaces
  // DAC interface
  input [2*BIT_DEPTH-1:0] s_axis_tdata,
  input s_axis_tvalid,
  output s_axis_tready,
  // ADC interface
  output [2*BIT_DEPTH-1:0] m_axis_tdata,
  output m_axis_tvalid,
  input m_axis_tready
);

adau1761_sv #(
  .BIT_DEPTH(BIT_DEPTH)
) (
  .clk(clk),
  .reset(~reset_n),
  .sdata_i(sdata_i),
  .sdata_o(sdata_o),
  .bclk(bclk),
  .lrclk(lrclk),
  .dac_data(s_axis_tdata),
  .dac_valid(s_axis_tvalid),
  .dac_ready(s_axis_tready),
  .adc_data(m_axis_tdata),
  .adc_valid(m_axis_tvalid),
  .adc_ready(m_axis_tready)
);

endmodule
