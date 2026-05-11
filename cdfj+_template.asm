;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ CDFJ+ Template - Driver Ver 48
;@ ARM/6502 Hybrid Framework for Atari 2600
;@
;@ Craig Daniels - Gamax Software - 2026
;@ 
;@ Many thanks to John (johnnywc) for seeding this project
;@ to JetSetIlly for helping iron out digital samples
;@ and Andrew Davie for a bunch of cross-platform assistance
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	PROCESSOR 6502

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ CDFJ+ System and Framework Constants and Includes
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ ROM CONFIGURATION (READ THIS OR IT WILL BREAK)
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ ROM_SIZE and DISPLAY_SIZE MUST BE CORRECT OR BUILD WILL FAIL
;@
;@  ROM_SIZE   DISPLAY_SIZE (MINIMUM REQUIRED - May be increased for allocation of additional DD features, reducing available C RAM)
;@  --------   ------------
;@		32		4352		;256B sys + 256B wav + 16 * 192B DS Channels + 2 * 384B Jump Channels = 4352
;@		64		6400		;256B sys + 256B wav + 2048B Digital Sample buffer + 16 * 192B DS Channels + 2 * 384B Jump Channels = 6400
;@		128		6400		;256B sys + 256B wav + 2048B Digital Sample buffer + 16 * 192B DS Channels + 2 * 384B Jump Channels = 6400
;@		256		9472		;256B sys + 256B wav + 2048B Digital Sample buffer + 32 * 192B DS Channels + 2 * 384B Jump Channels = 9472
;@		512		9472		;256B sys + 256B wav + 2048B Digital Sample buffer + 32 * 192B DS Channels + 2 * 384B Jump Channels = 9472
;@
;@@@@@@@@
ROM_SIZE			= 128			
DISPLAY_SIZE		= 6400
;@@@@@@@@
;@
;@ If you change ROM_SIZE, you MUST update DISPLAY_SIZE accordingly.
;@ Framework auto-allocates additional Display Data features as
;@ available RAM increases with larger ROMs
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

FF_LDX					= 1				;Fast Fetch for LDX: 0 = off, NZ = on
FF_LDY					= 1				;Fast Fetch for LDY: 0 = off, NZ = on
FF_OFFSET				= 200			;Fast Fetch offset: 0 to 200
C_START					= $7800			;$1800, $2800, $3800, $4800, $5800, $6800, $7800
								; With current examples, C_START=$1800 will error because Bank1 contains 6507 routines.
								; Move/remove those routines to Bank0 before starting ARM C at $1800.

	INCLUDE "cdfjplus.h"		;cdfjplus.h must come AFTER system constants for FF_OFFSET to apply
	INCLUDE "vcs.h"
;	INCLUDE "macro.h"			;I personally do not use - but uncomment and use as you desire
								; <WARNING> fast fetch macros may not work properly
	INCLUDE "tia_constants.h"

_DD_BASE				= $40000800		;DisplayData base exported into defines file and used in CDFJ routines
_WAV_BASE				= _DD_BASE + _waveforms
_RAM_BASE				= _DD_BASE + DISPLAY_SIZE
_DISPLAY_SIZE32			= DISPLAY_SIZE / 4

	;C Stack Pointer - leave space for IAR at top of memory
	if (ROM_SIZE == 32)
C_STACK = $40001FDC
DS_SIZE = 0						;auto-generate DS_SIZE and CH_SIZE
CH_SIZE = 0						;for later use in DD RAM allocation
	endif
	if (ROM_SIZE == 64 || ROM_SIZE == 128)
C_STACK = $40003FDC				;when ROM_SIZE = 64 or 128 RAM increases to 16k
DS_SIZE = 2048					;allowing room for framework to enable the RAM digital sameple buffer
CH_SIZE = 0						;but not yet the additional 16 Data Stream channels
	endif
	if (ROM_SIZE == 256 || ROM_SIZE == 512)
C_STACK = $40007FDC				;when ROM_SIZE = 256 or 512 RAM increases to 32k
DS_SIZE = 2048					;allowing room for framework to enable both the RAM digital sameple buffer
CH_SIZE = 192					;and the additional 16 Data Stream channels
	endif

_SND_MODE_TIA			= 0
_SND_MODE_DPC			= 1
_SND_MODE_SAMPLE		= 2

_ARM_INIT				= 0
_ARM_VBLANK				= 1
_ARM_OVERSCAN			= 2

_SAVE_KEY_NONE			= 0
_SAVE_KEY_READ			= 1
_SAVE_KEY_WRITE			= 128

_TV_TYPE_60HZ			= 0
_TV_TYPE_50HZ			= 1
_DETECT_FRAME_COUNT		= 1			;can adjust this to however many initial test frames desired

VBLANK_TIMER_60			= 43
OVERSCAN_TIMER_60		= 35

VBLANK_TIMER_50			= 62
OVERSCAN_TIMER_50		= 75

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ User Constants
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@



;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ 2600 RIOT RAM - A mere 128 bytes
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	SEG.U VARS
	org $80

tv_type						ds 1		;<FRAMEWORK>

kernel						ds 1		;<FRAMEWORK>
sound_mode					ds 1		;<FRAMEWORK>
sound_save					ds 1		;<FRAMEWORK>
call_fn						ds 1		;<FRAMEWORK>

audv0						ds 1		;<FRAMEWORK>
audc0						ds 1		;<FRAMEWORK>
audf0						ds 1		;<FRAMEWORK>
audv1						ds 1		;<FRAMEWORK>
audc1						ds 1		;<FRAMEWORK>
audf1						ds 1		;<FRAMEWORK>

sk_command					ds 1		;<SaveKey>	holds current command from ARM
sk_detect					ds 1		;<SaveKey>	0- SaveKey not found; 1- SaveKey detected
sk_addr_l					ds 1		;<SaveKey>	
sk_addr_h					ds 1		;<SaveKey>
sk_count					ds 1		;<SaveKey>	bytes to copy 1-64
sk_offset					ds 1		;<SaveKey>	start offset into sk_RAM 0-63
sk_RAM						ds 64		;<SaveKey>

jump_code_RAM				ds 1		;dedicated area of RAM for bank routine jumping/calling	<FRAMEWORK>
jump_code_RAM_t_bank		ds 3		;cmp SelectBankX										<FRAMEWORK>
jump_code_RAM_t_r_l			ds 1		;jsr .called_bank_routine								<FRAMEWORK>
jump_code_RAM_t_r_h			ds 2		;cmp SelectBank0										<FRAMEWORK>
jump_code_RAM_r_bank		ds 3		;rts													<FRAMEWORK>

test_position				ds 1		;only for demonstration of positioning method purposes

	;Display Remaining RAM
	echo "---- 2600 RAM", ($100 - *)d, "bytes free" 


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ DisplayData RAM - Begins at $0000 and extends by DISPLAY_SIZE bytes
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	SEG.U DISPLAYDATA
	org $0000				;@@@@@ 256 Bytes: 6502 <-> ARM @@@@@
_C_routine					ds 1			; <FRAMEWORK>  MUST remain at location $0000
_SWCHA						ds 1			; <FRAMEWORK>
_SWCHB						ds 1			; <FRAMEWORK>
_INPT4						ds 1			; <FRAMEWORK>
_INPT5						ds 1			; <FRAMEWORK>
_SK_DETECT					ds 1			; <SaveKey>

	align 2

_kernel						ds 1			; <FRAMEWORK>
_sound_mode					ds 1			; <FRAMEWORK>
_AUDV0						ds 1			; <FRAMEWORK>
_AUDC0						ds 1			; <FRAMEWORK>
_AUDF0						ds 1			; <FRAMEWORK>
_AUDV1						ds 1			; <FRAMEWORK>
_AUDC1						ds 1			; <FRAMEWORK>
_AUDF1						ds 1			; <FRAMEWORK>

_save_command				ds 1			; <SaveKey>
_save_count					ds 1			; <SaveKey>
_save_addr_l				ds 1			; <SaveKey>
_save_addr_h				ds 1			; <SaveKey>
_save_offset				ds 1			; <SaveKey>
_save_data					ds 64			; <SaveKey>


	align 4

_test_data					ds 1 ;;;;;TEMP

			;173 bytes free for user data here
			;things such as player positions,
			;state, flags, etc.

	org $0100
_waveforms					ds 256			;@@@@@ 256 Bytes: 8 Custom Waveforms (0-7) @@@@@

_digital_sample				ds DS_SIZE		;@@@@@ 2048 Bytes: Digital Sound Sample (ROM_SIZE >= 64) @@@@@
						;@@@@@ playback access via waveform ID 8 @@@@@

_buffer0					ds 192			;@@@@@ 16x 192 Byte DS Channels @@@@@
_buffer1					ds 192
_buffer2					ds 192
_buffer3					ds 192
_buffer4					ds 192
_buffer5					ds 192
_buffer6					ds 192
_buffer7					ds 192
_buffer8					ds 192
_buffer9					ds 192
_buffer10					ds 192
_buffer11					ds 192
_buffer12					ds 192
_buffer13					ds 192
_buffer14					ds 192
_buffer15					ds 192

_buffer16					ds CH_SIZE		;@@@@@ 16x additional 192 Byte DS Channels (ROM_SIZE >= 256) @@@@@
_buffer17					ds CH_SIZE
_buffer18					ds CH_SIZE
_buffer19					ds CH_SIZE
_buffer20					ds CH_SIZE
_buffer21					ds CH_SIZE
_buffer22					ds CH_SIZE
_buffer23					ds CH_SIZE
_buffer24					ds CH_SIZE
_buffer25					ds CH_SIZE
_buffer26					ds CH_SIZE
_buffer27					ds CH_SIZE
_buffer28					ds CH_SIZE
_buffer29					ds CH_SIZE
_buffer30					ds CH_SIZE
_buffer31					ds CH_SIZE

_jump_table_1				ds 384
_jump_table_2				ds 384


	IF (* <= DISPLAY_SIZE)
	echo "------",(DISPLAY_SIZE - *)d , "bytes of Display Data RAM left"
	ELSE
	echo "FATAL ERROR - Display Data exceeds",(DISPLAY_SIZE)d ,"bytes"
	err
	ENDIF  


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Cartridge Layout	(with C_START = $7800)
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ $0000 - $07ff CDF Driver
;@ $0800 - $17ff Bank 0, 6507 code, cartridge always boots with this bank active
;@ $1800 - $27ff Bank 1, 6507 code
;@ $2800 - $37ff Bank 2, 6507 code
;@ $3800 - $47ff Bank 3, 6507 code
;@ $4800 - $57ff Bank 4, 6507 code
;@ $5800 - $67ff Bank 5, 6507 code
;@ $6800 - $77ff Bank 6, 6507 code
;@ $7800 - $87ff Bank 7, Starting location of ARM C-code and data
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Cartridge Layout	(with C_START = $1800)
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ $0000 - $07ff CDF Driver
;@ $0800 - $17ff Bank 0, 6507 code, cartridge always boots with this bank active
;@ $1800 - $27ff Bank 1, Starting location of ARM C-code and data
;@ $2800 - $37ff Bank 2, ARM C-code and data
;@ $3800 - $47ff Bank 3, ARM C-code and data
;@ $4800 - $57ff Bank 4, ARM C-code and data
;@ $5800 - $67ff Bank 5, ARM C-code and data
;@ $6800 - $77ff Bank 6, ARM C-code and data
;@ $7800 - $87ff Bank 7, ARM C-code and data
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@


        
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ CDF driver - The Harmony/Melody driver is located at Start of Cartridge ROM    
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	SEG CODE
	org $0000
    
CDFJPLUS_DRIVER:

	incbin "./cdfjplus48_p1.bin"

	if FF_LDX = 0
	.byte #$a9		;lda #imm
	else
	.byte #$a2		;ldx #imm
	endif

	incbin "./cdfjplus48_p2.bin"

	if FF_LDY = 0
	.byte #$a9		;lda #imm
	else
	.byte #$a0		;ldy #imm
	endif

	incbin "./cdfjplus48_p3.bin"

	.byte #FF_OFFSET

	incbin "./cdfjplus48_p4.bin"


CDFJPLUS_DRIVER_SIZE = [* - CDFJPLUS_DRIVER]d
	echo "---- CDFJPLUS DRIVER SIZE", CDFJPLUS_DRIVER_SIZE, "bytes"




;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 0 - Startup bank
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CURRENT_BANK set $0800
	ORG CURRENT_BANK

	.include "bank_0.asm"

	if C_START = $1800
	org $1800
	rorg $1800

	else

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 1
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CURRENT_BANK set $1800
	ORG CURRENT_BANK

	.include "bank_1.asm"

	if C_START = $2800
	org $2800
	rorg $2800

	else

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 2
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CURRENT_BANK set $2800
	ORG CURRENT_BANK

	.include "bank_2.asm"

	if C_START = $3800
	org $3800
	rorg $3800

	else

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 3
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CURRENT_BANK set $3800
	ORG CURRENT_BANK

	.include "bank_3.asm"

	if C_START = $4800
	org $4800
	rorg $4800

	else

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 4
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CURRENT_BANK set $4800
	ORG CURRENT_BANK

	.include "bank_4.asm"

	if C_START = $5800
	org $5800
	rorg $5800

	else

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 5
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CURRENT_BANK set $5800
	ORG CURRENT_BANK

	.include "bank_5.asm"

	if C_START = $6800
	org $6800
	rorg $6800

	else

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 6
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

CURRENT_BANK set $6800
	ORG CURRENT_BANK

	.include "bank_6.asm"


;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ Bank 7 - when C_START = $7800
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

	org $7800
	rorg $7800

	endif
	endif
	endif
	endif
	endif
	endif

;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
;@ C-Code
;@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

; The Makefile creates a temporary 1-byte testarm.bin during the bootstrap pass,
; then rebuilds this file with the real ARM binary before the final DASM pass.
C_CODE:
	INCBIN "main/bin/armcode.bin"






C_CODE_SIZE = * - C_CODE;
	echo "---- C CODE uses", (C_CODE_SIZE)d, "bytes"

 
	IF ROM_SIZE = 32
	echo "----",($8000 - *) , "C CODE bytes free"
	org $7fff
	ENDIF

	IF ROM_SIZE = 64
	echo "----",($10000 - *) , "C CODE bytes free"
	org $ffff
	ENDIF

	IF ROM_SIZE = 128
	echo "----",($20000 - *) , "C CODE bytes free"
	org $1ffff
	ENDIF

	IF ROM_SIZE = 256
	echo "----",($40000 - *) , "C CODE bytes free"
	org $3ffff
	ENDIF

	IF ROM_SIZE = 512
	echo "----",($80000 - *) , "C CODE bytes free"
	org $7ffff
	ENDIF

	.byte #$ff


    
