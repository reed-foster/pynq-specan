// sample_buffer.sv - Reed Foster
// audio sample buffer, records raw samples from ADAU1761 codec

module sample_buffer #(
  parameter int DWIDTH = 24,
  parameter int SAMPLE_DEPTH = 2048
) (
  input wire clk, reset,
  Axis_If.Slave_Simple din,
  Axis_If.Master_Full dout
);

logic [DWIDTH-1:0] buffer [SAMPLE_DEPTH];
logic [$clog2(SAMPLE_DEPTH)-1:0] read_addr, write_addr;

assign din.ready = 1;

always @(posedge clk) begin
  if (reset) begin
    read_addr <= '0;
    write_addr <= '0;
    dout.valid <= 1'b0;
  end else begin
    if (din.valid) begin
      buffer[write_addr] <= din.data;
      if (write_addr == SAMPLE_DEPTH - 1) begin
        write_addr <= '0;
      end else begin
        write_addr <= write_addr + 1'b1;
      end
    end
    if (dout.ready) begin
      dout.valid <= 1'b1;
      dout.data <= buffer[read_addr];
      if (read_addr == SAMPLE_DEPTH - 1) begin
        read_addr <= '0;
        dout.last <= 1'b1;
      end else begin
        read_addr <= read_addr + 1'b1;
        dout.last <= 1'b0;
      end
    end
  end
end
endmodule


// sv wrapper for instantiation in verilog wrapper that can be used in block design

module sample_buffer_sv #(
  parameter int DWIDTH = 24,
  parameter int SAMPLE_DEPTH = 2048
) (
  input wire clk, reset,

  input [DWIDTH-1:0] s_axis_tdata,
  input s_axis_tvalid,
  output s_axis_tready,

  output [DWIDTH-1:0] m_axis_tdata,
  output m_axis_tvalid,
  output m_axis_tlast,
  input m_axis_tready
);

Axis_If #(.DWIDTH(DWIDTH)) din();
Axis_If #(.DWIDTH(DWIDTH)) dout();

assign din.data = s_axis_tdata;
assign din.valid = s_axis_tvalid;
assign s_axis_tready = din.ready;

assign m_axis_tdata = dout.data;
assign m_axis_tvalid = dout.valid;
assign m_axis_tlast = dout.last;
assign dout.ready = m_axis_tready;

sample_buffer #(
  .DWIDTH(DWIDTH),
  .SAMPLE_DEPTH(SAMPLE_DEPTH)
) sample_buffer_i (
  .clk,
  .reset,
  .din,
  .dout
);

endmodule
