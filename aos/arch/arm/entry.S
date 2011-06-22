/*
 *  Copyright (C) 2011 Andrei Warkentin <andrey.warkentin@gmail.com>
 *
 * This program is free software ; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License version 2 as
 * published by the Free Software Foundation.
 */

#define DebugUartBase 0x70006040
#define CpuVectorBaseAddress 0x0
	
.globl _aos_entry

.macro	dputc,val
mov	r0, \val
bl	putc
.endm

	.section ".start", #alloc, #execinstr
	.align
_aos_entry:
	.text
	.type	_aos_entry, #function
	.rept	8
	mov	r0, r0
	.endr

	b	1f
	.word	0x016f2818		@ Magic numbers to help the loader
	.word   _aos_entry
	.word   _end
1:
	mov   	ip, r2	                @ Save ATAG pointer.
	dputc 	#'0'

	@ Enable Strict alignment checking & Instruction cache.
	mrc     p15, 0, r0, c1, c0, 0
	bic     r0, r0, #0x00002300     @ clear bits 13, 9:8 (--V- --RS)
	bic     r0, r0, #0x00000005     @ clear bits 0, 2 (---- -C-M)
	orr     r0, r0, #0x00000002     @ set bit 1 (A) Align
	orr     r0, r0, #0x00001000     @ set bit 12 (I) enable I-Cache
	mcr     p15, 0, r0, c1, c0, 0
	dputc 	#'1'

	@ Enable NEON register in case folks want to use them for optimizations (CopyMem)
	mrc     p15, 0, r0, c1, c0, 2
	orr     r0, r0, #0x00f00000   @ Enable VFP access (V* instructions)
	mcr     p15, 0, r0, c1, c0, 2
	mov     r0, #0x40000000       @ Set EN bit in FPEXC
	mcr     p10,#0x7,r0,c8,c0,#0
	dputc 	#'2'
	
	@ Set CPU vectors.
	adr 	r0, vectors
	adr     r1, vectors_end
	ldr	r2, =CpuVectorBaseAddress
	mcr     p15, 0, r2, c12, c0, 0
1:	ldr     r3, [r0], #4
	str 	r3, [r2], #4
	cmp	r0, r1
	blo 1b	
	isb
	dputc 	#'3'

	@ Load stack and fix-up GOT.
	adr	r0, LC0
	ldmia 	r0, {r1, r2, r3, sp}
	subs	r0, r0, r1 		@ r0 = actual - linked
	add     r2, r2, r0
	add     r3, r3, r0
	add	sp, sp, r0

1:	ldr	r6, [r2], #0		
	add	r6, r6, r0		@ actual = linked + r0
	str	r6, [r2], #4		
	cmp	r2, r3
	blo	1b
	dputc 	#'4'	
	dputc   #'\n'
	dputc   #'\r'

	mov	r0, ip	@ ATAG pointer.
	blx	c_entry
	b 	dead_loop

	@ We are manually relocating this down to VectorsBase.
vectors:
	b dead_loop   @ RESET, never taken since it always goes to 0x0
	b und_vector  @ UND
	b swi_vector  @ SWI
	b pabt_vector @ PABT
	b dabt_vector @ DABT
	b unk_vector  @ ?
	b irq_vector  @ IRQ
	b fiq_vector  @ FIQ
und_vector:
	dputc 	#'U'
	b 	dead_loop
swi_vector:
	dputc 	#'S'
	b 	dead_loop
pabt_vector:	
	dputc 	#'P'
	b 	dead_loop
dabt_vector:	
	dputc 	#'D'
	b 	dead_loop
unk_vector:	
	dputc 	#'?'
	b 	dead_loop
irq_vector:	
	dputc 	#'I'
	b 	dead_loop
fiq_vector:	
	dputc 	#'F'
	b 	dead_loop
dead_loop:
	dputc 	#'D'
	dputc 	#'E'
	dputc 	#'A'
	dputc 	#'D'
	dputc 	#'\n'
	dputc 	#'\r'
1:	b 	1b

putc:
	ldr r1, =DebugUartBase
	cmp	r1, #0
	beq 	1f
	strb	r0, [r1]
1:	mov     pc, lr
vectors_end:
	
	.ltorg
	
	.align	2
	.type	LC0, #object
LC0:		
	.word	LC0			   @ r1
	.word	_got_start		   @ r2
	.word	_got_end		   @ r3
	.word	_stack_end		   @ sp
	.align
	
	.section ".bss"
	.align  2
_stack:	.space	4096
_stack_end: