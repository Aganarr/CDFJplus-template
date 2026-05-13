	if C_START > $6800

	org CURRENT_BANK
	rorg $f000

BANK_6

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
blank_scanlines_6
	sta WSYNC
	dex
	bne blank_scanlines_6			;can use .blank_scanlines in any bank
	rts

	if (_ENABLE_WAV_SOUND == 1)
blank_scanlines_aud_6				;can use .blank_scanlines_aud in any bank
	sta WSYNC
	lda #AMPLITUDE
	sta AUDV0
	dex
	bne blank_scanlines_aud_6
	rts
	endif
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@







BANK6_CODE_SIZE = * - BANK_6;
	echo "---- BANK6", BANK6_CODE_SIZE, "bytes"
	echo "---- BANK6", ($fff0 - *), "bytes free"

CURRENT_BANK set CURRENT_BANK + $1000

	endif





