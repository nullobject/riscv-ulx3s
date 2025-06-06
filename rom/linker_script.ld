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
  } > rom

  .data :
  {
    . = ALIGN(4);
    *(.data)
    *(.sdata)
  } > ram

  .bss :
  {
    . = ALIGN(4);
    _szero = .;
    *(.bss)
    . = ALIGN(4);
    _ezero = .;
  } > ram

  .heap :
  {
    . = ALIGN(4);
    *(.heap)
  } > ram
}
