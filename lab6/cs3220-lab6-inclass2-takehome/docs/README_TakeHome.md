# CS3220 Lab #6 Take-Home: General Systolic Arrays and AXI-Stream

**Take-Home: 60 pts** (Part A: 15 pts, Part B: 15 pts, Part C: 15 pts, Report: 15 pts)

***Submission ddl***: Dec. 1st (tentative)

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

The take-home builds on your In-Class 2 design. Run all commands from inside the [code/](../code) folder. See [README_InClass2.md](README_InClass2.md) for the background, code structure, testing procedures, and debugging tips.

**Notation**: A is M × K, B is K × N, and C is M × N, on an M × N array (`ROWS` = M, `COLS` = N). K is the inner dimension each PE sums over. See [README_InClass2.md](README_InClass2.md) for details.

All three parts and the report are required. Part C uses your Part A and B design, so finish them in order.


## Running Tests

- **Setup:** in every new terminal, run `cd code` and then `source init.sh`.
- **Always name a target:** `make systolic_array`, `make systolic_array_nk`, or `make systolic_array_axis`. Plain `make` does not work.
- **Reading a grading script's output:** it prints a line like "expect 5 passes", then one `PASSED!` per passing test. A failing test prints nothing, so count the `PASSED!` lines.
- **Debugging a failure:** the grading scripts end with `make clean`, which deletes `results.log`, the `.bin` files, and `trace.vcd`. Rerun the failing case on its own with `make`, then open `results.log` and `trace.vcd`.
- **Run time:** each full `run_axis.sh` run took about 15 to 20 minutes in TA testing. Debug with single tests first.


### Part A: MxN Systolic Array (15 pts)

Generalize your In-Class 2 design to MxN arrays, where `M` and `N` can differ, with `N` = `K`.

During the actual grading for Part A, we will use
- `NUM >= 1000`
- `N = K`

Detailed parameters will not be disclosed.


Grading command: `chmod +x run.sh && ./run.sh`

You design should be robust and the grading rubrics as follows:
- Test different `SEED` (**3pts**)
- Test different `MULT_LAT` (Multiplier Latency) (**3pts**)
- Test different `M` and `N` (**3pts**)
- Test different `NUM` (**3pts**)
- Test combined parameter sweep (**3pts**)

Single test example: `make systolic_array ROWS=2 COLS=4 K=4 NUM_TESTS=10 SEED=1`, then `cat results.log | grep PASSED`

In your report, explain what your In-Class 2 (NxN) design needed in order to support MxN arrays, and what you changed, if anything (see [Report](#report-15-pts)).

**Hints**
- Square arrays hide `ROWS`/`COLS` mix-ups. Check every place you use either one: wire array sizes, loop bounds, delays, and `OWN_DELAY`.
- Delays that depend on the number of columns should use `COLS`, never `ROWS`.
- Start with small rectangular cases like 2x4 (`K` = 4) and 4x2 (`K` = 2). They are quick to run and catch most mistakes.


### Part B: General-sized Systolic Arrays (15 pts)

In Part A, we worked with systolic arrays with size restricted to `N`=`K`. Now, let's explore what happens when `N` and `K` are not equal. Try experimenting with different parameters in the systolic array implementation (you may also adjust the number of trials in the testing script). You'll likely observe that the systolic array fails certain test cases.

**Part B.1 (graded in the Report)**: Debug General-sized Array Failures

Analyze the waveforms and code of the failing cases. Write a brief explanation identifying why the implementation fails when working with non-square systolic arrays. Include it in your report.

**Part B.2 (15pts)**: Support General-sized Arrays

Based on your analysis from Part B.1, modify the original code to support general-sized systolic arrays, i.e., cases of `N`!=`K`. You may need to modify the entire implementation. Your implementation must:

- Maintain the same input and output stream interface as the previous section
- Avoid using large multiplexers (scaled to array dimensions) for input or output selection

In your report, describe what you changed in your design to support `N` != `K`.


**Testing `N` < `K`: use `make systolic_array_nk`**
- Why? (First read the last hint below) In these cases, a single MAC's own results won't be immediately ready after it bypass results from the previous MACs. Therefore, MACs will output zero in between.
- These gaps are expected. The normal checker (`make systolic_array`) rejects any gap, so it reports FAILED even for a correct design.
- `make systolic_array_nk` takes the same parameters, but checks with [data_gen_nk.py](../code/data_gen_nk.py). It removes the gaps from each row's output, then compares the values in order.
- Example: `make systolic_array_nk ROWS=4 COLS=2 K=4 NUM_TESTS=100`, then `cat results.log | grep PASSED`
- For `N` >= `K`, keep using `make systolic_array`. Gaps there are real errors.
- What if `N` > `K`?


**Hints**
- Consider the timing from a single MAC unit's perspective:
    - When will results be ready for different array dimensions and different sizes?
    - What happens if a MAC's result is ready, but it needs to wait for results from MACs to its right?

- Think about maintaining output stream order
    - Could the synchronous FIFO ([synchronus_fifo.v](../code/synchronus_fifo.v), provided; the module is named `synchronous_fifo`) be useful here? Note that its `rst_n` port resets the FIFO when it is **high**, despite the name, so connect it to `rst` directly.

- **You can adjust the depth of the synchronous FIFO according to the actual difference between `N` and `K` or simply use a large depth, e.g., 128.**
    - Why?: What if the FIFO is full or empty? We should not be reading or writing to the FIFO, which is like some stall of the computation. However, at current lab, we have not included the implementation to propagate the stall through the systolic array. The next lab will cover this part.


Grading command (your Part B code must still pass Part A). `run_nk.sh` runs 2 `N` > `K` tests and 2 `N` < `K` tests, each worth **3.75pts**:
- `chmod +x run.sh && ./run.sh`
- `chmod +x run_nk.sh && ./run_nk.sh`

Single test examples, then `cat results.log | grep PASSED`:
- `N` > `K`: `make systolic_array ROWS=4 COLS=4 K=2 NUM_TESTS=100`
- `N` < `K`: `make systolic_array_nk ROWS=4 COLS=2 K=4 NUM_TESTS=100`


### Part C: AXI-Stream Interface (15 pts)

Wrap your systolic array in an AXI-Stream (AXIS) interface. This is the same valid/ready handshake you used for the AXIS FIFO in Lab 4.

In the above testing, we assume the input data is always valid for the systolic array to consume, and the tester's receiver is always ready to receive the output data from the systolic array. However, in practice, the communication between the systolic array and the tester is dynamic and backpressure-sensitive. It's possible that the tester's receiver is not ready to receive the output data from the systolic array, or the input data is not valid for the systolic array to consume. Therefore, whenever this happens, the systolic array should stall the input or output data to avoid data corruption.

#### Files for Part C

| File | Role | Edit? |
|---|---|---|
| `systolic_array_axis.v` | AXIS top module skeleton. Instantiate your `systolic_array` here | Yes |
| `test_axis.cpp` | AXIS testbench with no stalls | No |
| `test_axis_random_drop.cpp` | AXIS testbench with random stalls | No |
| `data_gen_axi.py` | Data generator and checker for Part C | No |
| `run_axis.sh` | Part C grading script | No |

Complete the TODOs in [systolic_array_axis.v](../code/systolic_array_axis.v). Your Part A and B design in [systolic_array.v](../code/systolic_array.v), [MAC.v](../code/MAC.v), and [ctrl.v](../code/ctrl.v) stays as it is, since Parts A and B are still graded on it. You may add logic around it, but do not change the interface of `systolic_array`.

#### Interface

The interface of `systolic_array_axis` cannot be changed:

```verilog
module systolic_array_axis #(
    parameter IN_WIDTH          = 8,
    parameter IN_FRAC           = 0,
    parameter OUT_WIDTH         = 8,
    parameter OUT_FRAC          = 0,
    parameter MULT_LAT          = 3,
    parameter ACC_LAT           = 1,
    parameter ROWS              = 4,
    parameter K                 = 4,
    parameter COLS              = 4
)(
    input                       clk,
    input                       rst,
    input                       en,
    input                       flush,               // If 1, flush the pipeline
    input                       rst_accumulator_rdy, // If 1, reset accumulator in array
    input                       stream_out_rdy,      // If 1, stream acc result out
    input [IN_WIDTH*ROWS-1:0]   row_data_in,         // AXIS row_data_in
    input                       row_data_in_vld,
    output                      row_data_in_rdy,
    input [IN_WIDTH*COLS-1:0]   col_data_in,         // AXIS col_data_in
    input                       col_data_in_vld,
    output                      col_data_in_rdy,
    output [OUT_WIDTH*ROWS-1:0] row_data_out,        // AXIS row_data_out
    output                      row_data_out_vld,
    input                       row_data_out_rdy
);
```

How the testbench drives these signals:
- `row_data_in` and `col_data_in` carry the same pre-skewed data as Parts A and B. A new beat is loaded only after a transfer (`vld && rdy`) on that channel.
- `rst_accumulator_rdy` and `stream_out_rdy` belong to the current `row_data_in` beat. They only change when a `row_data_in` beat transfers.
- `row_data_in_vld` and `col_data_in_vld` stay high until the input data runs out, in both testers.
- `flush`: do not rely on it. It stays 0 in `test_axis.cpp` and rises late in the random-stall test, long after the inputs end.
- `en` is not driven by the testbench. Do not rely on it.

#### Output format for Part C

Part C is checked with `data_gen_axi.py` instead of `data_gen.py`. The two differ in what they expect on the output:
- `data_gen.py` (In-Class, Parts A and B) expects the skewed stream your array produces. Row `i` of C comes out `i` cycles after row 0, and the testbench records `row_data_out` every cycle.
- `data_gen_axi.py` (Part C) expects an unskewed stream. Each output beat holds one full column of C, with all rows in the same beat. The testbench records only beats where `row_data_out_vld && row_data_out_rdy`.

So in Part C you need to line up the rows before sending them out. How many cycles should row `i` be delayed?

#### Requirements

Your design must:
- Transfer a beat only on a cycle where `vld && rdy` are both high. At all other times, nothing moves.
- Hold `row_data_out` and `row_data_out_vld` stable while `row_data_out_rdy` is low.
- Not make any `vld` depend combinationally on a `rdy`.
- Produce every column of C exactly once, in order, with no missing, repeated, or extra beats.
- Assert `row_data_out_vld` only for real results. Unlike the earlier parts, Part C data can legitimately be zero, so filler zero beats can fail a test.

**FIFO_DEPTH**: You may want to use [FIFO](../code/synchronus_fifo.v) in many places. Your systolic array cannot pause once data starts flowing, so any result the receiver is not ready for has to wait in a buffer. Think about how deep that buffer needs to be for the largest test.

#### Testing

Testing happens in two stages:
- **No stalls**: `test_axis.cpp` holds `row_data_in_vld`, `col_data_in_vld`, and `row_data_out_rdy` high every cycle.
- **Random stalls**: `test_axis_random_drop.cpp` randomly holds `row_data_out_rdy` low. Your design must stall instead of corrupting the stream.

`run_axis.sh` includes `N` != `K` cases, so your Part B design must work before Part C can fully pass. A full run takes about 15 to 20 minutes per tester, so debug with single test cases first.

Grading commands:
- `chmod +x run_axis.sh && ./run_axis.sh test_axis.cpp 100` (**5pts**)
    - Test different `SEED`, `MULT_LAT`, `M` and `N`, `NUM`, and combined parameter sweep (**1pt each**)
- `chmod +x run_axis.sh && ./run_axis.sh test_axis_random_drop.cpp 100` (**10pts**)
    - Test different `SEED`, `MULT_LAT`, `M` and `N`, `NUM`, and combined parameter sweep (**2pts each**)

To run a single test case (use `TEST_FILE=test_axis.cpp` for the no-stall tester):

```
make systolic_array_axis ROWS=${M} COLS=${N} K=${K} NUM_TESTS=${NUM} MULT_LAT=${LAT} TEST_FILE=test_axis_random_drop.cpp
cat results.log | grep PASSED
```

**Hints**
- A matrix multiplication step only happens when both the row and column beats are available. What should each `rdy` be?
- Your array cannot pause in the middle of a computation. When the output side stalls, results are still coming out of the array. Where do they go?
- How many results can pile up in the worst case? Look at how often `test_axis_random_drop.cpp` sets `row_data_out_rdy`, and how many results the largest test produces.

**Writeup (graded in the Report)**: In your report, explain why a deep enough FIFO can pass the random-stall tests without stalling the array at all. Then describe a stall pattern that would make a too-small FIFO lose data.


## Report (15 pts)

Submit one PDF report with the four sections below.

1. **Part A: From NxN to MxN (4pts)**: What had to be true about your In-Class 2 (NxN) design for it to work on MxN arrays with `N` = `K`? What did you change, if anything, and why?
2. **Part B: Non-square arrays (4pts)**: Why does your `N` = `K` design fail when `N` != `K`? What did you change in your design to support `N` != `K`?
3. **Part C: FIFO depth (4pts)**: Why can a deep enough FIFO pass the random-stall tests without stalling the array at all? Describe a stall pattern that would make a too-small FIFO lose data.
4. **AI usage (3pts)**: How did you use AI tools in this lab? Include:
    - The prompts you used
    - Errors you faced and how you resolved them

    If you did not use AI tools, say so and describe how you debugged your hardest bug instead.


## Submission

+ Provide a zip file containing your source code. Generate the submission.zip file using the command `make submit`. Avoid manual zip file creation to prevent any issues with the autograding script, which could lead to a 30% score deduction.
+ Submit your report as one PDF, separately from the zip. `make submit` only packages `.v` and `.vh` files.
* Late submission policy: 2 hours grace period


## Rules and Potential Violations
1. adder and multiplier instances have to be used and used as they are
2. systolic array IOs **and** default parameters cannot be changed
3. for MAC's parameters, as long as we can pass the MULT_LAT parameter in from the top module (systolic_array.v), it's fine
4. Any changes to Makefile, test*.cpp, adder and multiplier module definition will not be considered
5. Helper modules must be placed in MAC.v, ctrl.v, or systolic_array_axis.v. Do not add new `.v` files
6. The systolic_array_axis IOs **and** default parameters cannot be changed


## FAQ
[Q] Useful lecture links for systolic array design?

https://www.youtube.com/watch?v=cmy7LBaWuZ8&pp=ygUPc3lzdG9saWMgYXJhYXkg
