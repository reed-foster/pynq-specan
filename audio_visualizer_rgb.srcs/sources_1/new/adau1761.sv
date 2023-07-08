// adau1761.sv - Reed Foster
// i2s serializer/deserializer for ADAU1761 data interface

module adau1761 #(
  parameter int BIT_DEPTH = 24
)(
  input wire clk, reset,
  // i2s interface
  input         sdata_i,
  output logic  sdata_o,
  input         bclk,  // bit clock        (3.072MHz)
  input         lrclk, // left-right clock (48kHz)
  // i/o dsp stream interfaces
  Axis_If.Slave_Simple   dac_sample,
  Axis_If.Master_Simple  adc_sample
);

// get rising and falling edges of bclk and lrclk
logic bclk_r, bclk_f, lrclk_r, lrclk_f;
logic [2:0] bclk_d, lrclk_d;
always_ff @(posedge clk) begin
  bclk_d <= {bclk_d[1:0], bclk};
  lrclk_d <= {lrclk_d[1:0], lrclk};
end

assign bclk_r = !bclk_d[1] & bclk_d[0];
assign bclk_f = bclk_d[1] & !bclk_d[0];
// delay lrclk detector by an extra cycle to prevent erroneous triggering of bclk
// events immediately after lrclk falling/rising edge
assign lrclk_r = !lrclk_d[2] & lrclk_d[1];
assign lrclk_f = lrclk_d[2] & !lrclk_d[1];

// shift registers
logic [$clog2(BIT_DEPTH)-1:0] bit_counter = '0;
logic [2*BIT_DEPTH-1:0] shift_reg_in; // store two channels per sample
logic [2*BIT_DEPTH-1:0] shift_reg_out;
assign sdata_o = shift_reg_out[2*BIT_DEPTH-1];

// handle ready-valid logic, shift registers, and bit counter
always_ff @(posedge clk) begin
  if (reset) begin
    bit_counter <= '0;
    shift_reg_in <= '0;
    shift_reg_out <= '0;
    adc_sample.data <= '0;
    adc_sample.valid <= 1'b0;
    dac_sample.ready <= 1'b1;
  end else begin
    // ready_valid logic
    if (dac_sample.ready && dac_sample.valid) begin
      // perform a transfer
      dac_sample.ready <= 1'b0;
      dac_sample.data <= dac_sample.data;
    end
    if (adc_sample.ready && adc_sample.valid) begin
      // perform a transfer
      adc_sample.valid <= 1'b0;
    end
    // update bit counter
    if (lrclk_r || lrclk_f) begin
      bit_counter <= '0;
    end else if (bclk_r) begin
      bit_counter <= bit_counter + 1'b1;
    end
    // handle shift registers
    if (lrclk_f) begin
      // load in dac_sample_data
      shift_reg_out <= dac_sample.data;
      dac_sample.ready <= 1'b1;
      // load out adc_sample_data
      adc_sample.data <= shift_reg_in;
      adc_sample.valid <= 1'b1;
    end else begin
      if (bclk_r && (bit_counter > 0 && bit_counter < 25)) begin
        shift_reg_in <= {shift_reg_in[2*BIT_DEPTH-2:0], sdata_i};
      end
      if (bclk_f && (bit_counter > 1 && bit_counter < 26)) begin
        shift_reg_out <= {shift_reg_out[2*BIT_DEPTH-2:0], 1'b0};
      end
    end
  end
end
endmodule

// wrapper so sv can be instantiated in verilog wrapper

module adau1761_sv #(
  parameter int BIT_DEPTH = 24
) (
  input clk, reset_n,
  input enabled,
  // i2s interface
  input sdata_i,
  output sdata_o,
  input bclk,  // bit clock        (3.072MHz)
  input lrclk, // left-right clock (48kHz)
  // i/o dsp stream interfaces
  // DAC interface
  input dac_data,
  input dac_valid,
  output dac_ready,
  // ADC interface
  output adc_data,
  output adc_valid,
  input adc_ready
);

Axis_If #(.DWIDTH(2*BIT_DEPTH)) dac_if();
Axis_If #(.DWIDTH(2*BIT_DEPTH)) adc_if();

assign dac_if.data = dac_data;
assign dac_if.valid = dac_valid;
assign dac_ready = dac_if.ready;

assign adc_data = adc_if.data;
assign adc_valid = adc_if.valid;
assign adc_if.ready = adc_ready;

adau1761 #(
  .BIT_DEPTH(BIT_DEPTH)
) (
  .clk(clk),
  .reset(~reset_n),
  .sdata_i(sdata_i),
  .sdata_o(sdata_o),
  .bclk(bclk),
  .lrclk(lrclk),
  .dac_sample(dac_if),
  .adc_sample(adc_if)
);

endmodule
