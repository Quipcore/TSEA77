/*
 * testing.asm
 *
 *  Created: 2022-05-13 09:58:46
 *   Author: felix
 */ 
 	.equ	VMEM_SZ     = 5		; #rows on display
	.equ	AD_CHAN_X   = 0		; ADC0=PA0, PORTA bit 0 X-led
	.equ	AD_CHAN_Y   = 1		; ADC1=PA1, PORTA bit 1 Y-led
	.equ	GAME_SPEED  = 70	; inter-run delay (millisecs)
	.equ	PRESCALE    = 7		; AD-prescaler value
	.equ	BEEP_PITCH  = 20	; Victory beep pitch
	.equ	BEEP_LENGTH = 100	; Victory beep length
	
	; ---------------------------------------
	; --- Memory layout in SRAM
	.dseg
	.org	SRAM_START
POSX:	.byte	1	; Own position
POSY:	.byte 	1
TPOSX:	.byte	1	; Target position
TPOSY:	.byte	1
LINE:	.byte	1	; Current line	
VMEM:	.byte	VMEM_SZ ; Video MEMory
SEED:	.byte	1	; Seed for Random
MUXPOS: .byte   1
	
	; ---------------------------------------
	; --- Macros for inc/dec-rementing
	; --- a byte in SRAM
	; ---------------------------------------
	.macro INCSRAM	; inc byte in SRAM
		lds	r16,@0
		inc	r16
		sts	@0,r16
	.endmacro

	.macro DECSRAM	; dec byte in SRAM
	lds	r16,@0
	dec	r16
	sts	@0,r16
	.endmacro

	.cseg
	.org 	$0
	jmp		START
	//.org	INT0addr
	//jmp		MUX

START:
	ldi     r16,HIGH(RAMEND)
	out     SPH,r16
	ldi     r16,LOW(RAMEND)
	out     SPL,r16	
	
 main:
 	push	r0
	push	r0

	call	RANDOM		; RANDOM returns x,y on stack
	
	pop		r16 ; x
	pop		r17 ; y

	mov		r19,r16
	mov		r20,r17

	jmp main
RANDOM: ; Last subroutine
	//push r16

	in		r16,SPH
	mov		ZH,r16
	in		r16,SPL
	mov		ZL,r16

	ldi		r16,$A0
	std		Z+3,r16

	ldi		r16,$FF
    std		Z+4, r16        ; store POSY to stack
	
	//pop		r16

	ret
