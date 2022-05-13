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

	.cseg

START:
	ldi     r16,HIGH(RAMEND)
	out     SPH,r16
	ldi     r16,LOW(RAMEND)
	out     SPL,r16		
 main:
	call incSeed
	jmp main

incSeed:
	ldi		XH,HIGH(SEED)
	ldi		XL,LOW(SEED)
	ld		r16,X
	subi	r16,-1
	st		X,r16
	ret