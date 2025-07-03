MEMORY
{
  rom (rx)  : ORIGIN = 0x0000, LENGTH = 0x4000
  ram (rwx) : ORIGIN = 0x4000, LENGTH = 0x4000
}

STACK_SIZE = 4K;

SECTIONS
{
  .text :
  {
    . = ALIGN(4);
    _text_start = .;
    *(.text .text.*)
    *(.rodata .rodata.*)
    *(.srodata .srodata.*)
    . = ALIGN(4);
    _text_end = .;
  } > rom

  .data :
  {
    . = ALIGN(4);
    _data_start = .;
    *(.data .data.*)
    *(.sdata .sdata.*)
    . = ALIGN(4);
    _data_end = .;
  } > ram AT> rom

  .bss (NOLOAD) :
  {
    . = ALIGN(4);
    _bss_start = .;
    *(.bss .bss.*)
    *(.sbss .sbss.*)
    *(COMMON)
    . = ALIGN(4);
    _bss_end = .;
  } > ram

  .stack (NOLOAD):
  {
    . = ALIGN(4);
    _stack_start = .;
    . = . + STACK_SIZE;
    . = ALIGN(4);
    _stack_end = .;
  } > ram

  . = ALIGN(4);
  _end = .;
}
