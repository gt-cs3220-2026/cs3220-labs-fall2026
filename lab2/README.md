# CS 3220 Lab 2 — Branch Predictor

Implement a branch predictor for your RISC-V CPU. Use the supplied Lab 2 codebase, or copy your working `.v` and `.vh` files from Lab 1.

| Part       | Covers                            | Tasks | Points |
| ---------- | --------------------------------- | ----- | ------ |
| In-Class 1 | BHR, PHT and direction prediction | 1–3   | 15     |
| In-Class 2 | BTB, integration and counters     | 4–6   | 30     |
| Take-Home  | Predictor experiments             | 7–9   | 60     |
| Bonus      | Gselect                           | 10    | 10     |

## Setting up

Follow the [ICE environment setup](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf), then load the tools:

```bash
source /storage/ice-shared/cs3220/labs_setup.sh
module load perl/5.36.0
```

## In-Class 1 — Tasks 1–3

In this part, implement the BHR and PHT of a G-share branch predictor in `fe_stage.v`, then connect them to the pipeline. Refer to Lecture 5 and set the parameters in `define.vh`.

1. **Task 1:** Implement an 8-bit branch history register (BHR).

   BHR may also be called GHR (Global History Register) in the slides; both names refer to the same register.

2. **Task 2:** Implement a Pattern History Table (PHT) with 256 two-bit saturating counters. Initialize each counter to weakly fall-through (`01`).

3. **Task 3:** Connect BHR and PHT to the pipeline for branch direction prediction.

**Guidance**:

For Tasks 1 and 2, complete the logic inside the supplied module interfaces. Each module is graded independently. Task 3 covers their pipeline connections.

Read the parameter definitions in `define.vh` before choosing wire and register widths. Each Verilog file includes these definitions with `include`. Update the parameters to match your implementation.

A Verilog register array can represent a table. For example, `reg [31:0] r [0:10]` declares eleven 32-bit registers: the first range gives each register's width, and the second gives the array's indices.

**Grading**:

Run `./run_tests.sh inclass_1`. Tasks 1 and 2 check the BHR output and PHT direction output, worth five points each. Task 3 uses `beq`, `bne`, `blt`, `bgeu` and `predict`, worth one point each. The suite should report seven passing tests.

**The tests.** The instruction programs exercise branch outcomes; `predict` repeats a loop to exercise learning. Run `./run_tests.sh inclass_1 task3` to select these five programs.

**Reading the output.** A successful case prints `Passed!`. A failed check prints `expected output:` and `actual output:`. Read the corresponding `.S` file, or `predict.asm`, alongside the result. Compiler and simulator output is saved in `inclass_1_tests.log`.

## In-Class 2 — Tasks 4–6

In this part, implement the BTB, connect the complete predictor, and measure prediction accuracy.

1. **Task 4:** Implement a 16-entry direct-mapped branch target buffer (BTB), indexed by `PC[5:2]`. Each entry contains three fields:

   - The tag, `PC[31:6]`, identifies the instruction address stored in the entry.
   - The valid bit identifies an initialized entry.
   - The target address supplies the predicted branch or jump destination.

2. **Task 5:** Integrate the predictor into the pipeline.

   In FE, access the BTB and PHT together. A BTB hit and a taken PHT prediction select the stored target; the remaining cases select `PC+4`. Carry the selected next PC and the PHT lookup index with the instruction to AGEX.

   In AGEX, compute the actual next PC and check the prediction. A next-PC prediction error redirects fetch and flushes the younger instructions. The actual next PC is the branch target for a taken branch and `PC+4` for a fall-through branch.

   Every resolved branch or jump updates BHR and PHT. Train the PHT entry selected when the instruction was fetched. Record the branch's taken target in BTB for both outcomes, so the target is available on a later encounter.

3. **Task 6:** Implement `branch_count` and `correct_branch_count` in `agex_stage.v`. Prediction accuracy is the number of correct next-PC predictions divided by the number of resolved branches and jumps.

   Include jumps in both counts. Keep the counters in AGEX; the supplied simulator reads them and prints `Accuracy=xx%`.

**Guidance**:

BHR and PHT are accessed in FE, while branches resolve in AGEX. Use `from_AGEX_to_FE` to return the information needed for predictor updates.

Carry the information needed for prediction checks through the pipeline latches. Follow `FE_latch_out` through DE to AGEX, keeping each instruction and its prediction information together during stalls and flushes.

When extending a latch or feedback bus, update its width in `define.vh` and match the field order at both ends.

**Grading**:

Run `./run_tests.sh inclass_2`. Task 4 checks the BTB independently for five points. Task 5 uses ten instruction programs worth two points each, plus a prediction check. Task 6 checks the accuracy counters and requires accuracy above 30% on the supplied Towers program. The suite should report thirteen passing tests.

## Take-Home — Tasks 7–9

Use the more complex programs to study prediction accuracy and compare predictor designs. Record each configuration and explain its measured behavior.

- **Task 7:** Measure the original predictor on [towers.mem](test/take_home/towers/towers.mem). Reach at least 50% accuracy by changing the BHR, PHT or BTB sizes, or the history hash. Record the baseline and at least three modified configurations with their measured accuracy.

- **Task 8:** Compare one-bit and two-bit saturating counters on [counter.mem](test/take_home/counter.mem). Use 256 PC-indexed PHT entries and a 64-entry direct-mapped BTB for both runs. Change the counter width and explain the results using the counter states or a waveform. Relate your observations to the two-bit predictor discussed in lecture.

- **Task 9:** Implement a 16-entry, two-way set-associative BTB. Compare it with the original direct-mapped BTB on [btb.mem](test/take_home/btb.mem), keeping the other settings fixed. Explain the measured accuracy using the branch addresses and their bank conflicts.

**Guidance**:

Implement `PHT_1BIT` and `BTB_2WAY` as independent modules in `fe_stage.v`, using the same ports as `PHT` and `BTB`, respectively. Their module tests check behavior through these ports. Connect each variant to the pipeline for the report measurements.

For Task 8, use `PC[9:2]` to index the PHT in both configurations. For Task 9, retain the eight-bit history and 256 two-bit PHT entries while comparing the two BTB organizations. A 16-entry two-way BTB has eight sets with two entries per set.

Record the baseline and the variants even when a change lowers accuracy. Explain how the changed predictor settings affect the program's branch pattern.

## Running things

Run from `lab2/`:

```bash
make                            # Build and simulate; write trace.vcd
make clean                      # Remove generated build files and logs
./run_tests.sh inclass_1        # Tasks 1–3
./run_tests.sh inclass_1 task3  # BHR/PHT direction prediction
./run_tests.sh inclass_2        # Tasks 4–6
./run_tests.sh take_home        # Tasks 7–9
./run_tests.sh take_home task7  # Select task7, task8 or task9
./run_tests.sh all
```

For take-home measurements:

```bash
make tests TEST=take_home CASE=towers  # Task 7 baseline accuracy
./run_tests.sh take_home counter       # Task 8 comparison
./run_tests.sh take_home btb           # Task 9 comparison
```

To run a single program:

```bash
IDMEMINITFILE=$PWD/test/inclass_2/task6/towers.mem make tests
```

Results are in `<suite>_results.log`; compiler and simulator output is in `<suite>_tests.log`. The `.mem` files are supplied.

Tests print `Passed!` or two lines labelled `expected output:` and `actual output:`.

## What is in here

| File                        | Purpose                              | Task            |
| --------------------------- | ------------------------------------ | --------------- |
| `pipeline.v`                | Connects the five stages             | Provided        |
| `fe_stage.v`                | Fetch and predictor modules          | Tasks 1–5, 7–9  |
| `de_stage.v`                | Decode and pipeline latch            | Tasks 3, 5      |
| `agex_stage.v`              | Execute, branch resolution, counters | Tasks 3, 5–6    |
| `mem_stage.v`, `wb_stage.v` | Memory and write-back                | Provided        |
| `define.vh`                 | Parameters, latch widths, test path  | As needed       |
| `sim_main.cpp`              | Simulator driver                     | Provided        |
| `Makefile`, `run_tests.sh`  | Build and test drivers               | Provided        |

Tests are under `test/inclass_1/`, `test/inclass_2/` and `test/take_home/`. Keep implementations in the supplied Verilog files and preserve module interfaces.

## What to hand in

Run `make submit` and submit `submission.zip` with a separate PDF report of at most two pages. Include the independent `PHT_1BIT` and `BTB_2WAY` modules in `fe_stage.v`. Keep the PDF outside the ZIP.

The report must include:

1. Task 7's baseline and at least three modified configurations, their predictor settings and measured Towers accuracy. Identify the configuration that reaches at least 50%.
2. Task 8's one-bit and two-bit counter measurements on `counter.mem`, with an explanation based on counter states or waveforms.
3. Task 9's direct-mapped and two-way BTB measurements on `btb.mem`, with an explanation of the bank conflicts.

State the module and parameter settings used for each measurement and explain your observations.

## References

- [RISC-V RV32I manual](https://web.eecs.utk.edu/~smarz1/courses/ece356/notes/assembly/)
- [RISC-V instruction card](https://github.com/jameslzhu/riscv-card/releases/download/latest/riscv-card.pdf)
- [RISC-V emulator](https://www.cs.cornell.edu/courses/cs3410/2019sp/riscv/interpreter/)
- [Verilator manual](https://verilator.org/guide/latest/)
- [Signal Viewer setup](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf)
- [RISC-V test suite tutorial](https://web.archive.org/web/20221031194615/https://inst.eecs.berkeley.edu/~cs250/fa10/handouts/tut3-riscv.pdf)

## FAQ

[Q] Some instruction programs report a failure. How should I check pipeline recovery? \
[A] Check taken branches against their target address and fall-through branches against `PC+4`. On a next-PC prediction error, redirect fetch to the actual address and flush the younger instructions. 

[Q] What do the BTB and PHT look like, and how do we make predictions? \
[A] Each BTB entry contains a valid bit, a tag field (`PC[31:6]`), and a target address. The PHT has 256 two-bit counters, indexed by `PC[9:2] XOR BHR`. Both tables are accessed in FE.

[Q] How do we update the BHR (Branch History Register)? \
[A] For each resolved branch or jump, shift the BHR left by one bit and insert the latest outcome into bit 0: 1 for taken and 0 for fall-through. BHR is also called GHR in the slides.

[Q] How do we update the BTB? \
[A] When a branch or jump resolves in AGEX, store `PC[31:6]` in the tag field and the calculated taken target in the target field, then set the valid bit to 1.

[Q] Which branch outcomes cause a BTB update? \
[A] Both taken and fall-through outcomes update the BTB. The stored target can be used when that branch is encountered again.

[Q] What target should a fall-through branch store in the BTB? \
[A] Store the address the branch would reach on a taken outcome: the branch PC plus its sign-extended immediate.

[Q] How do we update the PHT? \
[A] Save the PHT index (`PC[9:2] XOR BHR`) when fetching the instruction and carry it through the pipeline. Return that index and the actual branch outcome from AGEX to FE using `from_AGEX_to_FE`, then update the selected counter.

[Q] When should we flush the pipeline? \
[A] Flush on a next-PC prediction error. Redirect fetch to the actual next PC and clear the younger instructions in FE and DE.

[Q] What if the target in the BTB is wrong? \
[A] Handle it as a next-PC prediction error: flush, redirect, and update the BTB with the resolved target.

[Q] With a branch predictor, will the pipeline still have pipeline bubbles? \
[A] Data-dependency stalls and branch prediction recovery still create bubbles. Correct predictions let fetch follow the branch's actual path.

[Q] What is the expected branch prediction accuracy on `towers.mem`? \
[A] The Task 6 baseline typically achieves around 30–40% accuracy with roughly 1,000 resolved branches and jumps. The Task 7 program uses its own branch pattern and requires at least 50% accuracy after optimization.

[Q] Why is the expected accuracy relatively low for the baseline implementation? \
[A] Cold predictor entries, the small tables and the distribution of branch histories limit prediction accuracy. Repeated encounters let the counters learn a branch's behavior.

[Q] Where should I put the counters for tracking branch predictions? \
[A] Put them in AGEX and update them for resolved branches and jumps. These instructions lie on the executed path; FE and DE can also contain younger instructions that are later flushed.

[Q] My accuracy is unusually high, or my branch count is far from the expected total. What should I check? \
[A] Check BTB valid bits and tags, fetch and resolved PCs, and the counter update conditions. Confirm that each resolved branch or jump contributes once and that program execution reaches its completion marker.

[Q] I am getting about 16% accuracy. How can I improve the implementation? \
[A] Check that jumps update BHR, PHT and BTB, that PHT training uses the saved fetch index, and that the accuracy counters include both branches and jumps. Compare the predicted next PC with the actual next PC.

[Q] The `jalr.mem` test reports a failure. What should I check? \
[A] Check JALR target calculation, including its cleared least significant bit, and the recovery signal in AGEX. Follow `jalr.S` and the corresponding PCs in the waveform.

[Q] How can I view PHT values in my waveform? \
[A] Select a few table entries or assign them to debug wires, then inspect those values in `trace.vcd` with Signal Viewer.

[Q] What can cause an X value in the BTB or BHR? \
[A] Check initialization and the controls associated with pipeline bubbles. Predictor updates should come from valid resolved branch or jump instructions, using initialized indices and data.

[Q] Why do the instruction tests show little prediction benefit? \
[A] Many instruction tests execute each branch a small number of times. Repeated branch patterns give the predictor more opportunities to learn; the supplied `predict` program exercises this behavior.

[Q] Which CPU implementation should I use to start Lab 2? \
[A] Use the supplied Lab 2 pipeline from the TAs, or copy your working `.v` and `.vh` files from Lab 1.

[Q] Where should I put an additional predictor module, such as one I would otherwise place in `bp.v`? \
[A] Keep predictor modules in `fe_stage.v`. The autograder compiles the six supplied pipeline `.v` files and `define.vh`.

[Q] Which tasks evaluate prediction performance? \
[A] Tasks 1–5 check module and pipeline behavior. Task 6 checks the accuracy counters and the 30% baseline requirement. Task 7 evaluates predictor optimization against the 50% target; Tasks 8 and 9 compare predictor designs.

[Q] How should I handle data dependencies in Lab 2? \
[A] The supplied pipeline handles data dependencies with stalls. Preserve its hazard handling while adding predictor connections.

[Q] Consider the following instruction stream:

```text
BR(1)
ADD
BR(2)
```

When BR(1) is in AGEX and BR(2) is in FE at the same clock edge, which history does the fetch use? \
[A] For the baseline, the prediction captured at that edge uses the history and table state before the edge. BR(1)'s update becomes visible after the edge. Save the index used for BR(2)'s fetch so its later PHT update reaches that entry.

[Q] How do I initialize the PHT entries to 1? \
[A] Assign `2'b01` to every PHT entry during reset, for example with a `for` loop in the reset branch of the clocked block.

[Q] How does the supplied Towers test signal completion? \
[A] The program writes its verification result to `gp` (`x3`) and retires an ECALL marker. A successful result has `gp=1`, and the test prints `Passed!`. Use the printed branch counts and accuracy to check the Task 6 or Task 7 requirement.

[Q] How should I report the three predictor design changes? \
[A] Record each configuration and its measured accuracy, including configurations that lower accuracy. Explain the effect of each change. For Task 7, identify a configuration that reaches at least 50% accuracy.
