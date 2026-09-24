module tb_bhr (
  input wire clk, reset, wr_ena,
  input wire wr_data,
  output wire [7:0] out
);
  BHR dut (.clk(clk), .reset(reset), .wr_ena(wr_ena), .wr_data(wr_data), .out(out));
endmodule
