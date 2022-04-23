;
; labb2.asm
;
; Created: 2022-04-23 23:18:15
; Author : Felix Lidö
;


BTAB: ; getDecodedIndexOf(char c) {return c.value - $41} ;Returns corresponding index in table
	.db $60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8
	//ret

MESSAGE:
	.db		"HELLO", $00
	//ret
		
		;---------------------------------------------------------------------

SETUP:
	ldi		r16,HIGH(RAMEND)
	out		SPH,r16
	ldi		r16,LOW(RAMEND)
	out		SPL,r16

	cbi		DDRA,0 //DRRA isnt used
	ldi		r16,$FF
	out		DDRB,r16

	ldi		r16,0

RESET:
	ldi		r17,0
	ldi		r20,MESSAGE
MORSE:
	

	inc r17
	dec r20
	breq	RESET

	rjmp	MORSE

	;---------------------------------------------------------------------

GET_CHAR:
	ret
	
ONE_CHAR:
	ret

BEEP_CHAR:
	ret

LOOKUP: ;Search for start of message -> add index(r17) -> -$47 to go from letter to index of BTAB -> return value at index
	ldi		ZH, HIGH(MESSAGE*2)
	ldi		ZL, LOW(MESSAGE*2)

	mov		r18,r17
	
	LOOP:
	adiw	Z, 1
	dec		r18
	brne	LOOP		


	lpm		r16,Z
	subi	r16,$41

	ldi		ZH, HIGH(BTAB*2)
	ldi		ZL, LOW(BTAB*2)

	movw	ZH:ZL, r16
	lpm		r16,Z
	ret

SEND:
	ret

GET_BIT:
	ret

SEND_BIT:
	ret

BIT:
	ret

BEEP: ; (N)
	ret

NOBEEP: ;(N)
	ret


