module tb_pht (
  input wire clk, reset, wr_ena, wr_data,
  input wire [7:0] rd_sel, wr_sel,
  output wire out
);
  PHT dut (.clk(clk), .reset(reset), .rd_sel(rd_sel), .out(out),
           .wr_sel(wr_sel), .wr_data(wr_data), .wr_ena(wr_ena));
endmodule
