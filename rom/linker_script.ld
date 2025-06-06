MEMORY
{
  rom (rx) : ORIGIN = 0x0000, LENGTH = 0x1000
  ram (rwx) : ORIGIN = 0x1000, LENGTH = 0x1000
}

SECTIONS
{
  .text :
  {
    . = ALIGN(4);
    _stext = .;
    *(.text)
    *(.rodata)
    . = ALIGN(4);
    _etext = .;
  } > rom

  .data : AT(ADDR(.text) + SIZEOF(.text))
  {
    . = ALIGN(4);
    _sdata = .;
    *(.data)
    *(.sdata)
    . = ALIGN(4);
    _edata = .;
  } > ram

  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss)
    . = ALIGN(4);
    _ebss = .;
  } > ram
}
