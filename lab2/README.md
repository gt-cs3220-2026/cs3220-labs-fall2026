# CS 3220 Lab 2 — Branch Predictor

This lab is a continuation of lab 1. In this project, you will implement a branch predictor for your RISC-V CPU. You suggested to work on top of the lab 2 codebase from the TAs, which are located in the current folder. Alternatively, you can copy your *.v and *.vh files from lab 1 here and start from your own implementation.


| Part       | Covers                                                                            | Tasks | Points |
| ---------- | --------------------------------------------------------------------------------- | ----- | ------ |
| In-Class 1 | BHR, PHT and BTB implementation                                                   | 1–3  | 15     |
| In-Class 2 | Register update and branch predictor wireup, Branch predictor accuracy caclculate | 4-6   | 15     |
| Take-Home  | Predictor accuracy test with diffrient configuration                              | 7-8   | 70     |

## Setting up

As lab 1, Follow this [document](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf) to access OnDemand ICE and connect to Coder to setup experiment environment.

Remember to run **`source /storage/ice-shared/cs3220/labs_setup.sh` and** **`module load perl/5.36.0` in your terminal to get an environment with** **`verilator`,** **`make`,** `g++`.

## In-Class 1 — Tasks 1–3, `FE_stage.v`:

In this part, you'll be implementing **Three** key modules of a G-share branch predictor (please refer to lecture-6):

1. Task 1 : A 8 bits branch history register (BHR), you will use `PC[9:2] XOR BHR` to index a Pattern History Table (PHT)

+ BHR may be referred to as GHR ( "Global branch history register") in the slides, they are the same item.

2. Task 2 : A pattern history Table(PHT), which is composed of 2^8 2-bit counters to make branch prediction. Each counter is initialized with weakly not taken.
3. Task 3 : A 16 entries branch target buffer (BTB), and you will use `PC[5:2]` to index it. Each entry of the BTB is composed of 3 parts: a valid bit, a tag field, and a target address:

+ the tag field is used to determine whether the current PC address in the FE stage is the one recorded in the BTB entry;
+ the valid bit is used to identify whether this entry contains a valid history, rather than unused;
+ the target address is used to predict the branch / jump target.

**Guidance**:

For easy to implementation, FE stage remain very simple frameworks for each module (You should see the`TODO` in `FE_stage.v`), which only implement a Flip-Flop.

The thing to understand before you type is how to use the parament define for the wire or register width. `define.vh` is the parament define file, which used in each module by `inclue`. We pre-define some key paraments as example for, like the width of each singal for you. You could change it for your own implementation.

You could use the array in verilog to represnet a file of registers, as the form `reg [31:0] r [0:10]`. The former square conlum represent the bit width for each register in file and the later represent the array length.

**Grading**:
We will check the testcases ./run_tests.sh inclass_1 are correctly executed or not. The testcase in class 1 will individually test your implementation on each modules. Proper functionallity will result in grade. Wire each module up is not necessary for grading.

## In-Class 2 — Tasks 4–6, `FE_stage.v` and `AGEX_stage.v`:

In this part, you'll be finish the remaining logic of the branch predictor, plus the accuracy counter:

- Task 4: wiring up the BHR, PHT and BTB with PC, implement the prediction logic path in `FE_stage.v`
- Task 5: implement the logic of misprediction check, and use the misprediction result to update the register in each module.
- Task 6: implemnent counter to measure the branch prediction accuracy(# of correctly predicted branches / # total branch instructions).

**Guidance**:

Summary of the G-share branch prediction algorithm:

* FE Stage ([fe_stage.v](fe_stage.v)):

  1. If there's a BTB hit, use PHT outcome to determine the target address for the next instruction fetch: if the outcome is taken, use BTB target address. If BTB misses, use PC+4 for next instruction.
  2. The address for the next instruction fetch and index (`PC[9:2] XOR BHR`) used in FE stage is passed to EX stage for PHT update.
* EX stage ([agex_stage.v](agex_stage.v)):

  1. Check if the next instruction fecthed in the FE stage is correct or not: if not, flush the pipeline.

  - If the branch is taken, and the next instruction we fetched is not the branch target, we are supposed flush the pipeline;
  - If the branch is not taken, and the next instruction we fetched is not PC+4, we should flush the pipeline.

  2. For branch instructions (bne, beq, jalr, etc.), insert the target address into the BTB, no matter taken or not.
  3. If PHT is used for branching prediction in the FE stage, update PHT using the propagated PHT index (`PC[9:2] XOR BHR`).
  4. Update the BHR.

  + As BHR and PHT are implemented in the FE stage, you are supposed to forward the relevant signals to the FE stage for the updates mentioned in 2, 3 and 4 via from_AGEX_to_FE.

For the accuracy measurement in task 6, note that jump instructions should be counted as branch instructions here as well.

To allow autograding, you have to print out the prediction accuracy in the following format: `Accuracy=xx%`, where `xx` is your accuracy. The accuracy can be a integer or a floating point number. You can refer to `sim_main.cpp` on how to access the register values in the Verilog modules via the verilator public data structure. **Note that you will need to modify `sim_main.cpp` to print the accuracy line.**

**Grading**:
We will check the testcases testcases ./run_tests.sh inclass_2 are correctly executed or not. Task 4 check your code is successfully predict something or not and the Task 5 test all of the predictor implementation. Task6 will test your accuracy output.

## Take-Home - Task 7-8 Performance Measurement & Optimization

For this part, you will evaluate your branch prediction in mutiple dimesion: accuracy, Cycle per instruction, register usage. Besides, enhance the performance of your branch predictor on the [towers.mem](test/towers/towers.mem) testcase by making design changes: you can explore other BHR hashing functions (e.g. using different bits of PC for the XOR operation), or change the PHT or BTB sizes.

- Task 7: implement the measurement for additional metrics: CPI counter, and register usage. Utilize the [towers.mem](test/towers/towers.mem) to measure these metrics as your branch predictor evaluation.
- Task 8: Implement at least three different design changes, and present the corresponding performance outcomes and tradeoff(eg. size/logic) in your report.

## Submission

+ check the testcases ./run_tests.sh take_home are correctly executed or not.
+ Submit a concise PDF report for Part 2 (limited to 2 pages) containing the following information:

1. Your performance measurements for the baseline G-share branch predictor and your three variants.
2. Discuss the design parameters that were modified and explain how these changes influenced branch prediction accuracy, either positively or negatively.
3. Do not put this pdf inside the zip file.

## Running things

Everything is run from the `lab2/` directory. The running command is similar with the lab 1:

```bash
make                    # build and run the program selected in define.vh; write trace.vcd
make clean              # delete obj_dir, root-level logs, and trace.vcd
```

To run a single instruction test, edit `IDMEMINITFILE` in
[define.vh](define.vh) and run `make`, or select the file on the command line:

```bash
IDMEMINITFILE="$PWD/test/part2/jalr.mem" make tests
```

The command-line selection leaves `define.vh` unchanged. Both instruction
memory and data memory load the selected `.mem` file.

To run a test suite:

```bash
./run_tests.sh inclass_1  # Tasks 1–3: independent BHR, PHT, and BTB tests
./run_tests.sh inclass_2  # Tasks 4–6: prediction path, whole processor, and accuracy measurement
./run_tests.sh take_home  # Towers benchmark
./run_tests.sh all        # Tasks 1–6
```

An individual task can be selected with `./run_tests.sh task1` through
`./run_tests.sh task6`. Each run reports the passing and failing tests.
Detailed logs are saved in `test_results/taskN/` (`test_results/take_home/`
for Towers); `test_results/summary.log` contains the latest run's results.
The command returns a nonzero status if any selected test fails.

The pipeline simulator prints `Passed!` when the final value in `gp` (`x3`)
is 1. Otherwise, it prints `Failed. exitcode: N`, where `N` is the final
value of `gp`. Compare the failing program's `.asm` or `.dump` with the
write-back trace printed by `make`; `PC=` identifies the instruction address
and `Op=` is the internal opcode defined in `define.vh`.

Towers uses 255 as its completion value. For `take_home`, the runner accepts
`Failed. exitcode: 255` together with a finite `Accuracy=xx%` result between
0 and 100.

For waveform debugging, select the program in `define.vh` and run `make`
to produce `trace.vcd`. Open it in Signal Viewer using the setup document
linked above; the required extension is impulse.

To create the code submission:

```bash
make submit              # write submission.zip
```

Submit the PDF report separately, as described in the Submission section.

## What is in here

### The processor

[pipeline.v](pipeline.v) connects the five stages. Signals pass between stages
in packed vectors, with their widths defined in [define.vh](define.vh).


| File                                             | What it contains                                                                    | Do you edit it?                                                |
| ------------------------------------------------ | ----------------------------------------------------------------------------------- | -------------------------------------------------------------- |
| `pipeline.v`                                     | Stage instances, connecting wires, and a cycle counter                              | Only if needed for Task 7 measurements                         |
| `fe_stage.v`                                     | Fetch PC, instruction memory, BHR, PHT, BTB, and prediction logic                   | Tasks 1–5 and predictor changes in Task 8                     |
| `de_stage.v`                                     | Instruction decode, register file, hazard detection, and the DE latch               | Task 5: pass the predicted next PC and PHT index to AGEX       |
| `agex_stage.v`                                   | Instruction execution, branch resolution, predictor feedback, and accuracy counters | Tasks 5–6                                                     |
| `mem_stage.v`                                    | Data memory and the MEM latch                                                       | No branch-predictor changes required                           |
| `wb_stage.v`                                     | Register write-back and values exposed to the simulator                             | Only if needed for Task 7 measurements                         |
| `define.vh`                                      | Opcodes, predictor parameters, latch widths, and the memory image path              | As needed for predictor parameters and additional latch fields |
| `sim_main.cpp`                                   | Simulation clock and reset, trace output, program result, and printed measurements  | Tasks 6–7                                                     |
| `Makefile`, `run_tests.sh`, `tests/run_tasks.py` | Build commands and test selection                                                   | No                                                             |

The predictor components are defined in `fe_stage.v`; the accuracy counter module is defined in `agex_stage.v`. For Task 5, check both the packing and unpacking of the FE and DE latches when adding prediction information. The corresponding widths in `define.vh` must include the new fields.

### The tests


| Files or directory                                               | Test selection                                | What it covers                                                     |
| ---------------------------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------ |
| `tests/test_bhr.cpp`, `tests/test_pht.cpp`, `tests/test_btb.cpp` | `inclass_1`, or `task1`–`task3` individually | Independent BHR, PHT, and BTB logic                                |
| `tests/test_prediction.cpp`                                      | `task4`                                       | The FE path from PC to predicted direction and next PC             |
| `test/part1/` through `test/part4/`                              | `task5`                                       | 45 instruction programs for whole-processor correctness            |
| `tests/test_accuracy.cpp`                                        | `task6`                                       | Branch/jump counts, correct-prediction counts, and accuracy output |
| `test/towers/`                                                   | `take_home` or `towers`                       | The Towers workload for performance measurements                   |

`inclass_2` runs Tasks 4–6. Tasks 1–3 supply the inputs to each component directly, so they do not require pipeline connections. Task 4 supplies a PC and training inputs to the FE prediction logic. The signal interfaces are listed in [tests/README.md](tests/README.md).

## What to hand in

Submit `submission.zip`, produced by `make submit`, to Gradescope.

For the task8 in take-home part submit a separate PDF
report of at most **2 pages**, as required in the Submission section:

1. Present the baseline G-share predictor and at least three design variants, including their prediction accuracy, CPI, and register usage.
2. Describe the parameters changed in each variant and discuss their effect on performance and hardware cost.

Keep the PDF outside `submission.zip`.

## References

* [RISC-V RV32I manual](https://web.eecs.utk.edu/~smarz1/courses/ece356/notes/assembly/) — also covers ABI register names and pseudo-instructions, which you need to read the take-home tests
* [RISC-V instruction card](https://github.com/jameslzhu/riscv-card/releases/download/latest/riscv-card.pdf) — one page, has every encoding
* [RISC-V emulator (Tiny RV2)](https://www.cs.cornell.edu/courses/cs3410/2019sp/riscv/interpreter/) — run a program by hand when you are not sure what the right answer is
* [Verilator manual](https://verilator.org/guide/latest/)
* [Signal Viewer setup (impulse extension)](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf) — how to open`trace.vcd` in Coder
* [Tutorial on the RISC-V test suite](https://web.archive.org/web/20221031194615/https://inst.eecs.berkeley.edu/~cs250/fa10/handouts/tut3-riscv.pdf)

## FAQ

[Q] What do the BTB and PHT look like, and how do we make predictions?
[A] Each BTB entry contains three parts: a valid bit, a tag field (PC[31:6]), and a target address. The PHT has 256 entries of 2‑bit counters, indexed by `PC[9:2] XOR BHR`. All branch prediction logic is implemented in the FE stage.

[Q] What do the BTB and PHT look like, and how do we make predictions?
[A] Each BTB entry contains three parts: a valid bit, a tag field (PC[31:6]), and a target address. The PHT has 256 entries of 2‑bit counters, indexed by `PC[9:2] XOR BHR`. All branch prediction logic is implemented in the FE stage.

[Q] How do we update the BHR (Branch History Register)?
[A] For each branch instruction, left shift the BHR by one bit and insert the latest result in the rightmost bit: 1 if taken, 0 if not taken. BHR is the same as GHR mentioned in the slides.

[Q] How do we update the BTB?
[A] When you detect a branch or jump in AGEX, insert it into the BTB regardless of whether it is taken. Store PC[31:6] in the tag field, the calculated target address in the target field, and set the valid bit to 1.

[Q] Do we insert a BTB entry only for the taken branch or even when it is not taken?
[A] You need to insert a BTB entry even when the branch is not taken, because the same branch might be taken the next time.

[Q] If we insert a not‑taken branch for the BTB entry, what will be the target address?
[A] You can still compute the target address as if it is taken and insert it in the BTB.

[Q] How do we update the PHT?
[A] Pass the PHT index (`PC[9:2] XOR BHR`) from FE to AGEX through pipeline latches. Forward this PHT index from AGEX back to FE using the `from_AGEX_to_FE` wire, and update the 2‑bit counter at that index based on the actual outcome.

[Q] When should we flush the pipeline?
[A] Flush when the next instruction is fetched from an incorrect address. If the branch is taken and the fetched instruction is not at the branch target, flush. If the branch is not taken and the fetched instruction is not at PC+4, also flush.

[Q] What if the target in the BTB is wrong?
[A] Treat it like a branch misprediction: flush the pipeline and update the BTB entry with the correct target.

[Q] With a branch predictor, will the pipeline still have pipeline bubbles?
[A] The pipeline will still have bubbles for dependency stalls, but not for correctly predicted branch instructions.

[Q] Where should I put the counters for tracking branch predictions?
[A] Implement counters in the AGEX stage because instructions there are never flushed and lie on the real execution path. Counting in FE or DE may include wrong‑path instructions.

[Q] I can’t see the PHT values in my waveform. How can I view them?
[A] The PHT has too many entries to display directly. Assign one or a few specific entries to separate wires or debug outputs so you can observe those entries in the waveform.

[Q] I’m debugging my code. I see that there is an X in the BTB/BHT. How would it be possible?
[A] The FE stage can have pipeline bubbles. Therefore, BTB/PHT might be indexed with uninitialized values (X). Make sure that when you update BTB/PHT, only valid branch/jump instructions (with non‑X control signals) are allowed to change their contents.

[Q] My pipeline did not work for lab 1. What should I do?
[A] Please use the reference design provided by the TAs instead of your own Lab 1 implementation.

[Q] I want to add a new file (e.g., `bp.v`). Can I?
[A] Please do not add new files, as this might break the auto‑grading script.

[Q] Let’s say my instruction stream is as follows:

```
BR(1)
ADD
BR(2)
```

When BR(1) is in EX, it will update the BHR, but BR(2) will be in FE at that time. Which value of BHR should FE use—the old value or the updated value from EX?
[A] This is one of the optimization opportunities. How you handle this case is up to you. Remember that the branch predictor is just a predictor and will not affect the correctness of the program, only performance.

[Q] How do I initialize the PHT entries to “1”?
[A] Explicitly write `2'b01` into every PHT entry during reset (e.g., in a `for` loop in the reset branch of your always block).
