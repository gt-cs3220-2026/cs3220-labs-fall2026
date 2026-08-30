module bf16 #(
    parameter DATA_WIDTH = 16,
    parameter INST_WIDTH = 2
)(
    input                   i_clk,
    input                   i_rst_n,
    input  [DATA_WIDTH-1:0] i_data_a,
    input  [DATA_WIDTH-1:0] i_data_b,
    input  [INST_WIDTH-1:0] i_inst,
    input                   i_valid,
    output [DATA_WIDTH-1:0] o_data,
    output                  o_valid
);

    // i_inst: 0 = add, 1 = mul, 2 = div
    // TODO: Implement the BF16 unit

endmodule
