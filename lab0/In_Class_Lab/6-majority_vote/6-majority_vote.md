# Lab 0 - Majority Vote

A 3-input majority circuit outputs 1 when at least two of its inputs are 1.

1. Create a module named `majority3` with three 1-bit inputs `x`, `y`, and `z`, and one 1-bit output `vote`.
2. `vote` should be 1 if at least two inputs are 1, and 0 otherwise.

| x | y | z | vote |
| :--- | :--- | :--- | :--- |
| 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 0 |
| 0 | 1 | 0 | 0 |
| 0 | 1 | 1 | 1 |
| 1 | 0 | 0 | 0 |
| 1 | 0 | 1 | 1 |
| 1 | 1 | 0 | 1 |
| 1 | 1 | 1 | 1 |

One way to express this is:

`vote = (x & y) | (x & z) | (y & z)`
