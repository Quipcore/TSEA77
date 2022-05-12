;
; demo1.asm
;
; Created: 2022-05-02 13:24:39
; Author : Felix Lidö
;

			.org $0000
	jmp		init

			.org INT0addr
	jmp		intZero	

			.org INT_VECTORS_SIZE
;----------------------------------------------------------------------------------------
;init - initiate program
;----------------------------------------------------------------------------------------
init:
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16
	
	;------------------------------------------------------------------------------------
	; Enable trigger of interrupts
	ldi     r16,(1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10)
	out     MCUCR,r16
	; Activate
	ldi     r16,(1<<INT0) | (1<<INT1)
	out     GICR,r16
	; Enable Interrupts Globally
	sei
	;------------------------------------------------------------------------------------

	ldi		r16,$FF
	out		DDRB,r16			;B port -> output

	ldi		r16,$0
	out		DDRA,r16			;A pin -> input
	out		PORTB,r16			;Setting start num = 0;

;----------------------------------------------------------------------------------------
;main - start here
;----------------------------------------------------------------------------------------
main:
	jmp main

;----------------------------------------------------------------------------------------
;interrupt #0 - should only trigger on falling edge, triggers on risning edge of strobe
;----------------------------------------------------------------------------------------
intZero:
	in		r16,PINA
	andi	r16,$0F ;Mask
	cpi		r16,$0A
	brmi	PRINT
	subi	r16,$0A
	ori		r16,$10

PRINT:
	out		PORTB,r16
	reti