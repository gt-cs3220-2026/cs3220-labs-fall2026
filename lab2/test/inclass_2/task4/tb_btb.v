module tb_btb (
  input wire clk, reset, rd_ena, wr_ena,
  input wire [31:0] rd_sel, wr_sel, wr_data,
  output wire [31:0] out_data,
  output wire outs_valid
);
  BTB dut (.clk(clk), .reset(reset), .rd_ena(rd_ena), .rd_sel(rd_sel),
           .out_data(out_data), .outs_valid(outs_valid),
           .wr_ena(wr_ena), .wr_sel(wr_sel), .wr_data(wr_data));
endmodule
