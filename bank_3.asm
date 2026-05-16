	if C_START > $3800
	
	org CURRENT_BANK
	rorg $f000

BANK_3

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
blank_scanlines_3
	sta WSYNC
	dex
	bne blank_scanlines_3			;can use blank_scanlines in any bank
	rts

	if (_ENABLE_WAV_SOUND == 1)
blank_scanlines_aud_3				;can use blank_scanlines_aud in any bank
	sta WSYNC
	lda #AMPLITUDE
	sta AUDV0
	dex
	bne blank_scanlines_aud_3
	rts
	endif

	if (_ENABLE_POSITIONING == 1)
position_object_3				;can use position_object in any bank
	sec
	sta WSYNC
divide_by_15_pos_3
	sbc #15
	bcs divide_by_15_pos_3
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







BANK3_CODE_SIZE = * - BANK_3;
	echo "---- BANK3", BANK3_CODE_SIZE, "bytes"
	echo "---- BANK3", ($fff0 - *), "bytes free"

CURRENT_BANK set CURRENT_BANK + $1000

	endif



