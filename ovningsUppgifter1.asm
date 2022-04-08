/*
 * ovningsUppgifter1.asm
 *
 *  Created: 2022-03-30 14:20:31
 */ 
	;-----------------------------------------------------------
	;Used to load number into SRAM and then clear the used registers
	;Numbers cant bigger than (se below) without risking cutoff
	;						FF
	;						1111 1111
	;						255
	;�V1
	ldi		r16,1
	sts		$110,r16

	ldi		r16,1
	sts		$111,r16

	clr		r16

	;-----------------------------------------------------------
	; �v2
	ldi		r16,198
	ldi		r17,$64 ;0x64 = 0d100, '$' can be replaced with the '0x' prefix
	ldi		r18,0b10010011 ;0b10010011 = 0x93 = 0d147; 0b<binary>, use the 0b prefix to indicate binary number
	mov		r16,r18
	
	clr		r16
	clr		r17
	clr		r18
	;-----------------------------------------------------------
	; �v3
	lds		r16,$110
	sts		$112,r16

	clr		r16
	;-----------------------------------------------------------
	; �v4
	lds		r16,$110
	lds		r17,$111

	add		r16,r17

	sts		$112,r16

	clr		r16
	clr		r17

	;-----------------------------------------------------------
	; �v5

	lds		r16,$110
	lsl		r16
	sts		$111,r16

	clr		r16
	;-----------------------------------------------------------
	; �v6

	ldi		r16,$FF
	andi	r16,$F0
	
	;-----------------------------------------------------------
	; �v7

	ldi		r16,$0F
	ori		r16,0b11100000
			
	;-----------------------------------------------------------
	; �v8
	ldi		r16,$AF
	sts		$110,r16

	lds		r16,$110
	
	mov		r17,r16
	andi	r17,0b11110000
	swap	r17
	sts		$111,r17
	
	mov		r18,r16
	andi	r18,0b00001111
	sts		$112,r18
	

	;-----------------------------------------------------------
	; �v9

	lds		r16,$110
	lds		r17,$111

	cp		r16,r17

	brpl	R16BIG
	mov		r16,r17

R16BIG:
	sts		$112,r16


	;-----------------------------------------------------------
	; �v10
	ldi		r16,10
	sts		$110,r16
	lds		r16,$110

	ldi		r17,10
	mul		r16,r17 //Sparar resultatet i r0

	sts		$112,r0

	;-----------------------------------------------------------
	; �v11

	subi	r16,-7
	
	;-----------------------------------------------------------
	; �v12
	
	adiw	r30,3

	;-----------------------------------------------------------
	; �v13

	subi	r16,-3
	brcs	DONE
	inc		r17

DONE:

	
	;-----------------------------------------------------------
	; �v14



	nop