; --- lab4spel.asm

	.equ	VMEM_SZ     = 5		; #rows on display
	.equ	AD_CHAN_X   = 0		; ADC0=PA0, PORTA bit 0 X-led
	.equ	AD_CHAN_Y   = 1		; ADC1=PA1, PORTA bit 1 Y-led
	.equ	GAME_SPEED  = 70	; inter-run delay (millisecs)
	.equ	PRESCALE    = 7		; AD-prescaler value
	.equ	BEEP_PITCH  = 20	; Victory beep pitch
	.equ	BEEP_LENGTH = 100	; Victory beep length
	.equ	FREQ = 300
	
	; ---------------------------------------
	; --- Memory layout in SRAM
	; ---------------------------------------
	.dseg
	.org	SRAM_START
POSX:	.byte	1	; Own position
POSY:	.byte 	1
TPOSX:	.byte	1	; Target position
TPOSY:	.byte	1
LINE:	.byte	1	; Current line	
VMEM:	.byte	VMEM_SZ ; Video MEMory
SEED:	.byte	1	; Seed for Random

	; ---------------------------------------
	; --- Macros for inc/dec-rementing
	; --- a byte in SRAM
	; ---------------------------------------
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
	; ---------------------------------------
	.cseg
	.org 	$00000000
	jmp		START
	.org	INT0addr
	jmp		MUX

	.org	INT_VECTORS_SIZE

	; ------------------------------------------------------------
	; --- START THE PROGRAM HERE, Runs the Run routine afterwards
	; ------------------------------------------------------------
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
	call	DELAY
	call	DELAY
	call	DELAY

	call	WARM
NO_HIT:
	jmp		RUN


	; ---------------------------------------
	; --- Hardware init
	; --- Uses r16
	; ---------------------------------------
HW_INIT:
	push	r16

	ldi     r16,(1<<ISC01) | (0<<ISC00) | (1<<ISC11) | (0<<ISC10)
	out     MCUCR,r16
	ldi     r16,(1<<INT0) | (0<<INT1)
	out     GICR,r16

	ldi		r16,$FF
	out		DDRB,r16
	
	ldi		r16,$F0
	out		DDRD,r16

	ldi		r16,0b1111100
	out		DDRA,r16
	sei

	pop		r16
	ret

	; ---------------------------------------
	; --- WARM start. Set up a new game
	; ---------------------------------------
WARM:
	push	r16
	push	r17

	ldi		r16,0
	sts		POSX,r16
	ldi		r16,2
	sts		POSY,r16	
	
	push	r0
	push	r0
	call	RANDOM		; RANDOM returns x,y on stack
	
	pop		r16 ; x
	pop		r17 ; y
	/*
	ldi		r16,3
	ldi		r17,3
	*/
	sts		TPOSX,r16
	sts		TPOSY,r17

	call	ERASE_VMEM

	pop		r17
	pop		r16
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
	; ---------------------------------------
RANDOM: ; Last subroutine
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
	std		Z+3,r16 ; Store xpos(r16) to stack

CON1_RANDOM:
	
	andi	r17,0b00111000
	lsr		r17
	lsr		r17
	lsr		r17

	cpi		r17,4
	brmi	CON2_RANDOM
	subi	r17,4
	std		Z+4,r17
CON2_RANDOM:
	ret


	; ---------------------------------------
	; --- Erase Videomemory bytes
	; --- Clears VMEM..VMEM+4
	; ---------------------------------------
	
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
		
	; -------------------------------------------------
	; --- JOYSTICK Sense stick and update POSX, POSY
	; --- Uses r16
	; -------------------------------------------------
JOYSTICK:	
	push	r16
	push	r17

	ldi		r16,0 ;PORTA0,x
	call	ADC10

	cpi		r16,0b11
	brne	DECREASE_X
	push	r16
	INCSRAM POSX
	pop		r16
	rjmp	CHANGE_Y_POS
DECREASE_X:
	cpi		r16,0b00
	brne	CHANGE_Y_POS
	DECSRAM POSX

CHANGE_Y_POS:
	ldi		r16,1 ; PORTA1,y
	call	ADC10

	cpi		r16,0b11
	brne	DECREASE_Y
	push	r16
	INCSRAM POSY
	pop		r16
	rjmp	JOY_LIM
DECREASE_Y:
	cpi		r16,0b00
	brne	JOY_LIM
	DECSRAM POSY

JOY_LIM:
	call	LIMITS		; don't fall off world!
	pop		r17
	pop		r16
	ret

	; -------------------------------------------------------------
	; --- AD-Converter
	; --- Push r16 before using
	; -------------------------------------------------------------
ADC10:
	out		ADMUX,r16
	ldi		r16,(1<<ADEN) ; A/D enable, ADPSx=111
	ori		r16,(1<<ADPS2)|(1<<ADPS1)|(1<<ADPS0)
	out		ADCSRA,r16
ADC10_CONVERT:
	in		r16,ADCSRA
	ori		r16,(1<<ADSC)
	out		ADCSRA,r16 ; starta omvandling
ADC10_WAIT:
	in		r16,ADCSRA
	sbrc	r16,ADSC ; om 0-ställd, klar
	rjmp	ADC10_WAIT ; annars vänta
	//in		r16,ADCL ; obs, läs låg byte först
	in		r16,ADCH ; hög byte sedan
	ret

	; ---------------------------------------
	; --- LIMITS Limit POSX,POSY coordinates	
	; --- Uses r16,r17
	; ---------------------------------------
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

	; -------------------------------------------------------------
	; --- UPDATE VMEM
	; --- with POSX/Y, TPOSX/Y
	; --- Uses r16, r17
	; -------------------------------------------------------------
UPDATE:	
	clr		ZH 
	ldi		ZL,LOW(POSX)
	call 	SETPOS
	clr		ZH
	ldi		ZL,LOW(TPOSX)	
	call	SETPOS
	ret

	; -------------------------------------------------------------
	; --- SETPOS Set bit pattern of r16 into *Z					---
	; --- Uses r16, r17											---
	; --- 1st call Z points to POSX at entry and POSY at exit   ---
	; --- 2nd call Z points to TPOSX at entry and TPOSY at exit ---
	; -------------------------------------------------------------
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

	; -------------------------------------------
	; --- BEEP(r16) r16 half cycles of BEEP-PITCH
	; -------------------------------------------
BEEP: ;return void
	;	r19  - temp storage 
	ldi			r19,$20
	call		BEEP_LOOP	
	ret
	
	BEEP_LOOP:
		sbi PORTA, 0b100
		call WAIT
		cbi PORTA, 0b100
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

	; --------------------------------------------------
	; --- DELAY
	; --------------------------------------------------
DELAY:

	ldi			r24,$FF
	ldi			r25,$FF
	subi		r24,LOW(GAME_SPEED*4000)-1 ; see notes for more info
	subi		r25,HIGH(GAME_SPEED*4000)

	LOOP_DELAY:
	adiw		r24,1
	brne		LOOP_DELAY
	
	ret

	; ---------------------------------------
	; --- Multiplex display - INT0
	; ---------------------------------------
MUX:		
	push	r16
	in		r16,SREG
	push	r16
	push	r17
	push	XH
	push	XL

	ldi		XH,HIGH(VMEM)
	ldi		XL,LOW(VMEM)

	lds		r16,LINE
	add		XL,r16
	ldi		r16,0
	adc		XH,r16

	ld		r16,X
	out		PORTB,r16
	lds		r16,LINE
	swap	r16
	out		PORTD,r16

	INCSRAM SEED
	INCSRAM LINE

	cpi		r16,VMEM_SZ
	brne	END_MUX
	ldi		r16,0
	sts		LINE,r16

END_MUX:
	pop		XL
	pop		XH
	pop		r17
	pop		r16
	out		SREG,r16
	pop		r16
	reti