; ACIA.ASM: A simple interface to the ACIA routines already in the
;           RC2014's MS-BASIC ROM.
;
; Copyright (C) 2018-2019, Bradan J. Wolbeck (CompaqDisc)
; <bwolbeck@compaqdisc.com>
;
; ACIA.ASM is a part of MON2014.
;
; Please see LICENSE in this project's root directory for license information.

ACIA_PUTCHAR:
	; Outputs the byte in A.
	RST	08H
	RET

ACIA_GETCHAR:
	; Collects the next byte in A.
	RST	10H
	RET
