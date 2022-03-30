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
	;ÖV1
	ldi		r16,1
	sts		$110,r16

	ldi		r16,1
	sts		$111,r16

	clr		r16

	;-----------------------------------------------------------
	; Öv2
	ldi		r16,198
	ldi		r17,$64 ;0x64 = 0d100, '$' can be replaced with the '0x' prefix
	ldi		r18,0b10010011 ;0b10010011 = 0x93 = 0d147; 0b<binary>, use the 0b prefix to indicate binary number
	mov		r16,r18
	
	clr		r16
	clr		r17
	clr		r18
	;-----------------------------------------------------------
	; Öv3
	lds		r16,$110
	sts		$112,r16

	clr		r16
	;-----------------------------------------------------------
	; Öv4
	lds		r16,$110
	lds		r17,$111

	add		r16,r17

	sts		$112,r16

	clr		r16
	clr		r17

	;-----------------------------------------------------------
	; Öv5

	lds		r16,$110
	lsl		r16
	sts		$111,r16


	nop