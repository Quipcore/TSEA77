;
; labb2.asm
;
; Created: 2022-04-23 23:18:15
; Author : Felix Lidö
;

	;r16-r20 function variable
	;r21-r25 globals together with SRAM

		
		;---------------------------------------------------------------------

SETUP:
	ldi			r16,HIGH(RAMEND)
	out			SPH,r16
	ldi			r16,LOW(RAMEND)
	out			SPL,r16

	//cbi		DDRA,0 //DRRA isnt used
	ldi			r16,$FF
	out			DDRB,r16

	ldi			r16,0

	;Setting global variables
	ldi			r21, MESSAGE_END*2-MESSAGE*2-1 ; Length of message, take -1 if message length % 2 = 0
MORSE:

	mov			r20,r21	 ;r20 -> counter

	loop_morse:		
	ldi			ZH, HIGH(MESSAGE*2)
	ldi			ZL, LOW(MESSAGE*2)
	
	mov			r17,r21  ; indexing of message
	sub			r17,r20
	add			ZL,r17

	lpm			r16,Z

	cpi			r16,$20
	brne		CONTINUE

	call		NOBEEP_SEV
	jmp			MINMIN

	CONTINUE
	subi		r16,$41

	call		lookup ;Set r16 to corresponding output bin
	call		SEND

	call		NOBEEP
	call		NOBEEP

	MINMIN:
	dec			r20
	brne		loop_morse

	rjmp		MORSE

	;---------------------------------------------------------------------

LOOKUP: ;Search for start of message -> add index(r17) -> -$47 to go from letter to index of BTAB -> return value at index

	ldi		ZH, HIGH(BTAB*2)
	ldi		ZL, LOW(BTAB*2)

	//neg		r16
	add		ZL,r16
	ldi		r18,0
	adc		ZH,r18

	lpm		r16,Z
	ret

SEND:
	
	loop_SEND:
	lsl		r16
	

	brcc	BEEP_ONCE
	call	beep
	call	beep
	BEEP_ONCE:
	call	beep
	call	NOBEEP

	cpi		r16,$80
	brne	loop_SEND
	ret


BEEP: ; (N)
	ldi	r19,$1
	out	PORTB,r19
	call DElAY	
	ret

NOBEEP: ;(N)
	//DELAY
	ldi	r19,0
	out	PORTB,r19
	call DELAY
	ret

NOBEEP_SEV:
	call NOBEEP
	call NOBEEP
	call NOBEEP
	call NOBEEP

	call NOBEEP
	call NOBEEP
	call NOBEEP
	ret

DELAY:
	
	ret

	.org $100
BTAB: ; getDecodedIndexOf(char c) {return c.value - $41} ;Returns corresponding index in table
	.db $60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8
	//ret

	.org $125
MESSAGE:
	.db		"HELLO", $00 ; if message_length % 2 = 0, dont pad with zero

MESSAGE_END:
	.db		"END",$00