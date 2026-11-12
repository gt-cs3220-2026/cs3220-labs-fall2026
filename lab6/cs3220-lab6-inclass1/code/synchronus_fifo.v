module synchronous_fifo #(
  parameter               DEPTH       = 8,
  parameter               DATA_WIDTH  = 8
) (
  input                   clk,
  input                   rst_n,
  input                   w_en,
  input                   r_en,
  input  [DATA_WIDTH-1:0] data_in,
  output [DATA_WIDTH-1:0] data_out,
  output                  full,
  output                  half_full,
  output                  empty
);
  
  // Additional 1 bit for w_ptr, r_ptr to determine full/empty
  reg [$clog2(DEPTH):0] w_ptr, r_ptr;
  reg [DATA_WIDTH-1:0] fifo[0:(1 << $clog2(DEPTH))-1];

  
  // Determine empty/full
  wire empty_int     = (w_ptr[$clog2(DEPTH)]     == r_ptr[$clog2(DEPTH)]);
  wire full_or_empty = (w_ptr[$clog2(DEPTH)-1:0] == r_ptr[$clog2(DEPTH)-1:0]);
  assign full      = full_or_empty & !empty_int;
  assign empty     = full_or_empty & empty_int;
  
  wire [31:0] temp = (1 << ($clog2(DEPTH)-1));
  wire [$clog2(DEPTH)-1:0] half_size  = temp[$clog2(DEPTH)-1:0];
  wire [$clog2(DEPTH)-1:0] difference = w_ptr[$clog2(DEPTH)-1:0] - r_ptr[$clog2(DEPTH)-1:0];
  assign half_full = difference >= half_size;

  // Set Default values on reset.
  always@(posedge clk) begin
    if(rst_n) begin
        r_ptr         <= 0;
    end else if(r_en & !empty) begin
        r_ptr         <= r_ptr + 1;
    end
    if(rst_n) begin
        w_ptr         <= 0;
    end else if(w_en & !full)begin
        w_ptr         <= w_ptr + 1;
        fifo[w_ptr[$clog2(DEPTH)-1:0]]   <= data_in;
    end
  end
  
  assign data_out = fifo[r_ptr[$clog2(DEPTH)-1:0]];

endmodule


