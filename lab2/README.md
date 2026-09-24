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

Complete BHR and PHT in `fe_stage.v`, then connect them to the pipeline. Refer to Lecture 5 and set the parameters in `define.vh`.

- **Task 1:** Implement an 8-bit BHR (also called GHR).
- **Task 2:** Implement a PHT with 256 two-bit saturating counters, initialized to weakly fall-through (`01`). The G-share index is `PC[9:2] XOR BHR`.
- **Task 3:** Connect BHR and PHT to the pipeline for branch direction prediction.

Run `./run_tests.sh inclass_1`. Tasks 1 and 2 grade the modules independently. Task 3 uses five programs worth one point each. The suite should report seven passing tests.

## In-Class 2 — Tasks 4–6

- **Task 4:** Implement a 16-entry direct-mapped BTB indexed by `PC[5:2]`. Each entry stores a valid bit, tag and target address.
- **Task 5:** Integrate the predictor into the pipeline. Use the BTB and PHT to select the next PC, update the predictor when branches and jumps resolve, and recover correctly from mispredictions. Record branch targets for both outcomes.
- **Task 6:** Implement `branch_count` and `correct_branch_count` in `agex_stage.v`. Accuracy is the number of correct next-PC predictions divided by the number of resolved branches and jumps. The supplied simulator prints `Accuracy=xx%`.

Run `./run_tests.sh inclass_2`. Task 4 grades the BTB independently. Task 5 uses ten instruction programs worth two points each, plus a prediction check. Task 6 requires accuracy above 30% on the supplied Towers program.

## Take-Home — Tasks 7–9

- **Task 7:** Measure the original predictor on [towers.mem](test/take_home/towers/towers.mem), then reach at least 50% accuracy by changing predictor sizes or the history hash. Record the baseline and at least three modified configurations.
- **Task 8:** Compare one-bit and two-bit saturating counters on [counter.mem](test/take_home/counter.mem). Use 256 PC-indexed PHT entries and a 64-entry direct-mapped BTB for both runs. Change only the counter width and explain the results.
- **Task 9:** Implement a 16-entry, two-way set-associative BTB. Compare it with the original direct-mapped BTB on [btb.mem](test/take_home/btb.mem), keeping the other settings fixed. Explain the effect of bank conflicts on accuracy.

Implement the Task 8 and Task 9 variants as independent `PHT_1BIT` and `BTB_2WAY` modules in `fe_stage.v`, using the supplied interfaces. Module grading tests them independently; connect each variant to the pipeline for report measurements.

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

Tests are under `test/inclass_1/`, `test/inclass_2/` and `test/take_home/`. Old tests are archived in `test/unused/`. Keep implementations in the supplied Verilog files and preserve module interfaces.

## What to hand in

Run `make submit` and submit `submission.zip` with a separate PDF report of at most two pages. Include both independent variant modules in the code. Keep the PDF outside the ZIP.

The report must include Task 7's baseline and three modified configurations with measured accuracy, Task 8's counter comparison, and Task 9's BTB comparison. State the settings used and explain your observations.

## References

- [RISC-V RV32I manual](https://web.eecs.utk.edu/~smarz1/courses/ece356/notes/assembly/)
- [RISC-V instruction card](https://github.com/jameslzhu/riscv-card/releases/download/latest/riscv-card.pdf)
- [RISC-V emulator](https://www.cs.cornell.edu/courses/cs3410/2019sp/riscv/interpreter/)
- [Verilator manual](https://verilator.org/guide/latest/)
- [Signal Viewer setup](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf)
- [RISC-V test suite tutorial](https://web.archive.org/web/20221031194615/https://inst.eecs.berkeley.edu/~cs250/fa10/handouts/tut3-riscv.pdf)
