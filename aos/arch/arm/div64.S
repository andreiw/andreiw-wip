/*
 *  arch/arm/div64.S
 *
 *  Optimized computation of 64-bit dividend / 32-bit divisor
 *
 *  Author:	Nicolas Pitre
 *  Created:	Oct 5, 2003
 *  Copyright:	Monta Vista Software, Inc.
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License version 2 as
 *  published by the Free Software Foundation.
 */

#include <linkage.h>

/*
 * __do_div64: perform a division with 64-bit dividend and 32-bit divisor.
 *
 * Note: Calling convention is totally non standard for optimal code.
 *       This is meant to be used by do_div() from include/asm/div64.h only.
 *
 * Input parameters:
 * 	r1-r0	= dividend (clobbered)
 * 	r4	= divisor (preserved)
 *
 * Output values:
 * 	r3-r2	= result
 * 	r1	= remainder
 *
 * Clobbered regs: r0, ip
 */

ENTRY(__do_div64)

	@ Test for easy paths first.
	subs	ip, r4, #1
	bls	9f			@ divisor is 0 or 1
	tst	ip, r4
	beq	8f			@ divisor is power of 2

	@ See if we need to handle upper 32-bit result.
	cmp	r1, r4
	mov	r3, #0
	blo	3f

	@ Align divisor with upper part of dividend.
	@ The aligned divisor is stored in r2 preserving the original.
	@ The bit position is stored in ip.

	clz	r2, r4
	clz	ip, r1
	sub	r2, r2, ip
	mov	ip, #1
	mov	ip, ip, lsl r2
	mov	r2, r4, lsl r2

	@ The division loop for needed upper bit positions.
 	@ Break out early if dividend reaches 0.
2:	cmp	r1, r2
	orrcs	r3, r3, ip
	subcss	r1, r1, r2
	movnes	ip, ip, lsr #1
	mov	r2, r2, lsr #1
	bne	2b

	@ See if we need to handle lower 32-bit result.
3:	cmp	r1, #0
	mov	r2, #0
	cmpeq	r0, r4
	movlo	r1, r0
	movlo	pc, lr

	@ The division loop for lower bit positions.
	@ Here we shift remainer bits leftwards rather than moving the
	@ divisor for comparisons, considering the carry-out bit as well.
	mov	ip, #0x80000000
4:	movs	r0, r0, lsl #1
	adcs	r1, r1, r1
	beq	6f
	cmpcc	r1, r4
5:	orrcs	r2, r2, ip
	subcs	r1, r1, r4
	movs	ip, ip, lsr #1
	bne	4b
	mov	pc, lr

	@ The top part of remainder became zero.  If carry is set
	@ (the 33th bit) this is a false positive so resume the loop.
	@ Otherwise, if lower part is also null then we are done.
6:	bcs	5b
	cmp	r0, #0
	moveq	pc, lr

	@ We still have remainer bits in the low part.  Bring them up.

	clz	r1, r0			@ we know r1 is zero here so...
	add	r1, r1, #1
	mov	r0, r0, lsl r1
	mov	ip, ip, lsr r1

	@ Current remainder is now 1.  It is worthless to compare with
	@ divisor at this point since divisor can not be smaller than 3 here.
	@ If possible, branch for another shift in the division loop.
	@ If no bit position left then we are done.
	movs	ip, ip, lsr #1
	mov	r1, #1
	bne	4b
	mov	pc, lr

8:	@ Division by a power of 2: determine what that divisor order is
	@ then simply shift values around

	clz	ip, r4
	rsb	ip, ip, #31

	mov	r3, r1, lsr ip
	mov	r2, r0, lsr ip
	rsb	ip, ip, #32
 	orr	r2, r2, r1, lsl ip
	mov	r1, r0, lsl ip
	mov	r1, r1, lsr ip
	mov	pc, lr

	@ eq -> division by 1: obvious enough...
9:	moveq	r2, r0
	moveq	r3, r1
	moveq	r1, #0
	moveq	pc, lr

	@ Division by 0:
	str	lr, [sp, #-8]!
	bl	__div0

	@ as wrong as it could be...
	mov	r2, #0
	mov	r3, #0
	mov	r1, #0
	ldr	pc, [sp], #8

ENDPROC(__do_div64)
