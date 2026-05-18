	if C_START > $1800

	org CURRENT_BANK
	rorg $f000

BANK_1

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
	if (_ENABLE_BLANKLINES == 1)
blank_scanlines_1				;can use blank_scanlines in any bank
	sta WSYNC
	lda sound_mode
	bne skip_blankline_wav_1
	lda #AMPLITUDE
	sta AUDV0
skip_blankline_wav_1
	dex
	bne blank_scanlines_1
	rts
	endif

	if (_ENABLE_POSITIONING == 1)
position_object_1				;can use position_object in any bank
	sec
	sta WSYNC
divide_by_15_pos_1				;A loaded with position
	sbc #15
	bcs divide_by_15_pos_1
	eor #7
	asl
	asl
	asl
	asl
	sta.w HMP0,x				;have X loaded for 0=p0, 1=p1, 2=m0, 3=m1, 4=bl
	sta RESP0,x
	rts

apply_HMOVE_1					;can use apply_HMOVE in any bank
	sta WSYNC
	sta HMOVE
	ldy sound_mode
	bne skip_HMOVE_wav_1
	lda #AMPLITUDE
	sta AUDV0
skip_HMOVE_wav_1
	sta WSYNC
	sta HMCLR
	tya
	bne skip_HMCLR_wav_1
	lda #AMPLITUDE
	sta AUDV0
skip_HMCLR_wav_1
	rts
	endif

do_vblank_1						;can use do_vblank in any bank
	lda sound_mode
	beq skip_vblank_wav_sound_1
	lda #AMPLITUDE
	sta AUDV0
skip_vblank_wav_sound_1
	lda INTIM
	bne do_vblank
	sta VBLANK
	rts

do_overscan_1					;can use do_overscan in any bank
	ldx #2
	stx WSYNC
	stx VBLANK
	lda sound_mode
	beq skip_overscan_wav_sound_1
	lda #AMPLITUDE
	sta AUDV0
skip_overscan_wav_sound_1
	lda overscan_timer
	sta TIM64T
	rts
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 00 Routine @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
kernel_00

	lda #72
	ldx #0							;index 0 = p0 object
	jsr position_object				;using cross-bank position routine

	lda #80
	ldx #1							;index 0 = p1 object
	jsr position_object				;using cross-bank position routine

	jsr apply_HMOVE

	jsr do_vblank

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

	jsr do_overscan


	rts
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 00 Routine @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 01 Routine @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
kernel_01

	jsr do_vblank

_kernel_01_loop				;kernel_01 demontrates the FastJump streams
	sta WSYNC

	if (_ENABLE_WAV_SOUND == 1)
	lda #AMPLITUDE
	sta AUDV0				;as well as handling wave samples
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


	jsr do_overscan

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