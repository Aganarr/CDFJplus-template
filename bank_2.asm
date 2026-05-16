	if C_START > $2800

	org CURRENT_BANK
	rorg $f000

BANK_2

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
blank_scanlines_2
	sta WSYNC
	dex
	bne blank_scanlines_2			;can use blank_scanlines in any bank
	rts

	if (_ENABLE_WAV_SOUND == 1)
blank_scanlines_aud_2				;can use blank_scanlines_aud in any bank
	sta WSYNC
	lda #AMPLITUDE
	sta AUDV0
	dex
	bne blank_scanlines_aud_2
	rts
	endif

	if (_ENABLE_POSITIONING == 1)
position_object_2				;can use position_object in any bank
	sec
	sta WSYNC
divide_by_15_pos_2
	sbc #15
	bcs divide_by_15_pos_2
	eor #7
	asl
	asl
	asl
	asl
	sta.w HMP0,x				;have X loaded for 0=p0, 1=p1, 2=m0, 3=m1, 4=bl
	sta RESP0,x
	rts
	endif
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@







BANK2_CODE_SIZE = * - BANK_2;
	echo "---- BANK2", BANK2_CODE_SIZE, "bytes"
	echo "---- BANK2", ($fff0 - *), "bytes free"

CURRENT_BANK set CURRENT_BANK + $1000

	endif