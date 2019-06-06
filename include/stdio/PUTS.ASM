; PUTS.ASM:
;
; Copyright (C) 2018-2019, Bradan J. Wolbeck (CompaqDisc)
; <bwolbeck@compaqdisc.com>
;
; PUTS.ASM is a part of MON2014.
;
; Please see LICENSE in this project's root directory for license information.

PUTS:
	LD	A,(HL)
	OR	A
	RET	Z
	CALL	PUTCHAR
	INC	HL
	JR	PUTS
