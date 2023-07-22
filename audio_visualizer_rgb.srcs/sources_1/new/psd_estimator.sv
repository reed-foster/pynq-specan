// psd_estimator.sv - Reed Foster
// estimates PSD from audio source

module psd_estimator #(
  parameter int NUM_LEDS = 600,
  parameter int AUDIO_WIDTH = 24,
  parameter int PSD_WIDTH = 16
) (
  input wire clk, reset,
  
  Axis_If.Slave_Simple audio_in,
  Axis_If.Master_Full psd_out
);



endmodule
