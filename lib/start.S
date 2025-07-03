#include "custom_ops.S"

.section .text

reset_vec:
  la sp, _stack_end
  picorv32_maskirq_insn(zero, zero)
  j start

.balign 16
irq_vec:
  /* Save registers */
	addi sp, sp, -128
	sw x0,   0*4(sp)
	sw x1,   1*4(sp)
	sw x2,   2*4(sp)
	sw x3,   3*4(sp)
	sw x4,   4*4(sp)
	sw x5,   5*4(sp)
	sw x6,   6*4(sp)
	sw x7,   7*4(sp)
	sw x8,   8*4(sp)
	sw x9,   9*4(sp)
	sw x10, 10*4(sp)
	sw x11, 11*4(sp)
	sw x12, 12*4(sp)
	sw x13, 13*4(sp)
	sw x14, 14*4(sp)
	sw x15, 15*4(sp)
	sw x16, 16*4(sp)
	sw x17, 17*4(sp)
	sw x18, 18*4(sp)
	sw x19, 19*4(sp)
	sw x20, 20*4(sp)
	sw x21, 21*4(sp)
	sw x22, 22*4(sp)
	sw x23, 23*4(sp)
	sw x24, 24*4(sp)
	sw x25, 25*4(sp)
	sw x26, 26*4(sp)
	sw x27, 27*4(sp)
	sw x28, 28*4(sp)
	sw x29, 29*4(sp)
	sw x30, 30*4(sp)
	sw x31, 31*4(sp)

  /* Jump to C code */
  jal ra, irq

  /* Load registers */
	lw x0,   0*4(sp)
	lw x1,   1*4(sp)
	lw x2,   2*4(sp)
	lw x3,   3*4(sp)
	lw x4,   4*4(sp)
	lw x5,   5*4(sp)
	lw x6,   6*4(sp)
	lw x7,   7*4(sp)
	lw x8,   8*4(sp)
	lw x9,   9*4(sp)
	lw x10, 10*4(sp)
	lw x11, 11*4(sp)
	lw x12, 12*4(sp)
	lw x13, 13*4(sp)
	lw x14, 14*4(sp)
	lw x15, 15*4(sp)
	lw x16, 16*4(sp)
	lw x17, 17*4(sp)
	lw x18, 18*4(sp)
	lw x19, 19*4(sp)
	lw x20, 20*4(sp)
	lw x21, 21*4(sp)
	lw x22, 22*4(sp)
	lw x23, 23*4(sp)
	lw x24, 24*4(sp)
	lw x25, 25*4(sp)
	lw x26, 26*4(sp)
	lw x27, 27*4(sp)
	lw x28, 28*4(sp)
	lw x29, 29*4(sp)
	lw x30, 30*4(sp)
	lw x31, 31*4(sp)
	addi sp, sp, 128

  /* All done */
  picorv32_retirq_insn()

start:
  /* Copy DATA section */
  la a0, _text_end
  la a1, _data_start
  la a2, _data_end
  bge a1, a2, _end_init_data
_loop_init_data:
  lw a3, 0(a0)
  sw a3, 0(a1)
  addi a0, a0, 4
  addi a1, a1, 4
  blt a1, a2, _loop_init_data
_end_init_data:

  /* Zero-init BSS section */
  la a0, _bss_start
  la a1, _bss_end
  bge a0, a1, _end_init_bss
_loop_init_bss:
  sw zero, 0(a0)
  addi a0, a0, 4
  blt a0, a1, _loop_init_bss
_end_init_bss:

  /* Jump to C code */
  call main

  /* In case main returns, loop forever */
_loop:
  j _loop
