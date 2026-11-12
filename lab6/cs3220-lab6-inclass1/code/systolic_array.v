module systolic_array #(
    parameter IN_WIDTH          = 8,
    parameter IN_FRAC           = 0,
    parameter OUT_WIDTH         = 8,
    parameter OUT_FRAC          = 0,
    parameter MULT_LAT          = 3,                 // Multiplication latency
    parameter ACC_LAT           = 1,                 // Addition latency (<=1, not support pipelined acc)
    parameter ROWS              = 4,                 // Row number of systolic array
    parameter K                 = 4,
    parameter COLS              = 4                  // Column number of systolic array
)(
    input                       clk,
    input                       rst_in,
    input                       rst_accumulator_rdy_in, // If 1, reset accumulator in array
    input                       stream_out_rdy_in_in,      // If 1, stream acc result out

    input [IN_WIDTH*ROWS-1:0]   row_data_in_in,
    input [IN_WIDTH*COLS-1:0]   col_data_in_in,
    output [OUT_WIDTH*ROWS-1:0] row_data_out
);
    // ------------------------------------------------------------------
    // Register inputs (provided) // something todo with verilator timing issue
    // ------------------------------------------------------------------
    reg       rst;
    reg       rst_accumulator_rdy;
    reg       stream_out_rdy;
    reg [IN_WIDTH*ROWS-1:0] row_data_in;
    reg [IN_WIDTH*COLS-1:0] col_data_in;

    always @(posedge clk) begin
        rst                 <= rst_in;
        rst_accumulator_rdy <= rst_accumulator_rdy_in;
        stream_out_rdy      <= stream_out_rdy_in_in;
        row_data_in         <= row_data_in_in;
        col_data_in         <= col_data_in_in;
    end


    // ------------------------------------------------------------------
    // Ctrl unit (provided)
    // One rst_accumulator and one stream_out_rdy signal per column, delayed in ctrl.v
    // ------------------------------------------------------------------
    wire [COLS-1:0] control_rst_accumulator_rdy;
    wire [COLS-1:0] control_stream_out_rdy;

    ctrl #(
        .IN_WIDTH(IN_WIDTH),
        .OUT_WIDTH(OUT_WIDTH),
        .ROWS(ROWS),
        .COLS(COLS),
        .MULT_LAT(MULT_LAT),
        .ACC_LAT(ACC_LAT)
    ) ctrl_0 (
        .clk(clk),
        .rst(rst),
        .input_rst_accumulator(rst_accumulator_rdy),
        .input_stream_out_rdy(stream_out_rdy),
        .rst_accumulator(control_rst_accumulator_rdy),
        .stream_out_rdy(control_stream_out_rdy)
    );


    // ------------------------------------------------------------------
    // In-Class 1: 2x2 array built from 4 MAC instances
    //
    //              col_data_in[0]      col_data_in[1]
    //                   |                   |
    //   row_data_in[0] -> PE(0,0) ----------> PE(0,1)
    //                   |                   |
    //   row_data_in[1] -> PE(1,0) ----------> PE(1,1)
    //
    // - Row data flows left -> right. Column data and both control signals flow top -> bottom.
    // - Results (psum_out) flow right -> left and leave the array from column 0 on row_data_out.
    // ------------------------------------------------------------------

    // Wires between MACs (provided)
    // Naming: <signal>_<from PE>_<to PE>, e.g. row_00_01 is row data from PE(0,0) to PE(0,1)
    wire [IN_WIDTH-1:0]  row_00_01, row_10_11;        // row data, left -> right
    wire [IN_WIDTH-1:0]  col_00_10, col_01_11;        // column data, top -> bottom
    wire                 rst_00_10, rst_01_11;        // rst_accumulator, top -> bottom
    wire                 so_00_10,  so_01_11;         // stream_out_rdy, top -> bottom
    wire [OUT_WIDTH-1:0] psum_00, psum_01;            // psum_out of row 0 MACs
    wire [OUT_WIDTH-1:0] psum_10, psum_11;            // psum_out of row 1 MACs

    //TODO [In-Class 1]: OWN_DELAY for each column
    // - Both columns get the same stream_out_rdy pulse from ctrl.v (see ctrl.v)
    // - Column 0 must send its own result first, then pass column 1's result one cycle later
    // - How many extra cycles should each column hold its own result so the row comes out in order?
    //
    // Suggestions [In-Class 1]:
    //   • psum[0] holds the accumulator from 1 cycle ago, psum[1] from 2 cycles ago, and so on.
    //     OWN_DELAY picks which one the MAC sends.
    //   • The shared stream_out_rdy pulse is timed for the LAST column (column 1 in a 2x2 array).
    //     How many cycles before column 1 did column 0 finish its sum? That is how far back
    //     column 0 must look. Column 1 is the last column itself.
    //   • Check in trace.vcd: on the cycle each MAC's stream_out_rdy_in is high, psum[OWN_DELAY]
    //     should hold that MAC's finished sum, not a partial sum of the next matmul.
    localparam OWN_DELAY_COL0 = 0;   // TODO
    localparam OWN_DELAY_COL1 = 0;   // TODO


    // PE(0,0): worked example, fully connected (provided)
    mac #(
        .IN_WIDTH(IN_WIDTH), .IN_FRAC(IN_FRAC), .OUT_WIDTH(OUT_WIDTH), .OUT_FRAC(OUT_FRAC),
        .MULT_LAT(MULT_LAT), .ADD_LAT(ACC_LAT), .K(K), .ROWS(ROWS), .COLS(COLS),
        .ROWS_IDX(0), .COLS_IDX(0), .OWN_DELAY(OWN_DELAY_COL0)
    ) mac_00 (
        .clk(clk),
        .rst(rst),
        .rst_accumulator_in(control_rst_accumulator_rdy[0]),   // top row: from ctrl, column 0
        .stream_out_rdy_in(control_stream_out_rdy[0]),         // top row: from ctrl, column 0
        .row_data_in(row_data_in[IN_WIDTH*0 +: IN_WIDTH]),     // left column: from row_data_in, row 0
        .col_data_in(col_data_in[IN_WIDTH*0 +: IN_WIDTH]),     // top row: from col_data_in, column 0
        .bypass_data_in(psum_01),                              // results from the MAC to its right
        .row_data_out(row_00_01),                              // to PE(0,1)
        .col_data_out(col_00_10),                              // to PE(1,0)
        .rst_accumulator_out(rst_00_10),                       // to PE(1,0)
        .stream_out_rdy_out(so_00_10),                         // to PE(1,0)
        .psum_out(psum_00)                                     // leaves the array on row_data_out, row 0
    );

    // Suggestions [In-Class 1] for connecting PE(0,1), PE(1,0), and PE(1,1):
    //   • Follow PE(0,0). Every port connects to one of: ctrl, row_data_in/col_data_in, a named
    //     wire, a constant, or nothing.
    //   • Use the wire names: an *_out port drives the wire that names this PE as "from";
    //     an *_in port reads the wire that names this PE as "to" (row_00_01: PE(0,0) -> PE(0,1)).
    //   • Inputs from outside the array are sliced by index: col_data_in[IN_WIDTH*1 +: IN_WIDTH]
    //     is column 1; control_rst_accumulator_rdy[1] is column 1's reset.
    //   • No right neighbor: tie bypass_data_in to '0. Nothing to drive: leave the port empty, e.g. .row_data_out().
    //   • Check: every named wire should have exactly one driver (an *_out port) and one reader.

    //TODO [In-Class 1]: PE(0,1): top row, right column
    // - Where do its control signals and column data come from? (Top row, like PE(0,0), but column 1)
    // - Where does its row data come from?
    // - It has no MAC to its right. What should bypass_data_in be?
    // - Nothing is to its right, so leave row_data_out unconnected: .row_data_out()
    mac #(
        .IN_WIDTH(IN_WIDTH), .IN_FRAC(IN_FRAC), .OUT_WIDTH(OUT_WIDTH), .OUT_FRAC(OUT_FRAC),
        .MULT_LAT(MULT_LAT), .ADD_LAT(ACC_LAT), .K(K), .ROWS(ROWS), .COLS(COLS),
        .ROWS_IDX(0), .COLS_IDX(1), .OWN_DELAY(OWN_DELAY_COL1)
    ) mac_01 (
        .clk(clk),
        .rst(rst),
        .rst_accumulator_in(/* TODO */),
        .stream_out_rdy_in(/* TODO */),
        .row_data_in(/* TODO */),
        .col_data_in(/* TODO */),
        .bypass_data_in(/* TODO */),
        .row_data_out(/* TODO */),
        .col_data_out(/* TODO */),
        .rst_accumulator_out(/* TODO */),
        .stream_out_rdy_out(/* TODO */),
        .psum_out(/* TODO */)
    );

    //TODO [In-Class 1]: PE(1,0): bottom row, left column
    // - Its control signals and column data come from the MAC above it, not from ctrl
    // - Nothing is below it, so leave col_data_out, rst_accumulator_out, and stream_out_rdy_out unconnected
    mac #(
        .IN_WIDTH(IN_WIDTH), .IN_FRAC(IN_FRAC), .OUT_WIDTH(OUT_WIDTH), .OUT_FRAC(OUT_FRAC),
        .MULT_LAT(MULT_LAT), .ADD_LAT(ACC_LAT), .K(K), .ROWS(ROWS), .COLS(COLS),
        .ROWS_IDX(1), .COLS_IDX(0), .OWN_DELAY(OWN_DELAY_COL0)
    ) mac_10 (
        .clk(clk),
        .rst(rst),
        .rst_accumulator_in(/* TODO */),
        .stream_out_rdy_in(/* TODO */),
        .row_data_in(/* TODO */),
        .col_data_in(/* TODO */),
        .bypass_data_in(/* TODO */),
        .row_data_out(/* TODO */),
        .col_data_out(/* TODO */),
        .rst_accumulator_out(/* TODO */),
        .stream_out_rdy_out(/* TODO */),
        .psum_out(/* TODO */)
    );

    //TODO [In-Class 1]: PE(1,1): bottom row, right column
    // - Combine what you did for PE(0,1) and PE(1,0)
    mac #(
        .IN_WIDTH(IN_WIDTH), .IN_FRAC(IN_FRAC), .OUT_WIDTH(OUT_WIDTH), .OUT_FRAC(OUT_FRAC),
        .MULT_LAT(MULT_LAT), .ADD_LAT(ACC_LAT), .K(K), .ROWS(ROWS), .COLS(COLS),
        .ROWS_IDX(1), .COLS_IDX(1), .OWN_DELAY(OWN_DELAY_COL1)
    ) mac_11 (
        .clk(clk),
        .rst(rst),
        .rst_accumulator_in(/* TODO */),
        .stream_out_rdy_in(/* TODO */),
        .row_data_in(/* TODO */),
        .col_data_in(/* TODO */),
        .bypass_data_in(/* TODO */),
        .row_data_out(/* TODO */),
        .col_data_out(/* TODO */),
        .rst_accumulator_out(/* TODO */),
        .stream_out_rdy_out(/* TODO */),
        .psum_out(/* TODO */)
    );

    //TODO [In-Class 1]: Array outputs
    // - Which MAC's psum_out leaves the array for each row?
    // Suggestions [In-Class 1]:
    //   • Results flow right -> left, so each row's output comes from that row's column 0 MAC.
    //   • Check in trace.vcd: row_data_out row 1 should look like row 0, one cycle later.
    assign row_data_out[OUT_WIDTH*0 +: OUT_WIDTH] = psum_00;   // row 0 (provided)
    assign row_data_out[OUT_WIDTH*1 +: OUT_WIDTH] = '0;        // row 1: TODO, replace '0

endmodule
