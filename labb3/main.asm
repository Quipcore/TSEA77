;
; labb3.asm
;
; Created: 5/1/2022 11:27:07 PM
; Author : Felix
;
.equ	TIME = $100

.org	$0000				; För tydlighet, behövs inte
jmp		INIT            ; Reset Handler

.org	INT0addr
jmp		INT0             ; INT0 Handler

.org	INT1addr
jmp		INT1              ; INT1 Handler


.org	INT_VECTORS_SIZE
;---------------------------------------------------------------------
; Macros
;---------------------------------------------------------------------
.macro ClockAdd
	ld		r16,X
	inc		r16
	st		X,r16
	cpi		r16,@0+1
	brne	DONE
	ldi		r16,0
	st		X,r16
	adiw	X,1

.endmacro

;---------------------------------------------------------------------
; Subrutines
;---------------------------------------------------------------------

INIT:
	ldi     r16,HIGH(RAMEND)
	out     SPH,r16
	ldi     r16,LOW(RAMEND)
	out     SPL,r16

	ldi		r16,$FF
	out		DDRA,r16 //Write seconds
	out		DDRB,r16 //Write minutes

	ldi     r16,(1<<ISC01) |(0<<ISC00) |(1<<ISC11) |(0<<ISC10)
	out     MCUCR,r16; Activate
	ldi     r16,(1<<INT0) |(1<<INT1)
	out     GICR,r16; Enable Interrupts Globally

	clr		r16
	clr		r17
	sei


MAIN:
	call	BCD
    rjmp	MAIN

;---------------------------------------------------------------------
BCD: ;Should be under INT0
	push	r16
	ldi		r16,SREG
	push	r16
	
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)

	//Seconds
	ClockAdd	$9
	ClockAdd	$5

	//Minutes
	ClockAdd	$9
	ClockAdd	$5

DONE:
	pop		r16
	out		SREG,r16
	pop		r16		
	ret

;---------------------------------------------------------------------

MUX:
	push	r16
	ldi		r16,SREG
	push	r16

	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)

	out		PORTA,r17

	ld		r16,X
	out		PORTB,r16
	adiw	X,1

	inc		r17
	cpi		r17,4
	brne	SKIP
	clr		r17

SKIP:
	pop		r16
	out		SREG,r16
	pop		r16	
	ret

;---------------------------------------------------------------------
; Interrputs
;---------------------------------------------------------------------
ISR0:
	reti

;---------------------------------------------------------------------

ISR1:
	reti