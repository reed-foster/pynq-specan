// multi_fft.sv - Reed Foster
// FFTs for 512, 1024, 2048, and 4096-point analysis

module multi_fft #(
  parameter int DATA_WIDTH = 24,
  parameter int N_FFT_MIN = 9,
  parameter int NUM_RES = 4
) (
  input wire clk, reset,
  Axis_If.Slave data_in,
  Axis_If.Master data_out
);

assign data_in.ready = 1'b1;

generate
  for (genvar i=0; i < NUM_RES; i++) begin
    Axis_If #(.DWIDTH(2*DATA_WIDTH)) fft_in;
    Axis_If #(.DWIDTH(2*DATA_WIDTH)) fft_out;
    // we'll first take an FFT of the left channel, then the right
    logic [2*DATA_WIDTH-1:0] buffer_data;

    logic [N_FFT_MIN+i-1:0] write_addr, read_addr;
   
    // match flow control signals with BRAM read latency
    logic [1:0] fft_last, fft_valid;
    assign fft_in.last = fft_last[1];
    assign fft_in.valid = fft_valid[1];
    logic channel;  // alternate between left and right channels

    assign fft_in.data = {{DATA_WIDTH{1'b0}}, (channel == 0) ? buffer_data[DATA_WIDTH-1:0] : buffer_data[2*DATA_WIDTH-1:DATA_WIDTH]};

    always @(posedge clk) begin
      if (reset) begin
        write_addr <= '0;
        read_addr <= '0;
        fft_last <= '0;
        fft_valid <= '0;
        channel <= '0;
      end else begin
        fft_valid[0] <= 1'b1;
        // match flow control with BRAM
        fft_last <= fft_last << 1;
        fft_valid <= fft_valid << 1;
        // increment write counter as long as we have new input data
        if (data_in.valid) begin
          write_addr <= write_addr + 1'b1;
        end
        // increment read counter whenever the FFT can process new samples
        if (fft_in.ready) begin
          if (read_addr == 512 * (1 << i) - 1) begin
            fft_last[0] <= 1'b1;
            read_addr <= '0;
            channel <= ~channel;
          end else begin
            fft_last[0] <= 1'b0;
            read_addr <= read_addr + 1'b1;
          end
        end
      end
    end
    
    // Similar to a frame buffer, the input data is continuously written to
    // this buffer, and is read out by the fft core
    xpm_memory_sdpram #(
       .ADDR_WIDTH_A(N_FFT_MIN + i),
       .ADDR_WIDTH_B(N_FFT_MIN + i),
       .MEMORY_SIZE((1 << (i + N_FFT_MIN)) * 2 * DATA_WIDTH),
       .BYTE_WRITE_WIDTH_A(2*DATA_WIDTH),
       .WRITE_DATA_WIDTH_A(2*DATA_WIDTH),
       .READ_DATA_WIDTH_B(2*DATA_WIDTH),
       .READ_LATENCY_B(2),
       .WRITE_MODE_B("read_first")
    )
    data_buffer_i (
       .clka(clk),
       .clkb(clk),
       .rstb(reset),
    
       .addra(write_addr),
       .addrb(read_addr),
       .dina(data_in.data),
       .doutb(buffer_data),
       .ena(data_in.valid),
       .wea(data_in.valid),
       .enb(1'b1),
    
       .injectdbiterra(1'b0),
       .injectsbiterra(1'b0),
       .dbiterrb(),
       .sbiterrb(),
       .regceb(1'b1),
       .sleep(1'b0)
    );

    fft #(.DATA_WIDTH(DATA_WIDTH), .N_FFT(1 << (i + N_FFT_MIN))) fft_i (
      .clk,
      .data_in(fft_in),
      .data_out(fft_out)
    );
    end
endgenerate

endmodule;
