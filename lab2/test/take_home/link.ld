OUTPUT_ARCH("riscv")
ENTRY(_start)

SECTIONS
{
  .text 0x200 : {
    *(.text.init)
    *(.text)
    *(.text.startup)
  }
  .text.stress 0x4000 : { *(.text.stress) }
  . = 0xa000;
  .data : { *(.data*) *(.rodata*) *(.sdata*) }
  .bss : { *(.bss*) *(.sbss*) *(COMMON) }
  STACK = 0xff00;
  /DISCARD/ : { *(.comment) *(.riscv.attributes) *(.eh_frame*) }
}
