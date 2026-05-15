//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
// @ Required ASM Header
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	.text
	.thumb

//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@ ClearCannel - 0s out 192 byte DD region
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	.global ClearChannel
	.align 2
	.thumb_func
ClearChannel:
	movs r3, #6
	movs r1, #0
loop_clear_channel:
	
	str  r1, [r0]
	str  r1, [r0,#4]
	str  r1, [r0,#8]
	str  r1, [r0,#12]
	str  r1, [r0,#16]
	str  r1, [r0,#20]
	str  r1, [r0,#24]
	str  r1, [r0,#28]

	add r0, #32
	sub r3, #1
	bne loop_clear_channel

	bx   lr
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@ MemCopy32 - 32bit aligned S/D copy
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	.global MemCopy32
    .thumb
    .thumb_func
MemCopy32:
loop_memCopy32_unrolled:
	cmp r2, #8
	blt loop_memCopy32_small
    ldr     r3, [r1, #0]
    str     r3, [r0, #0]
    ldr     r3, [r1, #4]
    str     r3, [r0, #4]
	ldr     r3, [r1, #8]
    str     r3, [r0, #8]
	ldr     r3, [r1, #12]
    str     r3, [r0, #12]
	ldr     r3, [r1, #16]
    str     r3, [r0, #16]
	ldr     r3, [r1, #20]
    str     r3, [r0, #20]
	ldr     r3, [r1, #24]
    str     r3, [r0, #24]
	ldr     r3, [r1, #28]
    str     r3, [r0, #28]
    
	add    r1, #32
    add    r0, #32
	sub r2, #8
	beq done_memCopy32
	b loop_memCopy32_unrolled

loop_memCopy32_small:
	cmp r2, #0
	beq done_memCopy32

    ldr     r3, [r1, #0]
    str     r3, [r0, #0]

    add    r1, #4
    add    r0, #4
    sub    r2, #1
    b       loop_memCopy32_small

done_memCopy32:
    bx      lr
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@ Random - 32 bit LFSR
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	.global Random
    .thumb
    .thumb_func
Random:
	cmp r0, #0
beq done_rand
	mov r2, #0b0000000011000101
	ldr r1, =rand
	ldr r3, [r1]
loop_rand:
	lsl r3, r3, #1
	bcc skip_rand_eor
	eor r3, r2
skip_rand_eor:
	sub r0, r0, #1
	bne loop_rand
	str r3, [r1]
done_rand:
    bx      lr
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
//@ calcPosition - calculate the Rough/Fine values for object positioning
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	.global calcPosition
    .thumb
    .thumb_func
calcPosition:
	mov		r1, #0
	add		r0, r0, #4
loop_calc_P_rough:
	cmp		r0, #15
	blo		done_calc_P_rough
	sub		r0, r0, #15
	add		r1, r1, #1
	b		loop_calc_P_rough
done_calc_P_rough:
	ldr		r2, =finePositionTable
	ldrb	r0, [r2, r0]
	ldr		r2, =rough_position
	strb	r1, [r2]
	ldr		r2, =fine_position
	strb	r0, [r2]
	bx		lr

finePositionTable:
	.byte	0x70, 0x60, 0x50, 0x40, 0x30
	.byte	0x20, 0x10, 0x00, 0xf0, 0xe0
	.byte	0xd0, 0xc0, 0xb0, 0xa0, 0x90
//@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


