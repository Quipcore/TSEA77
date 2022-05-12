 ;
; labb2.asm
;
; Created: 2022-04-23 23:18:15
; Author : Felix Lidö
;

SETUP:
	.equ		FREQ = 300

	ldi			r16,HIGH(RAMEND)
	out			SPH,r16
	ldi			r16,LOW(RAMEND)
	out			SPL,r16

	ldi			r16,$FF
	out			DDRB,r16

	ldi			r16,0

	ldi			r21, MESSAGE_END*2-MESSAGE*2-1 ; Length of message, take -1 if message length % 2 = 0
												; NOT multiplying by 2 might fix problem
		;---------------------------------------------------------------------

MORSE: ; return void
	;	r16 - return value
	;	r17 - index
	;	r20 - loopcounter
	;	r21 - length of message

	mov			r20,r21	

LOOP_MORSE:		
	ldi			ZH, HIGH(MESSAGE*2)
	ldi			ZL, LOW(MESSAGE*2)
	
	mov			r17,r21
	sub			r17,r20
	add			ZL,r17

	lpm			r16,Z

	cpi			r16,$20
	breq		SPACE

	subi		r16,$41

	call		LOOKUP
	call		SEND

	call		NOBEEP
	call		NOBEEP


MINMIN:
	dec			r20
	brne		LOOP_MORSE

	call		NOBEEP_FIVE
	call		NOBEEP
	call		NOBEEP
	call		NOBEEP_FIVE

	rjmp		MORSE

SPACE:
	call		NOBEEP_FIVE
	call		NOBEEP
	call		NOBEEP
	jmp			MINMIN

	;---------------------------------------------------------------------

LOOKUP: ; return r16
	;Search for start of message -> add index(r17) -> -$47 to go from letter to index of BTAB -> return value at index
	;	r16 - input and return value
	;	r18 - temp storage

	ldi			ZH, HIGH(BTAB*2)
	ldi			ZL, LOW(BTAB*2)

	add			ZL,r16
	ldi			r18,0
	adc			ZH,r18

	lpm			r16,Z
	ret

	;---------------------------------------------------------------------

SEND: ; return void
	;	r16 - input value
	
LOOP_SEND:
	lsl			r16

	brcc		BEEP_ONCE
	call		beep
	call		beep
BEEP_ONCE:
	call		beep
	call		NOBEEP

	cpi			r16,$80
	brne		LOOP_SEND
	ret

	;---------------------------------------------------------------------

BEEP: ;return void
	;	r19  - temp storage 
	ldi			r19,$1
	out			PORTB,r19
	ldi			r19,$20
	call		BEEP_LOOP	
	ret
	
	BEEP_LOOP:
		sbi PORTB, $0
		call WAIT
		cbi PORTB, $0
		call WAIT
		dec r19
		brne BEEP_LOOP
		ret

WAIT:
	ldi r25, HIGH(FREQ)
	ldi r24, LOW(FREQ)
	WAIT_LOOP:
		sbiw r24, 1
		brne WAIT_LOOP
		ret
	;---------------------------------------------------------------------

NOBEEP: ;return void
	;	r19  - temp storage
	ldi			r19,$0 ; 0d10, need the first and only 1 for debug purposes
	out			PORTB,r19
	call		DELAY
	ret

	;---------------------------------------------------------------------

NOBEEP_FIVE: ; return void
	call		NOBEEP
	call		NOBEEP
	call		NOBEEP
	call		NOBEEP
	call		NOBEEP

	ret

	;---------------------------------------------------------------------

	.equ		SIGNAL_TIME = 10 ; Time in ms (0 < SIGNAL_TIME <= 16)
	;DELAY So that the sound played stays alive for SIGNAL_TIME miliseconds
DELAY: ; return void
	;	r24 - LOW in r24:r25 16-bit pair
	;	r25 - HIGH in r24:r25 16-bit pair
	ldi			r24,$FF
	ldi			r25,$FF
	subi		r24,LOW(SIGNAL_TIME*4000)-1 ; see notes for more info
	subi		r25,HIGH(SIGNAL_TIME*4000)

	LOOP_DELAY:
	adiw		r24,1
	brne		LOOP_DELAY
	ret
	

	;---------------------------------------------------------------------
	;	FLASH-MEMORY DATA, DO NOT RUN in cseg

	.org $100 ; Sets MESSAGE and MESSAGE_END at adress $125
BTAB: ; getDecodedIndexOf(char c) {return c.value - $41} ;Returns corresponding index in table
	.db $60,$88,$A8,$90,$40,$28,$D0,$08,$20,$78,$B0,$48,$E0,$A0,$F0,$68,$D8,$50,$10,$C0,$30,$18,$70,$98,$B8,$C8
	//ret

BTAB_END:
	.db		"END",$00

	.org $125 ; Sets MESSAGE and MESSAGE_END at adress $125
MESSAGE:
	.db		"SOS SOS", $00 ; if message_length % 2 = 0, dont pad with zero

MESSAGE_END:
	.db		"END",$00
