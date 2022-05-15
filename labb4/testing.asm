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
	call	JOYSTICK
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

MUX:
	//ldi		r16,$FF
	//out		PORTA,r16
	reti


JOYSTICK:

	//ldi		r16,(1<<REFS0) |(0<<ADLAR) ; kanal 0, AVCC ref, ADLAR=0
	call	ADC10
	out		PORTB,r16

	//ldi		r16,(0<<REFS0) |(0<<ADLAR) ; kanal 0, AVCC ref, ADLAR=0
	call	ADC10
	out		PORTD,r16
	
JOY_LIM:
	ret


ADC10:
	ldi		r16,(1<<REFS0) |(0<<ADLAR) ; kanal 0, AVCC ref, ADLAR=0
	out		ADMUX,r16
	ldi		r16,(1<<ADEN) ; A/D enable, ADPSx=111
	ori		r16,(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	out		ADCSRA,r16
ADC10_CONVERT:
	in		r16,ADCSRA
	ori		r16,(1<<ADSC)
	out		ADCSRA,r16 ; starta omvandling
ADC10_WAIT:
	in		r16,ADCSRA
	sbrc	r16,ADSC ; om 0-st�lld, klar
	rjmp	ADC10_WAIT ; annars v�nta
	in		r16,ADCL ; obs, l�s l�g byte f�rst
	in		r17,ADCH ; h�g byte sedan
	ret