module mac #(
    parameter IN_WIDTH = 8,
    parameter IN_FRAC = 0,
    parameter OUT_WIDTH = 8,
    parameter OUT_FRAC = 0,
    parameter MULT_LAT = 3,
    parameter ADD_LAT = 1,
    parameter K = 1,
    parameter ROWS = 1,
    parameter COLS = 1,
    parameter COLS_IDX = 1,
    parameter ROWS_IDX = 1,
    parameter OWN_DELAY = 0        // Extra cycles this MAC holds its own result before sending it out (set in systolic_array.v)
)(
    input                      clk,
    input                      rst,
    input                      rst_accumulator_in,
    input                      stream_out_rdy_in,
    input       [IN_WIDTH-1:0] row_data_in,
    input       [IN_WIDTH-1:0] col_data_in,
    input       [IN_WIDTH-1:0] bypass_data_in,
    output reg  [IN_WIDTH-1:0] row_data_out,
    output reg  [IN_WIDTH-1:0] col_data_out,
    output reg                 rst_accumulator_out,
    output reg                 stream_out_rdy_out,
    output reg [OUT_WIDTH-1:0] psum_out
);

    // ------------------------------------------------------------------
    // Signal declarations (provided)
    // ------------------------------------------------------------------
    localparam COLS_WIDTH = (COLS > 1) ? $clog2(COLS) : 1;

    // Shift register that holds this MAC's own result for OWN_DELAY extra cycles
    reg  [OUT_WIDTH-1:0]    psum [0:(1 << COLS_WIDTH)-1];
    reg  [OUT_WIDTH-1:0]    psum_reg;
    reg  [OUT_WIDTH-1:0]    mult_out;

    wire [OUT_WIDTH-1:0]    multiplier_out;
    wire                    multiplier_done;

    wire [IN_WIDTH-1:0]     adder_in_A;
    wire [IN_WIDTH-1:0]     adder_in_B;
    wire [OUT_WIDTH-1:0]    adder_out;
    wire                    adder_done;

    // Bypass controls
    wire                    bypass_en;
    wire [31:0]             temp = COLS - 1;
    wire [COLS_WIDTH-1:0]   bypass_counter_max = temp[COLS_WIDTH-1:0];
    reg  [COLS_WIDTH-1:0]   bypass_counter;
    reg                     stream_started;
    reg                     stream_out_rdy_in_reg;


    // ------------------------------------------------------------------
    // Multiplier (provided)
    // ------------------------------------------------------------------
    multiplier #(
        .INPUT_A_WIDTH(IN_WIDTH),
        .INPUT_B_WIDTH(IN_WIDTH),
        .INPUT_A_FRAC(IN_FRAC),
        .INPUT_B_FRAC(IN_FRAC),
        .OUTPUT_WIDTH(OUT_WIDTH),
        .OUTPUT_FRAC(OUT_FRAC),
        .DELAY(MULT_LAT)
    ) mul (
        .clk(clk),
        .reset(rst),
        .stall(1'b0),
        .en(~rst),
        .a_in(row_data_in),
        .b_in(col_data_in),
        .out(multiplier_out),
        .done(multiplier_done)
    );

    // Register the multiplier output: products reach the adder 1 cycle after multiplier_done (provided)
    always @(posedge clk) begin
        if (rst) begin
            mult_out <= '0;
        end else if (multiplier_done) begin
            mult_out <= multiplier_out;
        end else begin
            mult_out <= '0;
        end
    end


    // ------------------------------------------------------------------
    // Adder / accumulator
    // ------------------------------------------------------------------
    //TODO [In-Class 1]: Choose the adder's two inputs.
    // adder_in_A: the new product.
    // - Which signal above holds the product, lined up with multiplier_done? (Look at the block just above.)
    // adder_in_B: what the new product is added to.
    // - Normally the adder keeps adding new products to its own running sum (adder_out).
    // - When rst_accumulator_in is high, a new dot product starts. What should be added to the new product then?
    //
    // Suggestions [In-Class 1]:
    //   • These are continuous assigns (combinational): no clock, no always block.
    //   • adder_in_A: multiplier_out is the raw pipeline output; mult_out is the same product
    //     registered once and forced to 0 when multiplier_done is low. Pick the one your reset
    //     timing in ctrl.v is counted against, and use it consistently.
    //   • adder_in_B: a 2:1 choice selected by rst_accumulator_in, e.g. (cond ? a : b).
    //     One side keeps the running sum (adder_out); the other side starts a new sum.
    //   • Check in trace.vcd: on the cycle rst_accumulator_in is high, adder_in_A should hold the
    //     FIRST product of the new dot product, and adder_out one cycle later should equal it.
    assign adder_in_A = '0;   // TODO: replace '0
    assign adder_in_B = '0;   // TODO: replace '0

    adder #(
        .INPUT_A_WIDTH(IN_WIDTH),
        .INPUT_B_WIDTH(IN_WIDTH),
        .INPUT_A_FRAC(IN_FRAC),
        .INPUT_B_FRAC(IN_FRAC),
        .OUTPUT_WIDTH(OUT_WIDTH),
        .OUTPUT_FRAC(OUT_FRAC),
        .DELAY(ADD_LAT)
    ) add (
        .clk(clk),
        .reset(rst),
        .stall(1'b0),
        .en(~rst && multiplier_done),
        .a_in(adder_in_A),
        .b_in(adder_in_B),
        .out(adder_out),
        .done(adder_done)
    );


    // ------------------------------------------------------------------
    //TODO [In-Class 1]: Pass row/col data and control signals to the next MAC
    // - Row data goes to the MAC on the right; column data, rst_accumulator, and stream_out_rdy
    //   go to the MAC below.
    // - Each hop between MACs takes exactly 1 clock cycle. What hardware gives a 1-cycle delay?
    // - Drive all four outputs: row_data_out, col_data_out, rst_accumulator_out, stream_out_rdy_out
    // - Clear them on rst.
    //
    // Suggestions [In-Class 1]:
    //   • One always @(posedge clk) block for all four outputs (they are declared output reg).
    //   • On rst: drive all four to 0.
    //   • Otherwise: each *_out gets its matching *_in (row_data_out <= row_data_in, ...).
    //   • Use nonblocking assignments (<=) so every MAC updates on the same edge.
    //   • Check in trace.vcd: PE(0,1).row_data_in should equal PE(0,0).row_data_in, one cycle later.
    //     PE(1,0).rst_accumulator_in should equal PE(0,0).rst_accumulator_in, one cycle later.
    // ------------------------------------------------------------------



    // ------------------------------------------------------------------
    // Hold this MAC's own result (provided)
    // psum[0] is the accumulator value one cycle later; psum[i] is i cycles later than psum[0].
    // OWN_DELAY (set per column in systolic_array.v) picks how long to hold the result.
    // ------------------------------------------------------------------
    always @(posedge clk) begin
        if (rst) psum[0] <= '0;
        else     psum[0] <= adder_out;
    end

    genvar i;
    generate
        for (i = 0; i < (1 << COLS_WIDTH) - 1; i = i + 1) begin : psum_propagate
            always @(posedge clk) begin
                if (rst) psum[i+1] <= '0;
                else     psum[i+1] <= psum[i];
            end
        end
    endgenerate

    always @(posedge clk) begin
        if (rst) psum_reg <= '0;
        else     psum_reg <= psum[OWN_DELAY];
    end


    // ------------------------------------------------------------------
    // Stream out: send this MAC's own result, then pass its right neighbor's results
    //
    // How it works, for one row of COLS MACs:
    // - Results move right -> left, one MAC per cycle: each MAC's psum_out feeds the bypass_data_in
    //   of the MAC on its left. Column 0's psum_out is the array output for that row.
    // - Every column gets its stream_out_rdy_in pulse on the same cycle (see ctrl.v).
    // - On that pulse, each MAC first sends its OWN result (psum_reg). For the next COLS-1 cycles it
    //   forwards whatever arrives on bypass_data_in from the right. This is "bypassing".
    // - OWN_DELAY (systolic_array.v) lines the own results up, so column 0 sends C[i][0], then
    //   C[i][1], C[i][2], ... arrive from the right one cycle apart.
    //
    // Signals you will need (declared above):
    // - stream_started        : 0 after reset, 1 forever after the first stream_out_rdy_in.
    //                           Before the first result, the MAC should output 0.
    // - stream_out_rdy_in_reg : stream_out_rdy_in delayed by 1 cycle.
    // - bypass_counter        : counts the COLS-1 bypass cycles. It starts the cycle after the pulse
    //                           (use stream_out_rdy_in_reg), counts up to bypass_counter_max, then
    //                           returns to 0.
    // - bypass_en             : 1 while this MAC is bypassing, i.e. while bypass_counter is not 0.
    //
    // Output mux (register psum_out on the clock):
    // - while bypassing                 : bypass_data_in
    // - otherwise, once stream_started  : psum_reg (this MAC's own result)
    // - otherwise                       : 0
    // ------------------------------------------------------------------

    //TODO [In-Class 1]: stream_started
    // Suggestions [In-Class 1]:
    //   • always @(posedge clk).
    //   • On rst: 0. When stream_out_rdy_in is high: set to 1. Otherwise: keep its value.
    //   • It never returns to 0 after reset; it only stops the MAC from sending garbage before
    //     its first real result.



    //TODO [In-Class 1]: stream_out_rdy_in_reg
    // Suggestions [In-Class 1]:
    //   • A single flop: always @(posedge clk), 0 on rst, otherwise copy stream_out_rdy_in.



    //TODO [In-Class 1]: bypass_en and bypass_counter
    // Suggestions [In-Class 1]:
    //   • bypass_en is a continuous assign: high whenever bypass_counter is not 0.
    //   • bypass_counter: always @(posedge clk), checked in this priority order:
    //       rst                                    → 0
    //       bypass_counter == bypass_counter_max   → 0   (done bypassing)
    //       stream_out_rdy_in_reg or bypass_en     → bypass_counter + 1   (start, or keep counting)
    //       otherwise                              → 0
    //   • For COLS = 2, bypass_counter_max = 1, so the counter is 1 for exactly one cycle.
    //   • Check in trace.vcd: after each stream_out_rdy_in pulse, bypass_en goes high 2 cycles later
    //     and stays high for COLS - 1 cycles.



    //TODO [In-Class 1]: Output mux (drive psum_out)
    // Suggestions [In-Class 1]:
    //   • always @(posedge clk), in the priority order from the explanation above:
    //       rst → 0;  bypass_en → bypass_data_in;  stream_started → psum_reg;  otherwise → 0
    //   • Check in trace.vcd: PE(0,0).psum_out shows its own result, then PE(0,1)'s result on the
    //     next cycle. row_data_out row 0 should show C[0][0], then C[0][1], back to back.



endmodule
