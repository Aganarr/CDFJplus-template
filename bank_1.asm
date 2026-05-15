	if C_START > $1800

	org CURRENT_BANK
	rorg $f000

BANK_1

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
blank_scanlines_1
	sta WSYNC
	dex
	bne blank_scanlines_1			;can use .blank_scanlines in any bank
	rts

	if (_ENABLE_WAV_SOUND == 1)
blank_scanlines_aud_1				;can use .blank_scanlines_aud in any bank
	sta WSYNC
	lda #AMPLITUDE
	sta AUDV0
	dex
	bne blank_scanlines_aud_1
	rts
	endif
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 00 Routine @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
kernel_00

	ldx #192
kernel_00_loop				;kernel_00 shows a "standard" display loop
	sta WSYNC

	lda #DS0DATA
	sta COLUBK

	ldy #8
	lda amp_table1,y
	sta GRP0
	lda amp_table2,y
	sta GRP1	

	dex
	bne kernel_00_loop

	rts
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 00 Routine @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 01 Prep @@@@@@@@@@@@@@@@@@@@@@@@@
k_prep_01

	sta WSYNC
	lda #AMPLITUDE					;2
	sta AUDV0						;3,5
	sta $2d							;3,8 - delay code
	lda #DS30DATA					;2,10
	sta HMP0						;3,13
	ldx #DS30DATA					;2,15
loop_position_p0_k1
	dex								;2,17
	bpl loop_position_p0_k1			;2,19
	sta RESP0						;3,22

	sta WSYNC
	lda #AMPLITUDE					;2
	sta AUDV0						;3,5
	sta $2d							;3,8 - delay code
	lda #DS30DATA					;2,10
	sta HMP1						;3,13
	ldx #DS30DATA					;2,15
loop_position_p1_k1
	dex								;2,17
	bpl loop_position_p1_k1			;2,19
	sta RESP1						;3,22

	sta WSYNC
	sta HMOVE

	sta WSYNC
	sta HMCLR

	rts
;@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 01 Prep @@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 01 Routine @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
kernel_01

_kernel_01_loop				;kernel_01 demontrates the FastJump streams
	sta WSYNC

	if (_ENABLE_WAV_SOUND == 1)
	lda #AMPLITUDE
	sta AUDV0			;as well as handling wave samples
	tay
	endif

	lda #DS0DATA
	sta COLUBK

	lda amp_table1,y
	sta GRP0
	lda amp_table2,y
	sta GRP1

	jmp FASTJMP1
_kernel_01_done

	rts
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 01 Routine @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

amp_table2
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
	.byte #%00000000
amp_table1
	.byte #%00000000
	.byte #%10000000
	.byte #%11000000
	.byte #%11100000
	.byte #%11110000
	.byte #%11111000
	.byte #%11111100
	.byte #%11111110
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111
	.byte #%11111111









BANK1_CODE_SIZE = * - BANK_1;
	echo "---- BANK1", BANK1_CODE_SIZE, "bytes"
	echo "---- BANK1", ($fff0 - *), "bytes free"

CURRENT_BANK set CURRENT_BANK + $1000

	endif