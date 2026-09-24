// Short loops: T,T,N. The two loop branches share a 16-entry BTB index.
  .section .text.stress,"ax",@progbits
  .option norvc
  .globl branch_pressure
branch_pressure:
  li t0, 32
counter_outer:
  li t1, 3
counter_inner:
  addi t1, t1, -1
counter_branch:
  bne t1, zero, counter_inner
  addi t0, t0, -1
  .fill 14, 4, 0x00000013
counter_outer_branch:
  bne t0, zero, counter_outer
  ret
