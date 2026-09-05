# CS 3220 Lab 1 — A 5-stage RISC-V pipeline

You build a five-stage pipelined processor for a subset of RISC-V (the Tiny
RISC-V variant from Cornell, described in [tinyrv-isa.txt](tinyrv-isa.txt)).

| Part | Covers | Tasks | Points |
|---|---|---|---|
| In-Class 1 | latch plumbing and the ALU | 1–3 | 6 |
| In-Class 2 | branch condition, branch target, redirect | 4–5 | 10 |
| Take-Home  | the rest of the required instruction set | 6–7 | 84 |
| Bonus (optional) | the remaining instructions, `lw` and `sw` | 8 | +10 |

That is 100 points for the required work, plus up to 10 bonus points on top.
Partial credit on each part is the percentage of that part's test cases your
processor passes. Run the suites before you submit and hand in whatever passes.

Every piece of code you have to write is marked in the
source with a numbered `Task`.

---

## Setting up

Follow this [document](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf) to access OnDemand ICE and connect to Coder to setup experiment environment. 

Remember to run `source /storage/ice-shared/cs3220/labs_setup.sh` in your terminal to get an environment with
`verilator`, `make`, `g++`. 

---

## What you have to build

The four parts are cumulative: each one runs the earlier suites' instructions as
well, so re-run the earlier suites after every change. The commands quoted below
are explained in [Running things](#running-things), and the file-by-file
breakdown is in [What is in here](#what-is-in-here).

### In-Class 1 — Tasks 1–3, `agex_stage.v`

**Goal:** `./run_tests.sh inclass_1` reports 3 of 3. Those three tests use only
`add` and `addi`, so no branches are needed yet.

AGEX is empty in the skeleton: fetch and decode already work, but nothing
computes a result or hands one to MEM. You supply the three pieces:
**Task 1** unpacks the incoming DE latch, **Task 2** is the ALU, **Task 3** packs
the outgoing AGEX latch.

The thing to understand before you type is how a pipeline latch works here.
Verilog-2001 has no structs, so a stage packs its whole output into one wide
vector and the receiver unpacks it with a concatenation on the left of an
`assign`. Two consequences:

- **Order is the interface.** Only position connects a field to the wire that
  reads it; names do nothing. Verilator catches a wrong total *width*, but a
  wrong *order* compiles cleanly and produces garbage.
- **The receiving stage is the specification.** `de_stage.v` already packs the
  DE latch and `mem_stage.v` already unpacks the AGEX latch, both in files you
  are not editing, so each layout has exactly one correct answer and it is
  already written down somewhere.

For the ALU, note that `op_I_AGEX` decides two things at once: which operands
are used and which operation is applied, which is why one `case` does the whole
job. A combinational block must assign its output on every path or Verilog
infers a latch, so keep a `default`.

**Symptom to recognise:** the design builds and runs, but printed `PC=` values
are wrong or `wregno` names a register the program never mentions. That is a
misaligned concatenation, not an arithmetic bug. Fix the layout first.

---

## Running things

Everything is run from the `lab1/` directory.

```sh
make                    # build the simulator, run the test named in define.vh, and write trace.vcd (waveform)
make clean              # delete obj_dir, the logs and trace.vcd
```

**Running one specific test** — either edit `` `IDMEMINITFILE `` in
[define.vh](define.vh) (it holds a path relative to `lab1/`), or override it on
the command line without touching the file:

```sh
IDMEMINITFILE=$PWD/test/inclass_2/test4.mem make tests
```

The override is passed to Verilator as `+define+`; `define.vh` guards its own
`` `define `` with `` `ifndef ``, so the command line wins and your file is left
alone. Note that imem and dmem are loaded from the *same* file.

**Running a whole suite:**

```sh
./run_tests.sh inclass_1    # the 3 In-Class 1 tests
./run_tests.sh inclass_2    # the 5 In-Class 2 tests
./run_tests.sh takehome     # the 12 take-home tests
./run_tests.sh bonus        # the 32 optional ones
./run_tests.sh all
```

Each leaves `<suite>_tests.log` (the full console output) and
`<suite>_results.log` (one line per test), and prints the names of any tests
that failed.

**Reading the output.** A run prints one line per instruction that reaches
write-back:

```
[28]  PC=0x200 Inst=0x100193 Op=12 wr_reg=1 wregno=3 regval=1
-- stopped at PC=0x204 (end of program) --
Total instructions=1, cycles=9, IPC=0.111111
Passed!
```

`Op` is the internal opcode number from `define.vh` (12 is `` `ADDI_I ``).
Every test program ends with a `0x00000000` word, which decodes to
`` `INVALID_I ``; the simulator stops on the first one that retires. A test passes when it leaves 1 in `gp` (`x3`); otherwise
you get `Failed. exitcode: N`, where `N` is whatever `gp` ended up holding. Each
in-class test writes a different value to `gp` on each wrong path, so read the
`.asm` alongside `N` and it tells you which path the processor took.

**Viewing the wave form.** Follow the instructions in the same [document](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf) to open Signal Viewer to view the waveform for debugging (remember to install the extension: impulse).

**Building a submission:**

```sh
make submit             # writes submission.zip
```

Use this and **DO NOT zip by hand**.

---

## What is in here

### The processor

Five stages, one module each, wired together in `pipeline.v`. Stages talk to
each other only through packed latch vectors whose widths live in `define.vh`.

| File | What it is | Do you edit it? |
|---|---|---|
| `pipeline.v`  | instantiates the five stages and wires them together | no |
| `fe_stage.v`  | fetch: PC latch, instruction memory, redirect on mispredict | no |
| `de_stage.v`  | decode: opcode decode, register file, immediate, hazard scoreboard | Task 6
| `agex_stage.v`| execute: ALU, branch condition, branch target | Tasks 1–5, 7, 8 |
| `mem_stage.v` | data memory | Task 8 (bonus) |
| `wb_stage.v`  | write-back, and the counters the simulator prints from | Task 8 (bonus) |
| `define.vh`   | every constant: opcode numbers, latch widths, the test file path | Task 8 (bonus) |
| `sim_main.cpp`| the C++ testbench Verilator links against | no |
| `Makefile`, `run_tests.sh` | build and test drivers | no |

Most of your work is in `agex_stage.v`. Read `fe_stage.v`, `de_stage.v`,
`mem_stage.v` and `wb_stage.v` anyway.  They are the specification for the
latches you have to build.

### The tests

| Directory | Suite name | What |
|---|---|---|
| `test/inclass_1/` | `inclass_1` | 3 short programs |
| `test/inclass_2/` | `inclass_2` | 5 short programs |
| `test/takehome/` | `takehome` | 12 programs |
| `test/bonus/`    | `bonus`    | 32 programs, optional |

**`test/inclass_1/`** and **`test/inclass_2/`** are short hand-written programs.
Each `.mem` has its `.asm` next to it, and the `readme.txt` in each directory
says what every test covers.

**`test/takehome/`** and **`test/bonus/`** are mostly the real RISC-V test-suite
programs, compiled. The exceptions are `test9`–`test13` (take-home) and
`test14`–`test16` (bonus), which are hand-written assembly and much easier to
debug — start with those. Each compiled test comes as four files:

- `*.S` is assembly using RISC-V macros, defined in
  [test/include/test_macros.h](test/include/test_macros.h) and
  [test/include/riscv_test.h](test/include/riscv_test.h). It also uses ABI names
  and pseudo-instructions — the manual linked under References summarises both.
- `*.dump` is the disassembly produced by the RISC-V gcc compiler. This is the
  file to read when you want to know what actually executes.
- `*.mem` is the memory image the simulator loads.
- `*.dec` is useful with the RISC-V emulator linked under References.

When a compiled test fails, read the log before the waveform: the last `PC=`
line printed is the last instruction that retired, and finding that address in
the `.dump` usually tells you which instruction is wrong.
`python3 test/dumptoasm.py <name>.dump` pulls plain assembly out of a dump.

---

## What to hand in

Submit **`submission.zip`**, produced by `make submit` to Gradescope.

---

## References

- [RISC-V RV32I manual](https://web.eecs.utk.edu/~smarz1/courses/ece356/notes/assembly/)
  — also covers ABI register names and pseudo-instructions, which you need to
  read the take-home tests
- [RISC-V instruction card](https://github.com/jameslzhu/riscv-card/releases/download/latest/riscv-card.pdf)
  — one page, has every encoding
- [RISC-V emulator (Tiny RV2)](https://www.cs.cornell.edu/courses/cs3410/2019sp/riscv/interpreter/)
  — run a program by hand when you are not sure what the right answer is
- [Verilator manual](https://verilator.org/guide/latest/)
- [Signal Viewer setup (impulse extension)](https://github.com/gt-cs3220-2026/cs3220-labs-fall2026/blob/main/lab0/Take_home/ICE_environment_setup.pdf)
  — how to open `trace.vcd` in Coder
- [Tutorial on the RISC-V test suite](https://web.archive.org/web/20221031194615/https://inst.eecs.berkeley.edu/~cs250/fa10/handouts/tut3-riscv.pdf)

