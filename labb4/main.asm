; --- lab4spel.asm

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
MUXPOS: .byte   1   ; The counter for muxing

	; ---------------------------------------
	; --- Macros for inc/dec-rementing
	; --- a byte in SRAM
	.macro INCSRAM	; inc byte in SRAM
		lds	r16,@0
		inc	r16
		sts	@0,r16
	.endmacro

	.macro DECSRAM	; dec byte in SRAM
		lds	r16,@0
		dec	r16
		sts	@0,r16
	.endmacro

	; ---------------------------------------
	; --- Code
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
	call	WARM
RUN:
	call	JOYSTICK
	call	ERASE_VMEM
	call	UPDATE

	call	DELAY
	
//*** 	Avgör om träff				 	***
	lds		r16,POSX
	lds		r17,TPOSX

	cp		r16,r17
	brne	NO_HIT

	lds		r16,POSY
	lds		r17,TPOSY

	cp		r16,r17
	brne	NO_HIT	
	ldi		r16,BEEP_LENGTH
	call	BEEP
	call	WARM
NO_HIT:
	jmp	RUN

	; ---------------------------------------
	; --- Multiplex display
MUX:	

//*** 	skriv rutin som handhar multiplexningen och ***
//*** 	utskriften till diodmatrisen. Öka SEED.		***

	lds		r16,MUXPOS
	cpi		r16,0
	brne    SHOW_TARGET

	ldi		r16,1
	sts		MUXPOS,r16

	lds		r16,POSX
	lds		r17,POSY

	rjmp	CONTINUE

SHOW_TARGET:

	ldi		r16,0
	sts		MUXPOS,r16

	lds		r16,TPOSX
	lds		r17,TPOSY


CONTINUE:
	out		PORTA,r16
	out		PORTB,r17

	lds		r16,SEED
	subi	r16,-1
	sts		SEED,r16
	reti
		
	; ---------------------------------------
	; --- JOYSTICK Sense stick and update POSX, POSY
	; --- Uses r16
JOYSTICK:	

//*** 	skriv kod som ökar eller minskar POSX beroende 	***
//*** 	på insignalen från A/D-omvandlaren i X-led...	***

//*** 	...och samma för Y-led 				***

	ldi		r16,(1<<REFS0)|(0<<ADLAR) ; kanal 0, AVCC ref
									  ; left adjust
	call	ADC8

	cpi		r16,0b11
	brne	SET_RIGHT
	lds		r16,POSX
	dec		r16
	sts		POSX,r16
	jmp		JOY_LIM

SET_RIGHT:
	cpi		r16,0b00
	brne	JOY_LIM
	lds		r16,POSX
	inc		r16
	sts		POSX,r16

	ldi		r16,(1<<REFS1)|(0<<ADLAR) ; kanal 0, AVCC ref
									  ; left adjust

	call ADC8

	cpi		r16,0b11
	brne	SET_YRIGHT
	lds		r16,POSY
	dec		r16
	sts		POSY,r16
	jmp		JOY_LIM

SET_YRIGHT:
	cpi		r16,0b00
	brne	JOY_LIM
	lds		r16,POSY
	inc		r16
	sts		POSY,r16

JOY_LIM:
	call	LIMITS		; don't fall off world!
	ret

	; ---------------------------------------
	; --- LIMITS Limit POSX,POSY coordinates	
	; --- Uses r16,r17
LIMITS:
	lds		r16,POSX	; variable
	ldi		r17,7		; upper limit+1
	call	POS_LIM		; actual work
	sts		POSX,r16
	lds		r16,POSY	; variable
	ldi		r17,5		; upper limit+1
	call	POS_LIM		; actual work
	sts		POSY,r16
	ret

POS_LIM:
	ori		r16,0		; negative?
	brmi	POS_LESS	; POSX neg => add 1
	cp		r16,r17		; past edge
	brne	POS_OK
	subi	r16,2
POS_LESS:
	inc		r16	
POS_OK:
	ret

	; ---------------------------------------
	; --- UPDATE VMEM
	; --- with POSX/Y, TPOSX/Y
	; --- Uses r16, r17
UPDATE:	
	clr		ZH 
	ldi		ZL,LOW(POSX)
	call 	SETPOS
	clr		ZH
	ldi		ZL,LOW(TPOSX)
	call	SETPOS
	ret

	; --- SETPOS Set bit pattern of r16 into *Z
	; --- Uses r16, r17
	; --- 1st call Z points to POSX at entry and POSY at exit
	; --- 2nd call Z points to TPOSX at entry and TPOSY at exit
SETPOS:
	ld		r17,Z+  	; r17=POSX
	call	SETBIT		; r16=bitpattern for VMEM+POSY
	ld		r17,Z		; r17=POSY Z to POSY
	ldi		ZL,LOW(VMEM)
	add		ZL,r17		; *(VMEM+T/POSY) ZL=VMEM+0..4
	ld		r17,Z		; current line in VMEM
	or		r17,r16		; OR on place
	st		Z,r17		; put back into VMEM
	ret
	
	; --- SETBIT Set bit r17 on r16
	; --- Uses r16, r17
SETBIT:
	ldi		r16,$01		; bit to shift
SETBIT_LOOP:
	dec 	r17			
	brmi 	SETBIT_END	; til done
	lsl 	r16			; shift
	jmp 	SETBIT_LOOP
SETBIT_END:
	ret

	; ---------------------------------------
	; --- Hardware init
	; --- Uses r16
HW_INIT:
/*
*** 	Konfigurera hårdvara och MUX-avbrott enligt ***
*** 	ditt elektriska schema. Konfigurera 		***
*** 	flanktriggat avbrott på INT0 (PD2).			***
*/
	ldi     r16,(1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10)
	out     MCUCR,r16; Activate
	ldi     r16,(1<<INT0) | (0<<INT1)
	out     GICR,r16; Enable Interrupts Globally

	ldi		r16,$FF
	out		DDRA,r16
	out		DDRB,r16
	
	sei
	ret

	; ---------------------------------------
	; --- WARM start. Set up a new game
WARM:

//*** 	Sätt startposition (POSX,POSY)=(0,2)		***
	ldi		r16,0
	sts		POSX,r16
	ldi		r16,2
	sts		POSY,r16	
		
	push	r0		
	push	r0		
	call	RANDOM		; RANDOM returns x,y on stack
	pop		r16 ; x
	pop		r17 ; y
	
	sts		TPOSX,r16
	sts		TPOSY,r17

	call	ERASE_VMEM
	ret

	; ---------------------------------------
	; --- RANDOM generate TPOSX, TPOSY
	; --- in variables passed on stack.
	; --- Usage as:
	; ---	push r0 
	; ---	push r0 
	; ---	call RANDOM
	; ---	pop TPOSX 
	; ---	pop TPOSY
	; --- Uses r16
RANDOM:
	in		r16,SPH
	mov		ZH,r16
	in		r16,SPL
	mov		ZL,r16
	lds		r16,SEED

	mov		r17,r16

	andi	r16,0b00000111
	cpi		r16,4
	brmi	CON1_RANDOM
	subi	r16,4

CON1_RANDOM:
	
	andi	r17,0b00111000
	lsr		r17
	lsr		r17
	lsr		r17

	cpi		r17,4
	brmi	CON2_RANDOM
	subi	r17,4

CON2_RANDOM:
	push	r17 ; y
	push	r16 ; x
	ret

	; ---------------------------------------
	; --- Erase Videomemory bytes
	; --- Clears VMEM..VMEM+4
	
ERASE_VMEM:
	push	r16
	push	r17
	push	XH
	push	XL
	
	ldi		XH,HIGH(VMEM)
	ldi		XL,LOW(VMEM)

	ldi		r17,0
	ldi		r16,0
ERASE_LOOP:
	st		X+,r17
	inc		r16
	cpi		r16,VMEM_SZ
	brne	ERASE_LOOP

	pop		XL
	pop		XH
	pop		r17
	pop		r16
	ret

	; ---------------------------------------
	; --- BEEP(r16) r16 half cycles of BEEP-PITCH
//*** skriv kod för ett ljud som ska markera träff 	***
BEEP:
	ldi			r19,$1
	out			PORTB,r19
	ldi			r19,BEEP_LENGTH
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
		ldi r25, HIGH(BEEP_PITCH)
		ldi r24, LOW(BEEP_PITCH)
		WAIT_LOOP:
			sbiw r24, 1
			brne WAIT_LOOP
		ret

	;--------------------------------------------------

DELAY:
	push	r24
	push	r25
	
	ldi		r24,LOW(GAME_SPEED)
	ldi		r25,HIGH(GAME_SPEED)

DELAY_LOOP:
	sbiw	r24,1
	brne	DELAY_LOOP

	pop		r25
	pop		r24
	ret



ADC8:
	out		ADMUX,r16
	ldi		r16,(1<<ADEN) ; A/D enable, ADPSx=111
	ori		r16,(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	out		ADCSRA,r16
ADC8_CONVERT:
	in		r16,ADCSRA
	ori		r16,(1<<ADSC)
	out		ADCSRA,r16 ; starta omvandling
ADC8_WAIT:
	in		r16,ADCSRA
	sbrc	r16,ADSC ; om 0-ställd, klar
	rjmp	ADC8_WAIT ; annars vänta
	in		r16,ADCH ; en läsning av hög byte
	ret