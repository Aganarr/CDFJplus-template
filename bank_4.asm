	if C_START > $4800

	org CURRENT_BANK
	rorg $f000

BANK_4

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
	if (_ENABLE_BLANKLINES == 1)
blank_scanlines_4				;can use blank_scanlines in any bank
	sta WSYNC
	lda sound_mode
	bne skip_blankline_wav_4
	lda #AMPLITUDE
	sta AUDV0
skip_blankline_wav_4
	dex
	bne blank_scanlines_4
	rts
	endif

	if (_ENABLE_POSITIONING == 1)
position_object_4				;can use position_object in any bank
	sec
	sta WSYNC
divide_by_15_pos_4				;A loaded with position
	sbc #15
	bcs divide_by_15_pos_4
	eor #7
	asl
	asl
	asl
	asl
	sta.w HMP0,x				;have X loaded for 0=p0, 1=p1, 2=m0, 3=m1, 4=bl
	sta RESP0,x
	rts

apply_HMOVE_4					;can use apply_HMOVE in any bank
	sta WSYNC
	sta HMOVE
	ldy sound_mode
	bne skip_HMOVE_wav_4
	lda #AMPLITUDE
	sta AUDV0
skip_HMOVE_wav_4
	sta WSYNC
	sta HMCLR
	tya
	bne skip_HMCLR_wav_4
	lda #AMPLITUDE
	sta AUDV0
skip_HMCLR_wav_4
	rts
	endif

do_vblank_4						;can use do_vblank in any bank
	lda sound_mode
	beq skip_vblank_wav_sound_4
	lda #AMPLITUDE
	sta AUDV0
skip_vblank_wav_sound_4
	lda INTIM
	bne do_vblank
	sta VBLANK
	rts

do_overscan_4					;can use do_overscan in any bank
	ldx #2
	stx WSYNC
	stx VBLANK
	lda sound_mode
	beq skip_overscan_wav_sound_4
	lda #AMPLITUDE
	sta AUDV0
skip_overscan_wav_sound_4
	lda overscan_timer
	sta TIM64T
	rts
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@







BANK4_CODE_SIZE = * - BANK_4;
	echo "---- BANK4", BANK4_CODE_SIZE, "bytes"
	echo "---- BANK4", ($fff0 - *), "bytes free"

CURRENT_BANK set CURRENT_BANK + $1000

	endif





