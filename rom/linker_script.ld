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
    *(.text)
    *(.text*)
    *(.rodata)
    *(.rodata*)
    *(.srodata)
    *(.srodata*)
    . = ALIGN(4);
    _etext = .;
    _sidata = _etext;
  } > rom

  .data : AT(_sidata)
  {
    . = ALIGN(4);
    _sdata = .;
    _ram_start = .;
    . = ALIGN(4);
    *(.data)
    *(.data*)
    *(.sdata)
    *(.sdata*)
    *(.fastcode*)
    . = ALIGN(4);
    _edata = .;
  } > ram

  .bss :
  {
    . = ALIGN(4);
    _sbss = .;
    *(.bss)
    *(.bss*)
    *(.sbss)
    *(.sbss*)
    *(COMMON)
    . = ALIGN(4);
    _ebss = .;
  } > ram
}
