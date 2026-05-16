CURRENT_BANK set $0800

	org CURRENT_BANK
	rorg $f000

BANK_0

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ These routines put at beginning of each bank so all have access @@@@@@@@@@@@@@@@@@@@@
blank_scanlines
	sta WSYNC
	dex
	bne blank_scanlines			;can use blank_scanlines in any bank
	rts

	if (_ENABLE_WAV_SOUND == 1)
blank_scanlines_aud				;can use blank_scanlines_aud in any bank
	sta WSYNC
	lda AMPLITUDE
	sta AUDV0
	dex
	bne blank_scanlines_aud
	rts
	endif

	if (_ENABLE_POSITIONING == 1)
position_object					;can use position_object in any bank
	sec
	sta WSYNC
divide_by_15_pos         
	sbc #15
	bcs divide_by_15_pos         
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

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@ Code block that gets copied into RAM for bank routine dispatch @@@@@@@@@@@@@@@@@
jump_code
	cmp BANK0
	jsr jump_code
	cmp BANK0
	rts
;@@@@@@@@@@@@@@@@@ Code block that gets copied into RAM for bank routine dispatch @@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Cart Reset @@@@@@@@@@@@@@@@@@@@@@@@@@@@
start
	sei
	cld
clear_stack
	ldx #$0a					; ASL opcode = $0A
	inx
	txs
	pha
	bne clear_stack+1 

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@ Software Init @@@@@@@@@@@@@@@@@@@@@@@@@@@

	if (_ENABLE_SAVEKEY == 1)
	jsr read_save_key			;<SaveKey> sets sk_detect with presence of SaveKey
	endif

	ldx #9						;@ <FRAMEWORK>
loop_init_jump_code				;@
	lda jump_code,x				;@ Code needed for bank routine
	sta jump_code_RAM,x			;@ dispatch handler
	dex							;@
	bpl loop_init_jump_code		;@
	inx							;@
	stx DSPTR					;@
	stx DSPTR					;@
	stx DSWRITE					;@
	stx SETMODE					;@ FastFetch ON
	dex							;@
	stx call_fn					;@
	stx CALLFN					;@ Init ARM call

	lda #DS31DATA				;@
	sta kernel					;@ read initial states

	if (_ENABLE_WAV_SOUND == 1)
	lda #DS31DATA				;@ from ARM
	sta sound_mode				;@
	sta sound_save				;@
	tax							;@
	lda sound_mode_table,x		;@
	sta SETMODE					;@ set proper sound mode
	lda call_fn_table,x			;@
	sta call_fn					;@ apply proper function caller
	endif

	if (_ENABLE_TV_DETECT == 1)
	ldy _DETECT_FRAME_COUNT		;@
loop_init_frames				;@
	lda #%1110					;@
vertsync_init					;@
	sta WSYNC					;@ 10 dedicated 262 scanline frames to
	sta VSYNC					;@ time and detect TV type
	lsr 						;@
	bne vertsync_init			;@
	lda #$ff					;@
	sta CALLFN					;@
	ldx #129					;@	number of dual scanlines needed to make a 262 scanline frame with VSYNC
loop_frame_delay_init			;@
	sta WSYNC					;@
	sta WSYNC					;@
	dex							;@
	bne loop_frame_delay_init	;@
	dey							;@
	bpl loop_init_frames		;@
								;@
	lda #DS31DATA				;@
	sta tv_type					;@
	endif



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Game Loop @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
main_game_loop

	if (_ENABLE_WAV_SOUND == 1)
	lda sound_mode				; compare this frame's sound mode
	cmp sound_save				; to last frame's
	beq skip_change_modes		;
	sta sound_save				; apply new mode if change
	tax							; is detected
	lda sound_mode_table,x		;
	sta SETMODE					;
	lda call_fn_table,x			;
	sta call_fn					;
skip_change_modes				;
	tax							; branch to proper frame handler
	bne main_game_loop_sampled	; standard TIA or sampled sound
	endif

	if (_ENABLE_TIA_SOUND == 1) || ((_ENABLE_TIA_SOUND == 0) && (_ENABLE_WAV_SOUND == 0))	;safety net in case BOTH get set to 0
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Game Loop - Standard Sounds @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
main_game_loop_standard

;@@@@@@@@@@@@@@@@@@@@
	lda #%1110
vertsync_std
	sta WSYNC
	sta VSYNC
	lsr 
	bne vertsync_std
	
	ldx tv_type
	lda vblank_table,x
	sta TIM64T
;@@@@@@@@@@@@@@@@@@@@

	jsr vblank_ARM

;@@@@@@@@@@@@@@@@@@@@
wait_vblank_end_std
	lda INTIM
	bne wait_vblank_end_std
	sta VBLANK
;@@@@@@@@@@@@@@@@@@@@

	ldx kernel
	jsr call_bank_routine

;@@@@@@@@@@@@@@@@@@@@
	lda #2
	sta WSYNC
	sta VBLANK
	ldx tv_type
	lda overscan_table,x
	sta TIM64T
;@@@@@@@@@@@@@@@@@@@@

	jsr overscan_ARM

	lda audc0
	sta AUDC0
	lda audf0
	sta AUDF0
	lda audv0
	sta AUDV0
	lda audc1
	sta AUDC1
	lda audf1
	sta AUDF1
	lda audv1
	sta AUDV1

;@@@@@@@@@@@@@@@@@@@@
wait_overscan_std
	lda INTIM	
	bne wait_overscan_std
;@@@@@@@@@@@@@@@@@@@@

	jmp main_game_loop
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Game Loop - Standard Sounds @@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	endif

	if (_ENABLE_WAV_SOUND == 1)
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Game Loop - Sampled Sounds @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
main_game_loop_sampled

;@@@@@@@@@@@@@@@@@@@@
	ldx #2
	ldy #3
vertsync_samp
	stx WSYNC
	stx VSYNC
	lda #AMPLITUDE
	sta AUDV0
	dey
	bne vertsync_samp
	sty WSYNC
	sty VSYNC
	lda #AMPLITUDE
	sta AUDV0
	
	ldx tv_type
	lda vblank_table,x
	sta TIM64T
;@@@@@@@@@@@@@@@@@@@@

	jsr vblank_ARM

;@@@@@@@@@@@@@@@@@@@@
wait_vblank_end_samp
	lda #AMPLITUDE
	sta AUDV0
	lda INTIM
	bne wait_vblank_end_samp
	sta VBLANK
;@@@@@@@@@@@@@@@@@@@@

	ldx kernel
	jsr call_bank_routine

;@@@@@@@@@@@@@@@@@@@@
	ldx #2
	stx WSYNC
	stx VBLANK
	lda #AMPLITUDE
	sta AUDV0
	ldx tv_type
	lda overscan_table,x
	sta TIM64T
;@@@@@@@@@@@@@@@@@@@@

	jsr overscan_ARM

	lda audc1
	sta AUDC1
	lda audf1
	sta AUDF1
	lda audv1
	sta AUDV1

;@@@@@@@@@@@@@@@@@@@@
wait_overscan_samp
	lda #AMPLITUDE
	sta AUDV0
	lda INTIM	
	bne wait_overscan_samp
;@@@@@@@@@@@@@@@@@@@@

	jmp main_game_loop
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ Game Loop - Sampled Sounds @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@ Tables for Frame Dispatch @@@@@@@@@@@@

sound_mode_table					;for auto-adjust to SETMODE mirror
	.byte #$00
	.byte #$f0
	.byte #$00

call_fn_table						;for auto-adjust to call_fn mirror
	.byte #$ff
	.byte #$fe
	.byte #$fe

;@@@@@@@@@@@@ Tables for Frame Dispatch @@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	endif


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@ Tables for VBlank Areas @@@@@@@@@@@@@

vblank_table
	.byte VBLANK_TIMER_60
	.byte VBLANK_TIMER_50
overscan_table
	.byte OVERSCAN_TIMER_60
	.byte OVERSCAN_TIMER_50

;@@@@@@@@@@@@@ Tables for VBlank Areas @@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@ Handle VBlank ARM Call @@@@@@@@@@@@@@@@@@@@@@@@@@@
vblank_ARM


	ldx #<_C_routine
	stx DSPTR
	stx DSPTR
	ldx #_ARM_VBLANK				;let ARM know we are in VBlank
	stx DSWRITE

	ldx call_fn
	stx CALLFN

	lda kernel
	clc
	adc KERNEL_PREP
	tax
	jmp call_bank_routine			;after ARM VBlank dispatch kernel's prep routine

;@@@@@@@@@@@@@@@@@@@@@@@@@@@ Handle VBlank ARM Call @@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@ Handle Overscan ARM Call @@@@@@@@@@@@@@@@@@@@@@@@@@
overscan_ARM

	ldx #<_C_routine
	stx COLUBK						;clear color registers while X = 0
	stx COLUP0
	stx COLUP1
	stx COLUPF
	stx DSPTR
	stx DSPTR
	ldx #_ARM_OVERSCAN				;let ARM know we are Overscan
	stx DSWRITE
	ldx SWCHA
	stx DSWRITE
	ldx SWCHB
	stx DSWRITE
	ldx INPT4
	stx DSWRITE
	ldx INPT5
	stx DSWRITE						;all Atari inputs to ARM
	ldx INPT1
	stx DSWRITE
	ldx INPT3
	stx DSWRITE

	if (_ENABLE_SAVEKEY == 1)
	ldx sk_detect					;<SaveKey>
	stx DSWRITE						;<SaveKey>
	endif

	ldx call_fn
	stx CALLFN

	lda #DS31DATA
	sta kernel						;kernel and sound_mode get refreshed
	lda #DS31DATA					;from the ARM each frame
	sta sound_mode
	lda #DS31DATA
	sta audv0
	lda #DS31DATA
	sta audc0
	lda #DS31DATA
	sta audf0
	lda #DS31DATA
	sta audv1
	lda #DS31DATA
	sta audc1
	lda #DS31DATA
	sta audf1


	if (_ENABLE_SAVEKEY == 1)
	lda sk_command					;<SaveKey> block of code
	bmi write_to_save_key			;<SaveKey> preforms SaveKey operations one byte at a time each frame
	bne read_from_save_key			;<SaveKey> to maintain the screen, sound will be slightly distorted

	lda #DS31DATA					;test for new save key operation
	beq skip_save_key_operation
	sta sk_command
	tay
	lda #DS31DATA
	beq acknowledge_save_command	;bail on count = 0
	cmp #65
	bcs acknowledge_save_command	;bail on count > 64
	sta sk_count
	lda #DS31DATA
	sta sk_addr_l
	lda #DS31DATA
	sta sk_addr_h
	lda #DS31DATA
	and #63							;wrap offset into 0-63 sk_RAM buffer range
	sta sk_offset
	clc
	adc sk_count
	cmp #65
	bcs acknowledge_save_command	;bail on access outside sk_RAM
	tya
	bpl read_from_save_key

	ldx #0
loop_DD_to_sk_RAM					;load sk_RAM buffer with data from ARM
	lda #DS31DATA
	sta sk_RAM,x
	inx
	cpx #64
	bne loop_DD_to_sk_RAM
	beq skip_save_key_operation

read_from_save_key
	jsr read_save_key
	ldx #>_save_data
	stx DSPTR
	lda #<_save_data				;reads can update DD ARM after each byte
	clc
	adc sk_offset
	sta DSPTR
	ldx sk_offset
	lda sk_RAM,x
	sta DSWRITE
	jmp done_savekey_operation

write_to_save_key
	jsr write_save_key

done_savekey_operation
	inc sk_offset
	inc sk_addr_l
	dec sk_count
	bne skip_save_key_operation
acknowledge_save_command
	ldx #0
	stx sk_command
	ldx #>_save_command				;X = 0 here, using this for DSWRITE
	stx DSPTR						;<SaveKey>
	ldy #<_save_command				;<SaveKey>
	sty DSPTR						;<SaveKey>
	stx DSWRITE						;<SaveKey> block of code
	endif


skip_save_key_operation
	rts
;@@@@@@@@@@@@@@@@@@@@@@@@@@ Handle Overscan ARM Call @@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@ Cross Bank Routine Handler @@@@@@@@@@@@@@@@@@@@@@@@@
call_bank_routine
	lda jump_table_target_bank,x				;RAM in the jump code area gets modified
	sta jump_code_RAM_t_bank					;with target bank
call_bank_routine_sans_bank
	lda jump_table_target_routine_l,x
	sta jump_code_RAM_t_r_l						;and low and
	lda jump_table_target_routine_h,x
	sta jump_code_RAM_t_r_h						;high byte of target routine
	jmp jump_code_RAM							;will return to THIS routine's caller
;@@@@@@@@@@@@@@@@@@@@

jump_table_target_bank			;routines can be located anywhere on any bank
;@@@@@ first banks for kernels (we want to be able to call these ASAP without math to kernel variable)
	.byte <BANK1
	.byte <BANK1
;@@@@@ then kernel prep routine bank
	.byte <BANK0
	.byte <BANK1

jump_table_target_routine_l		;each routine gets an entry in the table set
	.byte <kernel_00
	.byte <kernel_01
;@@@@@ then kernel prep routine address
	.byte <k_prep_00
	.byte <k_prep_01

jump_table_target_routine_h
	.byte >kernel_00
	.byte >kernel_01
KERNEL_PREP = * - jump_table_target_routine_h
	.byte >k_prep_00
	.byte >k_prep_01
ROUTINE_B0_R0 = * - jump_table_target_routine_h	;use this method to create names for manual routine calling




;@@@@@@@@@@@@@@@@@@@@@@@@@ Cross Bank Routine Handler @@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


	if (_ENABLE_SAVEKEY == 1)
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@ Write Save Key Routine @@@@@@@@@@@@@@@@@@@@@@
;@ 1 byte 1310 cycles (17+ scanlines) including call
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
write_save_key
	jsr setup_save_key
	bcc noSKfound
	ldx #1
	stx sk_detect
	ldx sk_offset
	lda sk_RAM,x
	jsr i2c_txbyte
	jsr i2c_stopwrite
	rts
noSKfound
	ldx #0
	stx sk_detect
done_save_key
	rts
;@@@@@@@@@@@@@@@@@@@@ Write Save Key Routine @@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@ Read Save Key Routine @@@@@@@@@@@@@@@@@@@@@
;@ 1 byte 1736 cycles (23 scanlines) including call
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
read_save_key
	jsr setup_save_key
	bcc noSKfound
	ldx #1
	stx sk_detect
	jsr i2c_stopwrite
	jsr i2c_startread
	ldx sk_offset
	jsr i2c_rxbyte
	sta sk_RAM,x
	jsr i2c_stopread
	rts
;@@@@@@@@@@@@@@@@@@@@@@ Read Save Key Routine @@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@ .SetupSaveKey Routine @@@@@@@@@@@@@@@@@@@@@@
setup_save_key
	jsr i2c_startwrite
	bne exitSK
	clv
	lda sk_addr_h
	jsr i2c_txbyte
	lda sk_addr_l
	jmp i2c_txbyte
exitSK
 	clc
 	rts
;@@@@@@@@@@@@@@@@@@@@@ .SetupSaveKey Routine @@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@ .i2c Routines @@@@@@@@@@@@@@@@@@@@@@@@@@@
i2c_startread
	ldy #%10100001
	.byte $2c
i2c_startwrite
	ldy #%10100000
	lda #24
	sta SWCHA
	lsr
	sta SWACNT
	tya
i2c_txbyte
	eor #$ff
	sec
	rol
i2c_txbyteloop
	tay
	lda #$0
	sta SWCHA
	adc #2
	asl
	asl
	sta SWACNT
	lda #8
	sta SWCHA
	tya
	asl
	bne i2c_txbyteloop
	beq i2c_rxbit
i2c_rxbyte
	bvc i2c_rxskipack
	jsr i2c_txack
i2c_rxskipack
	bit i2c_rxbyte
	lda #1
i2c_rxbyteloop
	tay
i2c_rxbit
	lda #16
	sta SWCHA
	lsr
	sta SWACNT
	nop
	sta SWCHA
	lda SWCHA 
	lsr
	lsr
	lsr
	tya
	rol
	bcc i2c_rxbyteloop
	rts

i2c_stopread
	bvc i2c_stopwrite
	ldy #$80
	jsr i2c_rxbit
i2c_stopwrite
	jsr i2c_txack
	lda #0
	sta SWACNT
	rts

i2c_txack
	lda #0
	sta SWCHA
	lda #12
	sta SWACNT
	asl
	sta SWCHA
	rts
;@@@@@@@@@@@@@@@@@@@@@@@@ .i2c Routines @@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
	endif


	if (_ENABLE_WAV_SOUND == 1)
	org CURRENT_BANK+$0700			;org usage within each bank remains straightforward - use CURRENT_BANK + desired offset
	rorg CURRENT_BANK+$0700			;samples need actual position within ROM, so rorg = org for those

_sample_steel
	INCBIN "/main/samples/sd2.bin"
_sample_steel_size = * - _sample_steel
	endif


	org CURRENT_BANK+$0e00
	rorg $f000+$0e00			;rorg also straightforward - use $f000 + desired offset

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 00 Prep @@@@@@@@@@@@@@@@@@@@@@@@@
k_prep_00
k_prep_xx	;[example] kernels can share prep code when setup is identical but display handling differs

	;each kernel also dispatches a "prep" routine to allow for object pre-positioning

	sta WSYNC
	dec $2d
	sta $2d
	lda #DS30DATA
	sta HMP0
	ldx #DS30DATA
loop_poition_p0_k0
	dex
	bpl loop_poition_p0_k0
	sta RESP0

	sta WSYNC
	dec $2d
	sta $2d
	lda #DS30DATA
	sta HMP1
	ldx #DS30DATA
loop_poition_p1_k0
	dex
	bpl loop_poition_p1_k0
	sta RESP1

	sta WSYNC
	sta HMOVE

	sta WSYNC
	sta HMCLR

	rts
;@@@@@@@@@@@@@@@@@@@@@@@@@ Kernel 00 Prep @@@@@@@@@@@@@@@@@@@@@@@@@
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



	org CURRENT_BANK+$0f00
	rorg $f000+$0f00






BANK0_CODE_SIZE = * - BANK_0;
	echo "---- BANK0", BANK0_CODE_SIZE, "bytes"
	echo "---- BANK0", ($fff0 - *), "bytes free"


;@@@@@@@@@@@@@@@ Bank 0 Footer - needed for CDFJ+ to function @@@@@@@@@@@@@@@
	; ROM Pointers
	org $17F0		;This section is only needed in BANK 0
	rorg $FFF0
	DC.B 0, 0, 0, 0		;CDFJ Hotspots
	DC.L C_STACK		;$F4	C Stack
	DC.L C_CODE+1		;$F8	C Code (+1 for THUMB Mode)
	DC.W start		;$FC	Reset
	DC.W start		;$FE	BRK

CURRENT_BANK set CURRENT_BANK + $1000
