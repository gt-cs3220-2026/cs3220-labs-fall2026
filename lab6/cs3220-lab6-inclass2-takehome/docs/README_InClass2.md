# CS3220 Lab #6 In-Class 2: NxN Systolic Array

**In-Class 2: 20 pts.**

Lab 6 points:

| Portion | Points |
|---|---|
| In-Class 1: 2x2 Systolic Array | 20 pts |
| In-Class 2: NxN Systolic Array | 20 pts |
| Take-Home Part A: MxN Systolic Array (`N` = `K`) | 15 pts |
| Take-Home Part B: General-sized Systolic Array (`N` != `K`) | 15 pts |
| Take-Home Part C: AXI-Stream Interface | 15 pts |
| Take-Home Report | 15 pts |
| **Total** | **100 pts** |

This session builds on the In-Class 1 2x2 design. The skeleton in this folder already contains a working In-Class 1 solution, so you do not need to code it again. Run all commands from inside the [code/](../code) folder:

```
cd code
source init.sh
chmod +x *.sh
```

The background, testing procedures, and debugging tips from In-Class 1 are repeated at the end of this document.

**Notation**: A is M × K, B is K × N, and C is M × N, on an M × N array (`ROWS` = M, `COLS` = N). K is the inner dimension each PE sums over.


## Starting Point

[MAC.v](../code/MAC.v), [ctrl.v](../code/ctrl.v), and [systolic_array.v](../code/systolic_array.v) contain a working 2x2 design with `MULT_LAT` = 3:
- [MAC.v](../code/MAC.v) needs no changes for In-Class 2.
- [ctrl.v](../code/ctrl.v) uses the fixed numbers `RST_DELAY` = 4 and `STREAM_OUT_DELAY` = 6.
- [systolic_array.v](../code/systolic_array.v) uses 4 hand-written MAC instances, with `OWN_DELAY` = 1 for column 0 and 0 for column 1.

Before changing anything, run `./run_inclass1.sh`. It should report 5 / 5.

The `TODO [In-Class 2]` comments in the code mark what to change. If you prefer, you can start from your own In-Class 1 design instead.


## In-Class 2 Task (20 pts)

Generalize the In-Class 1 design to any square array where `M` = `N` = `K` (for example, a 4x4 array with `K` = 4). Every size and delay in your design should depend on parameters, not on fixed numbers.

This means two changes:
- In [systolic_array.v](../code/systolic_array.v), replace the 4 hand-written MAC instances with a generate block that works for any `ROWS` and `COLS`. The 4 instances will only ever work for 2x2, so `run_inclass2.sh` fails until you make this change.
- Replace every fixed number from In-Class 1 with a formula: `RST_DELAY` and `STREAM_OUT_DELAY` in [ctrl.v](../code/ctrl.v), and `OWN_DELAY` for each column.

Test command: `chmod +x run_inclass2.sh && ./run_inclass2.sh`

| Group | ROWS x COLS | K | MULT_LAT | NUM | SEED | Tests |
|---|---|---|---|---|---|---|
| Seeds | 4 x 4 | 4 | 3 | 10 | 1 to 5 | 5 |
| Latency | 4 x 4 | 4 | 2, 4, 5, 6 | 10 | 1 | 4 |
| Size | 8 x 8 | 8 | 3 | 10 | 1 | 1 |
| Length | 4 x 4 | 4 | 3 | 100 | 1 | 1 |
| Regression | 2 x 2 | 2 | 6 | 100 | 1 | 1 |

Expect 12 passes. Points are given in proportion to the number of passing tests. The last row re-checks the 2x2 array at a new multiplier latency, so the 2x2 case must still work.

To run a single test case:

```
make systolic_array ROWS=4 COLS=4 K=4 NUM_TESTS=10 SEED=1 MULT_LAT=3
cat results.log | grep PASSED
```


## Hints
Generate block:
- Compare the PE(0,1) and PE(1,1) instances in [systolic_array.v](../code/systolic_array.v). Which connections are the same pattern with a different index? That pattern becomes one instance inside two nested loops (`genvar r` over `ROWS`, `genvar c` over `COLS`).
- Replace the named wires (`row_00_01`, ...) with 2-D wire arrays, for example `wire [IN_WIDTH-1:0] row_wire [0:ROWS-1][0:COLS];`. Let `row_wire[r][c]` feed PE(r,c) and `row_wire[r][c+1]` be its output. Making each array one entry larger than the grid gives the edge MACs a slot to read from or write to.
- Handle the edges with separate loops or with `if` inside the generate block: the top row reads from `ctrl` and `col_data_in`, the left column reads from `row_data_in`, and the right column has no neighbor to bypass from.
- Slice packed buses by index, for example `row_data_in[IN_WIDTH*r +: IN_WIDTH]`.
- Name your generate blocks (`begin : g_row`) so the MACs are easy to find in the waveform.

If a test fails:
- `run_inclass2.sh` runs its tests one after another, so `trace.vcd` is from the last test only. Rerun the failing case on its own with `make` (see the command above) before opening the waveform.
- **Passes at `MULT_LAT` = 3, fails at other latencies:** a delay is still a fixed number.
- **Passes for 2x2, fails for 4x4 or 8x8:** check `OWN_DELAY`, the bypass counter's range, and your wire array indexing.
- **Fails only for 8x8:** check array sizes and loop bounds (off-by-one at the edges).
- **Build errors after the change:** check that each wire array has an entry for the edge MACs.

Formulas:
- `OWN_DELAY` becomes a formula in `COLS` and the column index `c`. For `COLS` = 2, it must give 1 for column 0 and 0 for column 1.
- `RST_DELAY` and `STREAM_OUT_DELAY` become formulas in `MULT_LAT`, `ACC_LAT`, and `COLS`. At `MULT_LAT` = 3 and `COLS` = 2, they must give 4 and 6.


## Rules and Potential Violations
1. adder and multiplier instances have to be used and used as they are
2. systolic array IOs **and** default parameters cannot be changed
3. for MAC's parameters, as long as we can pass the MULT_LAT parameter in from the top module (systolic_array.v), it's fine
4. Any changes to Makefile, test*.cpp, adder and multiplier module definition will not be considered
5. Helper modules must be placed in MAC.v or ctrl.v. Do not add new `.v` files


## FAQ
[Q] Useful lecture links for systolic array design?

https://www.youtube.com/watch?v=cmy7LBaWuZ8&pp=ygUPc3lzdG9saWMgYXJhYXkg


# Reference from In-Class 1

## Systolic Array Overview

In this lab, you'll implement an MxN systolic array, with output stationary design. We will focus only on the matrix multiplication operation.

**IMPORTANT!! Otherwise you will be lost during this lab! Please be sure to read through the original systolic array paper before you start:**

- [link1](https://www.princeton.edu/~kung/papers_pdf/New%20Folder/VLSI%20Array%20Processors.pdf)

To enhance your comprehension and offer more specific guidance on implementation, we have included a tutorial report detailing the systolic array design and implementation. This report will direct you on where to begin and outline the necessary steps:
- [link2](CS3220_systolic_array_luke_zhang.pdf)



### Problem Description


The code skeleton is provided in:
- [systolic_array.v](../code/systolic_array.v)
- [MAC.v](../code/MAC.v)
- [ctrl.v](../code/ctrl.v)
- [adder.v](../code/adder.v)
- [multiplier.v](../code/multiplier.v)
- [synchronus_fifo.v](../code/synchronus_fifo.v)


Out of the above files, you will need to work on [systolic_array.v](../code/systolic_array.v), [MAC.v](../code/MAC.v), and [ctrl.v](../code/ctrl.v) to complete the systolic array design.


Finish all the TODOs in the code; or you can start from scratch if you prefer. The only major requirement is that you are not allowed to change the interface of the systolic array [systolic_array.v](../code/systolic_array.v). Although we provide the interfaces for [MAC.v](../code/MAC.v) and [ctrl.v](../code/ctrl.v), you are free to change them as you see fit.

Todos in the skeleton codes provided are intended to guide you through the implementation process and provide some hints. However, you are free to modify the code as you see fit.

**Note:** The Makefile only compiles the files listed above. If you write a helper module (for example, a delay line), put it inside [MAC.v](../code/MAC.v) or [ctrl.v](../code/ctrl.v). Do not create a new `.v` file for it.



Useful hints:
- Pay very special attention to the timing of the signals. At what clock cycle should the signals be expected?
- What if two signals are expected to arrive at the same time? But one of them is a little falling behind? Remember Flip-Flop is a very useful tool to help you with this; output of a Flip-Flop is always one clock cycle behind the input; can you use this to help you with the timing?
- Generate block in Verilog is a good way to save repetitive code.
- When debugging, start with small sized systolic array, and zoom in into a single MAC unit. This will help you understand the timing of the signals.
- More hints may be available in the code skeleton, please read through them carefully.


### Testing Procedures

Testing pattern and assumptions:
- The input data will be pre-skewed and pre-rotated. You don't need to implement the skewing and rotating logic. For example:
    - For matrix multiplication A*B=C:
![Alt text](imgs/m1.png)
    - A: Streamed to ```row_data_in``` [systolic_array.v](../code/systolic_array.v) from left to right as (note topmost is the first row): ![Alt text](imgs/m2.png)
    - B: Streamed to ```col_data_in``` [systolic_array.v](../code/systolic_array.v) from top to bottom as (note leftmost is the first column): ![Alt text](imgs/m3.png)
    - C: Expected to be streamed out from ```row_data_out``` [systolic_array.v](../code/systolic_array.v) from left to right as (note topmost is the first row): ![Alt text](imgs/m4.png)
- Multiple matrix multiplication operations will be performed in sequence. Your design is expected to be able to handle the next matrix multiplication operation immediately after the previous one is finished.
    - Assume the same matrix multiplication operation as above is performed again, the input data will be streamed in the same way as above.
    - A: Streamed to ```row_data_in``` [systolic_array.v](../code/systolic_array.v) from left to right as (note topmost is the first row): ![Alt text](imgs/m5.png)
    - B: Streamed to ```col_data_in``` [systolic_array.v](../code/systolic_array.v) from top to bottom as (note leftmost is the first column): ![Alt text](imgs/m6.png)
    - C: Expected to be streamed out from ```row_data_out``` [systolic_array.v](../code/systolic_array.v) from left to right as (note topmost is the first row): ![Alt text](imgs/m7.png)

**Notation**

The lab computes C = A × B on an M × N systolic array.
- **M**: rows of A and C, and rows of the array (`ROWS`)
- **N**: columns of B and C, and columns of the array (`COLS`)
- **K**: columns of A and rows of B. Each PE sums K products, and each matrix multiplication takes K input cycles (`K`).

So A is M × K, B is K × N, and C is M × N.

Example: `ROWS=2 COLS=4 K=2` means A is 2×2, B is 2×4, C is 2×4, on a 2×4 array.

Test script, a `NUM` number of random tests of A (`M`x`K`) * B (`K`x`N`) matrix multiplications will be performed, on systolic array with size `M`x`N`. You can run the test script by:

```
make systolic_array ROWS=${M} COLS=${N} K=${K} NUM_TESTS=${NUM}
cat results.log | grep PASSED
```

How a test runs (`make systolic_array`):
1. `data_gen.py` makes random A and B, pre-skews them, and writes the expected C.
2. Verilator turns your Verilog into a C++ model and builds it with the testbench, `test_systolic_array.cpp`.
3. The testbench drives one input beat per cycle and records `row_data_out` every cycle. It also writes `trace.vcd`.
4. `data_gen.py` compares your output with the expected C and writes PASSED or FAILED to `results.log`.

All code files are in the [code/](../code) folder. Run every command from inside it:

```
cd code
source init.sh
```


## How the Array Works

The in-class slides walk through a 2x2 example cycle by cycle. In short:

**Dataflow**
- PE(i,j) stays in place and owns one output, C[i][j].
- A's rows move right and B's columns move down, one PE per cycle.
- PE(i,j) gets its first pair `i + j` cycles after PE(0,0).
- Matrix multiplications arrive back to back, every `K` cycles, with no gap.

**The two control signals**

| Signal | The testbench sends it | `ctrl.v` delays it until | Then the PE |
|---|---|---|---|
| `rst_accumulator` | With the first input of each matmul (`counter % K == 0`) | The first product reaches the adder | Starts a new sum from that product |
| `stream_out_rdy` | With the last input of each matmul (`counter % K == K-1`) | The last column's sum is done | Sends its own result, then forwards its right neighbors' results |

- The testbench ignores `MULT_LAT`. All latency compensation is in `ctrl.v`.
- `ctrl.v` drives the top row only: bit `j` goes to PE(0,j). Each MAC passes both signals to the MAC below it, 1 cycle later.

**Inside one MAC**
- Product path: multiplier (`MULT_LAT` cycles), then a product register (1 cycle), then the adder.
- The next matmul starts right away and overwrites the accumulator. So the MAC keeps a short history of past sums (`psum[0]`, `psum[1]`, ...), and `OWN_DELAY` picks the one from when this column finished.

**Getting results out**
- Results leave the array only from column 0, one value per row per cycle. No large output mux.
- On `stream_out_rdy`, every PE sends its own result. For the next `COLS - 1` cycles (the bypass counter), it forwards results from its right.
- Row 0 comes out as C[0][0], C[0][1], ... Row `i` comes out 1 cycle after row `i - 1`.


## Debugging Tips
- Every build dumps a waveform to `trace.vcd`. Open it with the Signal Viewer extension, or download it and use GTKWave.
- On a FAILED test, open `results.log`. It prints the expected (`Gold`) and actual (`Result`) output streams.
- The checker finds the first expected output row, then the last one, and compares everything in between. Leading zeros before your first result are fine, but a bubble or wrong value between results fails the test.
- Name your generate blocks so internal MAC signals are easy to find in the waveform.
- The run scripts run their tests one after another, so `trace.vcd` and the `.bin` files are from the last test only. To debug a specific failing test, rerun it on its own with `make`.
- Always name a target (`make systolic_array`). Plain `make` does not work.

Check your design in this order, in `trace.vcd`:
1. **Pass-through:** PE(0,1) sees PE(0,0)'s row data 1 cycle later; PE(1,0) sees its column data and control signals 1 cycle later.
2. **Reset:** `rst_accumulator_in` is high on the same cycle `adder_in_A` holds the first product of a matmul.
3. **Sums:** each `adder_out` reaches the right C[i][j] value. Work one out by hand for PE(0,0).
4. **Stream-out:** on the `stream_out_rdy_in` cycle, `psum[OWN_DELAY]` holds the finished sum, not part of the next matmul.
5. **Output:** `row_data_out` shows each row in column order, back to back.

If a step fails, the problem is usually in the step before it.
