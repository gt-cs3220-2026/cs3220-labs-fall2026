# CS 3220 Lab 2 — Branch Predictor

Implement a branch predictor for your RISC-V CPU. Use the supplied Lab 2 codebase, or copy your working `.v` and `.vh` files from Lab 1.

| Part       | Covers                            | Tasks | Points |
| ---------- | --------------------------------- | ----- | ------ |
| In-Class 1 | BHR, PHT and BTB                  | 1–3   | 15     |
| In-Class 2 | Integration and accuracy counters | 4–5   | 25     |
| Take-Home  | Predictor experiments             | 6–8   | 60     |
| Bonus      | Gselect                           | 9     | 10     |

## Setting up

Follow the [ICE environment setup](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf), then load the tools:

```bash
source /storage/ice-shared/cs3220/labs_setup.sh
module load perl/5.36.0
```

## In-Class 1 — Tasks 1–3

Complete the independent modules in `fe_stage.v`. Refer to Lecture 5 and set the parameters in `define.vh`.

- **Task 1:** Implement an 8-bit BHR (also called GHR).
- **Task 2:** Implement a PHT with 256 two-bit saturating counters, initialized to weakly not taken. The G-share index is `PC[9:2] XOR BHR`.
- **Task 3:** Implement a 16-entry direct-mapped BTB indexed by `PC[5:2]`. Each entry stores a valid bit, tag and target address.

These tasks grade the modules independently. `./run_tests.sh inclass_1` should report three passing tests.

## In-Class 2 — Tasks 4–5

- **Task 4:** Integrate the predictor into the pipeline. Use the BTB and PHT to select the next PC, update the predictor when branches and jumps resolve, and recover correctly from mispredictions. Record branch targets whether the branch is taken or not.
- **Task 5:** Implement `branch_count` and `correct_branch_count` in `agex_stage.v`. Accuracy is the number of correct next-PC predictions divided by the number of resolved branches and jumps. The supplied simulator prints `Accuracy=xx%`.

Run `./run_tests.sh inclass_2`. Task 4 uses ten instruction programs worth two points each, plus a prediction check. Task 5 requires accuracy above 30% on the supplied Towers program.

## Take-Home — Tasks 6–8

- **Task 6:** Measure the original predictor on [towers.mem](test/take_home/towers/towers.mem), then reach at least 50% accuracy by changing predictor sizes or the history hash. Record the baseline and at least three modified configurations.
- **Task 7:** Compare one-bit and two-bit saturating counters on [counter.mem](test/take_home/counter.mem). Use 256 PC-indexed PHT entries and a 64-entry direct-mapped BTB for both runs. Change only the counter width and explain the results.
- **Task 8:** Implement a 16-entry, two-way set-associative BTB. Compare it with the original direct-mapped BTB on [btb.mem](test/take_home/btb.mem), keeping the other settings fixed. Explain the effect of bank conflicts on accuracy.

Implement the Task 7 and Task 8 variants as independent `PHT_1BIT` and `BTB_2WAY` modules in `fe_stage.v`, using the supplied interfaces. Module grading tests them independently; connect each variant to the pipeline for report measurements.

## Running things

Run from `lab2/`:

```bash
make                            # Build and simulate; write trace.vcd
make clean                      # Remove generated build files and logs
./run_tests.sh inclass_1        # Tasks 1–3
./run_tests.sh inclass_2        # Tasks 4–5
./run_tests.sh take_home        # Tasks 6–8
./run_tests.sh take_home task6  # Select task6, task7 or task8
./run_tests.sh all
```

For take-home measurements:

```bash
make tests TEST=take_home CASE=towers  # Task 6 baseline, without the 50% pass threshold
./run_tests.sh take_home counter       # Task 7 comparison
./run_tests.sh take_home btb           # Task 8 comparison
```

To run a single program:

```bash
IDMEMINITFILE=$PWD/test/inclass_2/task5/towers.mem make tests
```

Results are in `<suite>_results.log`; compiler and simulator output is in `<suite>_tests.log`. The `.mem` files are supplied.

## What is in here

| File                        | Purpose                              | Do you edit it? |
| --------------------------- | ------------------------------------ | --------------- |
| `pipeline.v`                | Connects the five stages             | No              |
| `fe_stage.v`                | Fetch and predictor modules          | Tasks 1–4, 6–8  |
| `de_stage.v`                | Decode and pipeline latch            | Task 4          |
| `agex_stage.v`              | Execute, branch resolution, counters | Tasks 4–5       |
| `mem_stage.v`, `wb_stage.v` | Memory and write-back                | No              |
| `define.vh`                 | Parameters, latch widths, test path  | As needed       |
| `sim_main.cpp`              | Simulator driver                     | No              |
| `Makefile`, `run_tests.sh`  | Build and test drivers               | No              |

Tests are under `test/inclass_1/`, `test/inclass_2/` and `test/take_home/`. Old tests are archived in `test/unused/`. Keep implementations in the supplied Verilog files and preserve module interfaces.

## What to hand in

Run `make submit` and submit `submission.zip` with a separate PDF report of at most two pages. Include both independent variant modules in the code. Keep the PDF outside the ZIP.

The report must include Task 6's baseline and three modified configurations with measured accuracy, Task 7's counter comparison, and Task 8's BTB comparison. State the settings used and explain your observations.

## References

- [RISC-V RV32I manual](https://web.eecs.utk.edu/~smarz1/courses/ece356/notes/assembly/)
- [RISC-V instruction card](https://github.com/jameslzhu/riscv-card/releases/download/latest/riscv-card.pdf)
- [RISC-V emulator](https://www.cs.cornell.edu/courses/cs3410/2019sp/riscv/interpreter/)
- [Verilator manual](https://verilator.org/guide/latest/)
- [Signal Viewer setup](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf)
- [RISC-V test suite tutorial](https://web.archive.org/web/20221031194615/https://inst.eecs.berkeley.edu/~cs250/fa10/handouts/tut3-riscv.pdf)
