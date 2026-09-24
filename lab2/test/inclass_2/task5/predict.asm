# Start at 0x200. Warm up a repeatedly taken conditional branch.
addi gp, x0, 0
addi t0, x0, 64
addi t1, x0, 0
loop:                       # 0x20c
addi t1, t1, 1
addi t0, t0, -1
bne t0, x0, loop            # 0x214: repeated taken direction; Task 5 also predicts target 0x20c
addi t2, x0, 64
bne t1, t2, fail
addi gp, x0, 1
j done
fail:
addi gp, x0, 0
done:
ecall                       # test completion marker
