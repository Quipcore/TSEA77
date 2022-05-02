;
; labb3.asm
;
; Created: 5/1/2022 11:27:07 PM
; Author : Felix
;


; Replace with your application code
.cseg

MAIN:
    inc r16
    rjmp MAIN


PUSH_REG:
	push r16
	push r17
	push r18
	push r19
	push r20
	push r21
	push r22
	push r23
	push r24
	push r25
	ret
	
POP_REG:
	pop r25
	pop r24
	pop r23
	pop r22
	pop r21
	pop r20
	pop r19
	pop r18
	pop r17
	pop r16
	ret

