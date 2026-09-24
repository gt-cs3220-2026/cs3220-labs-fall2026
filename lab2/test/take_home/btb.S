// Alternate between two taken branches separated by 64 bytes.
  .section .text.stress,"ax",@progbits
  .option norvc
  .globl branch_pressure
branch_pressure:
  li t0, 128
btb_first:
  beq zero, zero, btb_second_start
  .fill 14, 4, 0x00000013
btb_second_start:
  addi t0, t0, -1
btb_second:
  bne t0, zero, btb_first
  ret
