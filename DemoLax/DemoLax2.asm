/*
 * DemoLax2.asm
 *
 *  Created: 2022-05-12 12:42:02
 *   Author: felix
 */ 

 .def	COUNTER = r18
 .org	$0000		
jmp		START            ; Reset Handler

.org	INT0addr
jmp		ISR0             ; INT0 Handler

.org	INT1addr
jmp		ISR1              ; INT1 Handler


.org	INT_VECTORS_SIZE

;---------------------------------------------------------------------
; Subrutines
;---------------------------------------------------------------------

START:
	ldi     r16,HIGH(RAMEND)
	out     SPH,r16
	ldi     r16,LOW(RAMEND)
	out     SPL,r16
	call	INIT


MAIN:
	call	ISR0
	call	ISR1
    rjmp	MAIN

;---------------------------------------------------------------------
; SUBROUTINES
;---------------------------------------------------------------------
INIT:
	ldi		r16,$FF
	out		DDRA,r16 //
	out		DDRB,r16 //

	ldi     r16,(1<<ISC01) |(0<<ISC00) |(1<<ISC11) |(0<<ISC10)
	out     MCUCR,r16; Activate
	ldi     r16,(1<<INT0) |(1<<INT1)
	out     GICR,r16; Enable Interrupts Globally

	clr		r16
	clr		COUNTER 
	sei
	ret
;---------------------------------------------------------------------
; INTERRUPTS
;---------------------------------------------------------------------

ISR0:

	inc		COUNTER
	cpi		COUNTER,$10
	brne	SKIP
	ldi		COUNTER,$00
SKIP:
	reti

;---------------------------------------------------------------------

ISR1:
	out		PORTA,COUNTER
	reti