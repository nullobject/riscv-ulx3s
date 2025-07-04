MEMORY
{
  rom (rx)  : ORIGIN = 0x00000, LENGTH = 0x10000
  ram (rwx) : ORIGIN = 0x10000, LENGTH = 0x10000
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

  /* Heap starts here and grows upwards */
  . = ALIGN(4);
  _end = .;

  /* Stack grows downwards from the end of RAM */
  _stack_end = ORIGIN(ram) + LENGTH(ram);
  _stack_start = _stack_end - STACK_SIZE;

  /* Ensure heap doesn't overlap with stack */
  ASSERT(_end <= _stack_start, "Error: Heap overlaps with stack")
}
