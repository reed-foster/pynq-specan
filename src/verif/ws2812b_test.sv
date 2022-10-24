// ws2812b_test.sv - Reed Foster
// testbench for ws2812b framebuffer and serialization module

module ws2812b_test ();

localparam CLK_RATE_HZ = 100_000_000;
logic clk = 0;
always begin
  clk <= 1'b1;
  #(0.5s/CLK_RATE_HZ) clk <= 1'b0;
  #(0.5s/CLK_RATE_HZ);
end
logic reset = 0;

logic write_en = 0;
logic [3:0] write_addr;
logic [7:0] din;
logic dout;

logic [7:0] led_data [12] = {8'hde, 8'had, 8'hbe, 8'hef, 8'h42, 8'h69, 8'hb0, 8'h0f, 8'h12, 8'h34, 8'h56, 8'h78};

always @(posedge clk) begin
  if (reset) begin
    write_addr <= '0;
  end else begin
    if (write_en) begin
      if (write_addr == 11) begin
        write_addr <= '0;
      end else begin
        write_addr <= write_addr + 1;
      end
    end
  end
end

assign din = led_data[write_addr];

initial begin
  reset <= 1'b1;
  repeat (100) @(posedge clk);
  reset <= 1'b0;
  repeat (100) @(posedge clk);
  write_en <= 1'b1;
  repeat (96) @(posedge clk);
  write_en <= 1'b0;
  repeat (40000) @(posedge clk);
  $finish;
end

ws2812b #(
  .STRIP_LEN(12),
  .COLOR_BITS(8),
  .T0HI(40), // 400ns
  .T1HI(80), // 800ns
  .T0LO(85), // 850ns
  .T1LO(45), // 450ns
  .TRES(5500) // 55us
) dut_i (
  .clk,
  .reset,
  .write_en,
  .write_addr,
  .din,
  .dout
);

endmodule
