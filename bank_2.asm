	if C_START > $2800

	org CURRENT_BANK
	rorg $f000

BANK_2

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
blank_scanlines_2
	sta WSYNC
	dex
	bne blank_scanlines_2			;can use .blank_scanlines in any bank
	rts

	if (_ENABLE_WAV_SOUND == 1)
blank_scanlines_aud_2				;can use .blank_scanlines_aud in any bank
	sta WSYNC
	lda #AMPLITUDE
	sta AUDV0
	dex
	bne blank_scanlines_aud_2
	rts
	endif
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@







BANK2_CODE_SIZE = * - BANK_2;
	echo "---- BANK2", BANK2_CODE_SIZE, "bytes"
	echo "---- BANK2", ($fff0 - *), "bytes free"

CURRENT_BANK set CURRENT_BANK + $1000

	endif