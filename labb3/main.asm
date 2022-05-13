;
; labb3.asm
;
; Created: 5/1/2022 11:27:07 PM
; Author : Felix
;
.equ	TIME = $100
.def	COUNTER = r17

.org	$0000		
jmp		INIT            ; Reset Handler

.org	INT0addr
jmp		ISR0            ; INT0 Handler

.org	INT1addr
jmp		ISR1            ; INT1 Handler


.org	INT_VECTORS_SIZE
;---------------------------------------------------------------------
; Macros - never used
;---------------------------------------------------------------------
.macro ClockAdd
	ld		r16,X
	inc		r16
	st		X,r16
	cpi		r16,@0+1
	brne	DONE
	ldi		r16,0
	st		X+,r16
	;adiw	X,1

.endmacro

;---------------------------------------------------------------------
; Subrutines
;---------------------------------------------------------------------

INIT:
	ldi     r16,HIGH(RAMEND)
	out     SPH,r16
	ldi     r16,LOW(RAMEND)
	out     SPL,r16

	ldi		r16,3
	out		DDRA,r16 //Write seconds
	ldi		r16,127
	out		DDRB,r16 //Write minutes

	ldi     r16,(1<<ISC01) |(0<<ISC00) |(1<<ISC11) |(0<<ISC10)
	out     MCUCR,r16; Activate
	ldi     r16,(1<<INT0) |(1<<INT1)
	out     GICR,r16; Enable Interrupts Globally

	clr		r16
	clr		counter
	clr		r18
	sei

MAIN:
    rjmp	MAIN

;---------------------------------------------------------------------
; Interrputs
;---------------------------------------------------------------------
ISR0:
	push	r16
	ldi		r16,SREG
	push	r16
	push	XL
	push	XH
	push	ZL
	push	ZH
	push	r18
	
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)
	
	ldi		r18,0
LOOP:
	ld		r16,X
	inc		r16
	st		X,r16
	cpi		r16,$A
	brne	DONE
	ldi		r16,$0
	st		X+,r16
	ld		r16,X
	inc		r16
	st		X,r16
	cpi		r16,$6
	brne	DONE
	ldi		r16,$0
	st		X+,r16

	inc		r18
	cpi		r18,2
	brne	LOOP
	/*
	ClockAdd	$9
	ClockAdd	$5

	//Minutes
	ClockAdd	$9
	ClockAdd	$5
	*/
DONE:
	pop		r18
	pop		ZH
	pop		ZL
	pop		XH
	pop		XL
	pop		r16
	out		SREG,r16
	pop		r16		
	reti
;---------------------------------------------------------------------

ISR1:
	push	r16
	ldi		r16,SREG
	push	r16
	push	XL
	push	XH
	push	ZL
	push	ZH
	
	ldi		XH,HIGH(TIME)
	ldi		XL,LOW(TIME)

	add		XL,COUNTER		;If program big use add with carry :)

	ld		r16,X

	ldi		ZH,HIGH(BCD*2)
	ldi		ZL,LOW(BCD*2)

	add		ZL,r16
	lpm		r16,Z


	out		PORTA,COUNTER
	out		PORTB,r16

	inc		counter
	cpi		counter,4
	brne	SKIP
	clr		counter

SKIP:	

	pop		ZH
	pop		ZL
	pop		XH
	pop		XL
	pop		r16
	out		SREG,r16
	pop		r16	

	reti

;-----------------------------------
.org	$300
BCD:
	.db	$3F,$30,$5B,$4F,$66,$6D,$7D,$07,$FF,$67