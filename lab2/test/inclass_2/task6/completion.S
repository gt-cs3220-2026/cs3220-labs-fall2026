# Completion epilogue patched into the supplied legacy towers.mem at 0x784.
# Its C source is test/unused/test/towers/towers.c: NUM_DISCS=8 and main
# returns towers.numMoves in a0, so a successful run must return 255.
# The old image only ran into NOPs/zeros and never set a pass result.
.org 0x784
addi t0, x0, 255
addi gp, x0, 2
bne a0, t0, done
addi gp, x0, 1
done:
ecall                         # retired marker consumed by the simulator
