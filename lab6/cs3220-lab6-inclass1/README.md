# CS3220 Lab #6 In-Class 1: 2x2 Systolic Array

In this session, you will build a 2x2 output-stationary systolic array.

| Portion | Instructions | Points |
|---|---|---|
| In-Class 1: 2x2 Systolic Array | [docs/README_InClass1.md](docs/README_InClass1.md) | 20 pts |

Start with [docs/README_InClass1.md](docs/README_InClass1.md). It covers the background, code structure, and testing procedures.

## Repository Layout

```
docs/    Lab instructions, figures, and the tutorial report
code/    Skeleton code, testbench, and test script
```

## Getting Started

Run every command from inside `code/`:

```
cd code
source init.sh
chmod +x *.sh
./run_inclass1.sh
```

## Files in `code/`

| File | Used for | Edit? |
|---|---|---|
| `systolic_array.v`, `MAC.v`, `ctrl.v` | Your design | Yes |
| `adder.v`, `multiplier.v`, `synchronus_fifo.v` | Provided modules | No |
| `test_systolic_array.cpp`, `data_gen.py` | Testbench and checker | No |
| `run_inclass1.sh` | In-Class 1 test script | No |
| `Makefile`, `init.sh` | Build and setup | No |

## Files in `docs/`

| File | Contents |
|---|---|
| `README_InClass1.md` | In-Class 1 instructions, background, and testing procedures |
| `imgs/` | Figures used in the instructions |
| `CS3220_systolic_array_luke_zhang.pdf` | Tutorial report |
