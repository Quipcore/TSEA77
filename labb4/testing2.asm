/*
 * testing2.asm
 *
 *  Created: 2022-05-15 15:19:51
 *   Author: Felix
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

	.cseg
	.org 	$0
	jmp		START
	.org	INT0addr
	jmp		MUX

START:
	ldi     r16,HIGH(RAMEND)
	out     SPH,r16
	ldi     r16,LOW(RAMEND)
	out     SPL,r16	
	
	call	HW_INIT	
 main:
	call TEST_METHOD
	jmp main

TEST_METHOD:
	lds		r16,SEED
	subi	r16,-1
	sts		SEED,r16
	ret

MUX:
	in		r16,SPH
	mov		ZH,r16
	in		r16,SPL
	mov		ZL,r16
	lds		r16,SEED

	mov		r17,r16

	andi	r16,0b00000111
	cpi		r16,4
	brmi	CON1_RANDOM
	subi	r16,4

CON1_RANDOM:
	
	andi	r17,0b00111000
	lsr		r17
	lsr		r17
	lsr		r17
	cpi		r17,4
	brmi	CON2_RANDOM
	subi	r17,4

CON2_RANDOM:
	out		PORTB,r17 ; y
	out		PORTA,r16 ; x
	reti


RANDOM:
	
	ret

HW_INIT:
	ldi     r16,(1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10)
	out     MCUCR,r16; Activate
	ldi     r16,(1<<INT0) | (0<<INT1)
	out     GICR,r16; Enable Interrupts Globally

	ldi		r16,$FF
	out		DDRA,r16
	out		DDRB,r16
	
	sei
	ret