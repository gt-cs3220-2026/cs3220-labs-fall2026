# CS3220 Lab #6: Systolic Array Design

In this part of the lab, you will generalize the In-Class 1 systolic array and wrap it in an AXI-Stream interface. The skeleton already contains a working In-Class 1 solution, and you will use it for both In-Class 2 and the Take-Home.

| Portion | Instructions | Points |
|---|---|---|
| In-Class 1: 2x2 Systolic Array | Completed in the previous session | 20 pts |
| In-Class 2: NxN Systolic Array | [docs/README_InClass2.md](docs/README_InClass2.md) | 20 pts |
| Take-Home: Parts A, B, C and Report | [docs/README_TakeHome.md](docs/README_TakeHome.md) | 60 pts |
| **Total** | | **100 pts** |

Start with [docs/README_InClass2.md](docs/README_InClass2.md). It covers the background, code structure, and testing procedures used in every portion of this folder.

## Repository Layout

```
docs/    Lab instructions, figures, and the tutorial report
code/    Skeleton code, testbenches, and test scripts
```

## Getting Started

Run every command from inside `code/`:

```
cd code
source init.sh
chmod +x *.sh
./run_inclass2.sh
```

## Files in `code/`

| File | Used in | Edit? |
|---|---|---|
| `systolic_array.v`, `MAC.v`, `ctrl.v` | All portions (contain the In-Class 1 solution) | Yes |
| `systolic_array_axis.v` | Take-Home Part C | Yes |
| `adder.v`, `multiplier.v`, `synchronus_fifo.v` | Provided modules | No |
| `test_systolic_array.cpp`, `data_gen.py` | In-Class 2, Parts A and B | No |
| `data_gen_nk.py` | Part B, `N` < `K` checker | No |
| `test_axis.cpp`, `test_axis_random_drop.cpp`, `data_gen_axi.py` | Part C | No |
| `run_inclass1.sh`, `run_inclass2.sh` | Check the 2x2 starting point; In-Class 2 | No |
| `run.sh`, `run_nk.sh`, `run_axis.sh` | Parts A, B and C | No |
| `Makefile`, `init.sh` | Build and setup | No |

## Files in `docs/`

| File | Contents |
|---|---|
| `README_InClass2.md` | In-Class 2 instructions, background, and testing procedures |
| `README_TakeHome.md` | Take-Home Parts A, B, C, report, and submission |
| `imgs/` | Figures used in the instructions |
| `CS3220_systolic_array_luke_zhang.pdf` | Tutorial report |
