	if C_START > $5800

	org CURRENT_BANK
	rorg $f000

BANK_5

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
blank_scanlines_5
	sta WSYNC
	dex
	bne blank_scanlines_5			;can use .blank_scanlines in any bank
	rts

	if (_ENABLE_WAV_SOUND == 1)
blank_scanlines_aud_5				;can use .blank_scanlines_aud in any bank
	sta WSYNC
	lda #AMPLITUDE
	sta AUDV0
	dex
	bne blank_scanlines_aud_5
	rts
	endif
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@







BANK5_CODE_SIZE = * - BANK_5;
	echo "---- BANK5", BANK5_CODE_SIZE, "bytes"
	echo "---- BANK5", ($fff0 - *), "bytes free"

CURRENT_BANK set CURRENT_BANK + $1000

	endif






