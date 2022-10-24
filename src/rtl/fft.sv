// fft.sv - Reed Foster
// wrapper for Xilinx XFFT

module fft #(
  parameter int DATA_WIDTH = 24,
  parameter int N_FFT = 9 // 512-point FFT
) (
  input wire clk,
  Axis_If.Master data_out,
  Axis_If.Slave data_in
);

// config bits are padded as so: {pad8({FWD_INV, SCALE_SCH}), pad8(CP_LEN), pad8(NFFT)}
localparam CONFIG_BITS = 8*((1 + 2*N_FFT + 7) / 8)+ 8*((N_FFT + 7) / 8) + 8;
localparam logic [N_FFT-1:0] SCALE_SCHEDULE = {{(N_FFT-1){2'b01}}, 2'b10};
localparam logic [CONFIG_BITS-1:0] CONFIG_DATA = {SCALE_SCHEDULE, 1'b1};

generate
  case(N_FFT)
    9: xfft_radix2_lit_burst_512 xfft_i (
      .aclk(clk),
      .s_axis_config_tdata(CONFIG_DATA),
      .s_axis_config_tvalid(1'b1),
      .s_axis_config_tready(),
      .s_axis_data_tdata(data_in.data),
      .s_axis_data_tvalid(data_in.valid),
      .s_axis_data_tready(data_in.ready),
      .s_axis_data_tlast(data_in.last),
      .m_axis_data_tdata(data_out.data),
      .m_axis_data_tvalid(data_out.valid),
      .m_axis_data_tready(data_out.ready),
      .m_axis_data_tlast(data_out.last),
      .event_frame_started(),
      .event_tlast_unexpected(),
      .event_tlast_missing(),
      .event_status_channel_halt(),
      .event_data_in_channel_halt(),
      .event_data_out_channel_halt()
    );
    10: xfft_radix2_lit_burst_1k xfft_i (
      .aclk(clk),
      .s_axis_config_tdata(CONFIG_DATA),
      .s_axis_config_tvalid(1'b1),
      .s_axis_config_tready(),
      .s_axis_data_tdata(data_in.data),
      .s_axis_data_tvalid(data_in.valid),
      .s_axis_data_tready(data_in.ready),
      .s_axis_data_tlast(data_in.last),
      .m_axis_data_tdata(data_out.data),
      .m_axis_data_tvalid(data_out.valid),
      .m_axis_data_tready(data_out.ready),
      .m_axis_data_tlast(data_out.last),
      .event_frame_started(),
      .event_tlast_unexpected(),
      .event_tlast_missing(),
      .event_status_channel_halt(),
      .event_data_in_channel_halt(),
      .event_data_out_channel_halt()
    );
    11: xfft_radix2_lit_burst_2k xfft_i (
      .aclk(clk),
      .s_axis_config_tdata(CONFIG_DATA),
      .s_axis_config_tvalid(1'b1),
      .s_axis_config_tready(),
      .s_axis_data_tdata(data_in.data),
      .s_axis_data_tvalid(data_in.valid),
      .s_axis_data_tready(data_in.ready),
      .s_axis_data_tlast(data_in.last),
      .m_axis_data_tdata(data_out.data),
      .m_axis_data_tvalid(data_out.valid),
      .m_axis_data_tready(data_out.ready),
      .m_axis_data_tlast(data_out.last),
      .event_frame_started(),
      .event_tlast_unexpected(),
      .event_tlast_missing(),
      .event_status_channel_halt(),
      .event_data_in_channel_halt(),
      .event_data_out_channel_halt()
    );
    12: xfft_radix2_lit_burst_4k xfft_i (
      .aclk(clk),
      .s_axis_config_tdata(CONFIG_DATA),
      .s_axis_config_tvalid(1'b1),
      .s_axis_config_tready(),
      .s_axis_data_tdata(data_in.data),
      .s_axis_data_tvalid(data_in.valid),
      .s_axis_data_tready(data_in.ready),
      .s_axis_data_tlast(data_in.last),
      .m_axis_data_tdata(data_out.data),
      .m_axis_data_tvalid(data_out.valid),
      .m_axis_data_tready(data_out.ready),
      .m_axis_data_tlast(data_out.last),
      .event_frame_started(),
      .event_tlast_unexpected(),
      .event_tlast_missing(),
      .event_status_channel_halt(),
      .event_data_in_channel_halt(),
      .event_data_out_channel_halt()
    );
  endcase
endgenerate

endmodule
