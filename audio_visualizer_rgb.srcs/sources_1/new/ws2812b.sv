// ws2812b.sv - Reed Foster
// serializer to drive display
// frame buffer must be implemented separately

module ws2812b #(
  parameter int COLOR_BITS = 24,
  parameter int T0HI = 40,  // at 100MHz clock, 0.4us is 40 clock cycles
  parameter int T1HI = 80,
  parameter int T0LO = 85,
  parameter int T1LO = 45,
  parameter int TRES = 5500
) (
  input wire clk, reset,
  Axis_If.Slave_Full din, // full interface so last tells us when we're done
  output logic dout
);

localparam BIT_ADDR_BITS = $clog2(COLOR_BITS);
localparam DELAY_BITS = $clog2(TRES);

logic [BIT_ADDR_BITS-1:0] bit_idx;
logic [DELAY_BITS-1:0] delay_counter;
enum {RES, HI, LO} bit_state;

assign dout = (bit_state == HI) ? 1'b1 : 1'b0;

always_ff @(posedge clk) begin
  if (reset) begin
    bit_state <= RES;
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
        if (((din.data[bit_idx] == 1'b1) && (delay_counter == T1HI - 1)) ||
            ((din.data[bit_idx] == 1'b0) && (delay_counter == T0HI - 1))) begin
          bit_state <= LO;
          delay_counter <= '0;
        end else begin
          delay_counter <= delay_counter + 1'b1;
        end
      LO: // if LO duration is up, either transition to HI or RES, depending on whether or not
          // we're done with the current LED and if we have another LED to write to
        if (((din.data[bit_idx] == 1'b1) && (delay_counter == T1LO - 1)) ||
            ((din.data[bit_idx] == 1'b0) && (delay_counter == T0LO - 1))) begin
          if (bit_idx == COLOR_BITS - 1) begin
            bit_idx <= '0;
            if (din.last) begin
              bit_state <= RES;
            end else begin
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

// wrapper so sv can be instantiated in verilog wrapper

module ws2812b_sv #(
  parameter int COLOR_BITS = 24,
  parameter int T0HI = 40,  // at 100MHz clock, 0.4us is 40 clock cycles
  parameter int T1HI = 80,
  parameter int T0LO = 85,
  parameter int T1LO = 45,
  parameter int TRES = 5500
) (
  input clk, reset,
  // axis interface
  input [COLOR_BITS-1:0] s_axis_tdata,
  input s_axis_tvalid,
  input s_axis_tlast,
  output s_axis_tready,
  // ws2812b interface
  output dout
);

Axis_If #(.DWIDTH(COLOR_BITS)) din();

assign din.data = s_axis_tdata;
assign din.valid = s_axis_tvalid;
assign din.last = s_axis_tlast;
assign s_axis_tready = din.ready;

ws2812b #(
  .COLOR_BITS(COLOR_BITS),
  .T0HI(T0HI),
  .T1HI(T1HI),
  .T0LO(T0LO),
  .T1LO(T1LO),
  .TRES(TRES)
) ws2812b_i (
  .clk,
  .reset,
  .din,
  .dout
);

endmodule
