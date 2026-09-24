// Task 7: two taken passes compete with one not-taken pass in the PHT.
  .section .text.stress,"ax",@progbits
  .option norvc
  .globl branch_pressure
branch_pressure:
  li t0, 8
towers_outer:
  li t1, 2
  j towers_taken

  .balign 1024, 0
  nop
  nop
  nop
towers_taken:
  // PC word indices 4*i+3 XOR history 0xff give indices 4*(63-i).
  .rept 63
  beq zero, zero, 1f
  nop
  nop
  nop
1:
  .endr
  beq zero, zero, towers_repeat

towers_not_taken:
  // PC word indices 4*i XOR history 0x00 alias the taken group.
  .rept 64
  bne zero, zero, 2f
  nop
  nop
  nop
2:
  .endr
  addi t0, t0, -1
  bne t0, zero, towers_outer
  ret

towers_repeat:
  addi t1, t1, -1
  bne t1, zero, towers_taken
  j towers_not_taken
