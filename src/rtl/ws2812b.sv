// ws2812b.sv - Reed Foster
// frame buffer and serializer to drive 

module ws2812b #(
  parameter int STRIP_LEN = 120,
  parameter int COLOR_BITS = 24,
  parameter int T0HI = 40,  // at 100MHz clock, 0.4us is 40 clock cycles
  parameter int T1HI = 80,
  parameter int T0LO = 85,
  parameter int T1LO = 45,
  parameter int TRES = 5500,
  localparam int LED_ADDR_BITS = $clog2(STRIP_LEN)
) (
  input wire clk, reset,
  input write_en,
  input [LED_ADDR_BITS-1:0] write_addr,
  input [COLOR_BITS-1:0] din,
  output logic dout
);

localparam BIT_ADDR_BITS = $clog2(COLOR_BITS);
localparam DELAY_BITS = $clog2(TRES);

logic [LED_ADDR_BITS-1:0] read_addr;
logic [BIT_ADDR_BITS-1:0] bit_idx;
logic [DELAY_BITS-1:0] delay_counter;
logic [COLOR_BITS-1:0] current_color;
enum {RES, HI, LO} bit_state;

xpm_memory_sdpram #(
   .ADDR_WIDTH_A(LED_ADDR_BITS),
   .ADDR_WIDTH_B(LED_ADDR_BITS),
   .MEMORY_SIZE(COLOR_BITS*STRIP_LEN),
   .BYTE_WRITE_WIDTH_A(COLOR_BITS),
   .WRITE_DATA_WIDTH_A(COLOR_BITS),
   .READ_DATA_WIDTH_B(COLOR_BITS),
   .READ_LATENCY_B(2),
   .WRITE_MODE_B("read_first")
)
frame_buffer_i (
   .clka(clk),
   .clkb(clk),
   .rstb(reset),

   .addra(write_addr),
   .addrb(read_addr),
   .dina(din),
   .doutb(current_color),
   .ena(write_en),
   .wea(write_en),
   .enb(1'b1),

   .injectdbiterra(1'b0),
   .injectsbiterra(1'b0),
   .dbiterrb(),
   .sbiterrb(),
   .regceb(1'b1),
   .sleep(1'b0)
);

assign dout = (bit_state == HI) ? 1'b1 : 1'b0;

always_ff @(posedge clk) begin
  if (reset) begin
    bit_state <= RES;
    read_addr <= '0;
    bit_idx <= '0;
    delay_counter <= '0;
  end else begin
    unique case (bit_state)
      RES: // if reset duration is up, transition to HI
        if (delay_counter == TRES - 1) begin
          bit_state <= HI;
          delay_counter <= '0;
        end else begin
          delay_counter <= delay_counter + 1'b1;
        end
      HI: // if HI duration is up, transition to LO
        if (((current_color[bit_idx] == 1'b1) && (delay_counter == T1HI - 1)) ||
            ((current_color[bit_idx] == 1'b0) && (delay_counter == T0HI - 1))) begin
          bit_state <= LO;
          delay_counter <= '0;
        end else begin
          delay_counter <= delay_counter + 1'b1;
        end
      LO: // if LO duration is up, either transition to HI or RES, depending on whether or not we have another LED to write to
        if (((current_color[bit_idx] == 1'b1) && (delay_counter == T1LO - 1)) ||
            ((current_color[bit_idx] == 1'b0) && (delay_counter == T0LO - 1))) begin
          if (bit_idx == COLOR_BITS - 1) begin
            bit_idx <= '0;
            if (read_addr == STRIP_LEN - 1) begin
              read_addr <= '0;
              bit_state <= RES;
            end else begin
              read_addr <= read_addr + 1'b1;
              bit_state <= HI;
            end
          end else begin
            bit_state <= HI;
            bit_idx <= bit_idx + 1'b1;
          end
          delay_counter <= '0;
        end else begin
          delay_counter <= delay_counter + 1'b1;
        end
    endcase
  end
end

endmodule
