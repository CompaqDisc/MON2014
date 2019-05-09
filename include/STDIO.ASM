; STDIO.ASM:	A text function interface for MON2014.
;
; Copyright (C) 2018-2019, Bradan J. Wolbeck (CompaqDisc)
; <bwolbeck@compaqdisc.com>
;
; STDIO.ASM is a part of MON2014.
;
; Please see LICENSE in this project's root directory for license information.

#include "ACIA.ASM"

PUTCHAR:
	JR	ACIA_PUTCHAR

GETCHAR:
	JR	ACIA_GETCHAR

PUTS:
	; OutPUTS a null terminated string pointed to by HL.
	LD	A,(HL)
	OR	A
	RET	Z
	CALL	PUTCHAR
	INC	HL
	JR	PUTS

GETS:
	; Buffer address passed in HL
	; Save HL
	LD	DE,HL
GETS.LP1:
	; while GETCHAR() != \n
	CALL	GETCHAR
	CP	13
	JR	Z,GETS.END

	; Check if a == \e
	CP	27
	; BUG/WONTFIX: Doesn't handle escape sequences... Therefore DELETE
	; won't work.
	; Discard ESC
	JR	Z,GETS.LP1

	; Check if a == \b
	CP	8
	; If not then continue with character.
	JR	NZ,GETS.LP3
	; If so then:
	; 16-bit compare between HL and DE
	; Carry is clear before operation.
	SBC	HL,DE
	ADD	HL,DE
	; DE == HL, don't do anything!
	JR	Z,GETS.LP1
	; DE < HL, go back one.
	JR	NC,GETS.BSP

GETS.LP3:
	; Print and store character in buffer.
	CALL	PUTCHAR
	LD	(HL),A
	INC	HL
	JR	GETS.LP1

GETS.BSP:
	; Move back in the buffer, and overwrite the screen.
	DEC	HL
	LD	A,8
	CALL	PUTCHAR
	LD	A,32
	CALL	PUTCHAR
	LD	A,8
	CALL	PUTCHAR
	JR	GETS.LP1

GETS.END:
	; NULL terminator
	LD	(HL),0
	; Restore HL
	LD	HL,DE
	RET
