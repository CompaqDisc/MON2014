; MON2014:	A monitor program for unmodified RC2014 micro-computers,
;		designed to run completely in memory, independent of BASIC.
;
; Copyright (C) 2018-2019, Bradan J. Wolbeck (CompaqDisc)
; <bwolbeck@compaqdisc.com>
;
; Please see LICENSE in this project's root directory for license information.
;
; Author's Notes:	At ROM BASIC's "memory top?" prompt, enter 35071.
;			Use of a modified HEXLOAD.BAS (provided in the project.
;			repository) is recommended for loading this program.

#include "include/CHARSET.ASM"
A_BUFFER:	.EQU $FF00
CFDRV.CFG.PORT:	.EQU $E0

	.ORG	$F000

MON2014:
	; This label is called from BASIC via HEXLOAD.BAS
	;LD	SP,$A000			; Haven't needed the stack yet...
						; Might end up relocating the application
						; further along in development.
	CALL	CFDRV.INIT

MON2014.BEGIN:
	; Clear screen, and home cursor.
	LD	HL,STRING.CLEAR_SCREEN
	CALL	PUTS
	LD	HL,STRING.HOME_CURSOR
	CALL	PUTS
	; Print title and copyright notice.
	LD	HL,STRING.COPYRIGHT
	CALL	PUTS

MON2014.PROMPT_USER:
	; Print ']' prompt.
	LD	HL,STRING.PROMPT
	CALL	PUTS

	; Set HL to head of input buffer
	; Get string to buffer.
	LD	HL,A_BUFFER
	CALL	GETS

MON2014.PARSE_INPUT:
	LD	A,(HL)				; Store command letter
	INC	HL				; Skip letter
	INC	HL				; Skip space

	; switch(A)
	CP	'R'				; case 'R':
	JP	Z,$0000

	CP	'G'				; case 'G':
	JP	Z,MON2014.COMMAND.GOTO

	CP	'S'				; case 'S':
	JP	Z,MON2014.COMMAND.STORE

	CP	'X'				; case 'X':
	JP	Z,MON2014.COMMAND.EXAMINE

	CP	'C'				; case 'C':
	JP	Z,MON2014.COMMAND.CFCARD

	CP	'?'				; case '?':
	JP	Z,MON2014.COMMAND.HELP

	JP	MON2014.ERROR			; default:

MON2014.COMMAND.GOTO:
	CALL	HEX2BC				; Parse address into BC
	LD	HL,BC				; Load in prep for jump
	JP	(HL)				; Perform the jump

MON2014.COMMAND.STORE:
	CALL	HEX2BC				; Parse address into BC
	INC	HL				; Skip space
	CALL	HEX2A				; Parse value into A
	LD	(BC),A				; Store A via indirect addressing
	JP	MON2014.PROMPT_USER

MON2014.COMMAND.EXAMINE:
	CALL	HEX2BC				; Get address in BC
	LD	HL,BC				; Back up BC

	LD	E,16				; Loop count for 16 lines of hexdump.
EXAMINE.LOOPLINE
	LD	A,CR				; Print newline.
	CALL	PUTCHAR
	LD	A,LF
	CALL	PUTCHAR

	CALL	DISPHL				; Print address

	LD	A,$20				; 3 Spaces
	CALL	PUTCHAR
	LD	A,$20
	CALL	PUTCHAR
	LD	A,$20
	CALL	PUTCHAR

	LD	D,16				; Loop count for 16 values/line
EXAMINE.LOOPVAL
	LD	A,(HL)				; Get value in C, print value.
	LD	C,A
	CALL	OUTHEX8
	INC	HL				; Next value address.

	LD	A,$20				; Print space
	CALL	PUTCHAR

	DEC	D
	JR	NZ,EXAMINE.LOOPVAL		; Decide loop for 16 values/line.
	DEC	E
	JR	NZ,EXAMINE.LOOPLINE		; Decide loop for line.

	JP	MON2014.PROMPT_USER

MON2014.COMMAND.CFCARD:
	; Parse/set LBA
	CALL	HEX2BC
	LD	IYH,B		; LBA 24-27
	LD	IYL,C		; LBA 16-23
	CALL	HEX2BC
	LD	IXH,B		; LBA 8-15
	LD	IXL,C		; LBA 0-7
	CALL	CFDRV.SETLBA
	; Parse dest addr.
	INC	HL
	CALL	HEX2BC
	; Decide R/W
	INC	HL
	LD	A,(HL)
	CP	'R'
	JR	Z,MON2014.COMMAND.CFCARD.READ
	CP	'W'
	JR	Z,MON2014.COMMAND.CFCARD.WRITE

	JP	MON2014.ERROR

MON2014.COMMAND.CFCARD.READ:
	LD	HL,BC		; Pointer
	CALL	CFDRV.READSEC
	JP	MON2014.PROMPT_USER

MON2014.COMMAND.CFCARD.WRITE:
	LD	HL,BC		; Pointer
	CALL	CFDRV.WRITESEC
	JP	MON2014.PROMPT_USER

MON2014.COMMAND.HELP:
	LD	HL,STRING.ACTION.HELP
	CALL	PUTS
	JP	MON2014.PROMPT_USER

MON2014.ERROR:
	; Print a trailing '?', indicating an error.
	LD	HL,STRING.ERROR
	CALL	PUTS
	JP	MON2014.PROMPT_USER

; ======================================
; | Store HEX version of value in BC/A |
; ======================================
HEX2BC:
	; Takes HL as a pointer to a buffer.
	; Gets value from ASCII HEX (reads 4 bytes) and stores in BC.
	CALL	HEX2A
	LD	B,A
	INC	HL
	INC	HL
	CALL	HEX2A
	LD	C,A
	INC	HL
	INC	HL
	RET

HEX2A:
	; Takes HL as a pointer to a buffer.
	; Gets value from ASCII HEX (reads 2 bytes) and stores in A.
	LD	DE,(HL)

	LD	A,E
	CALL	HEX2A.1
	ADD	A,A
	ADD	A,A
	ADD	A,A
	ADD	A,A
	LD	E,A
	LD	A,D
	CALL	HEX2A.1
	OR	E
	RET

HEX2A.1:
	SUB	A,'0'
	CP	10
	RET	C
	SUB	A,'A'-'0'-10
	RET
; ==================================

DISPHL:
	LD	C,H
	CALL	OUTHEX8
	LD	C,L
OUTHEX8:
	LD	A,C
	RRA
	RRA
	RRA
	RRA
	CALL	CONV
	LD	A,C
CONV:
	AND	$0F
	ADD	A,$90
	DAA
	ADC	A,$40
	DAA
	CALL	PUTCHAR
	RET

#include "include/acia/ACIA.ASM"
#include "include/acia/DRIVER.ASM"
#include "include/stdio/STDIO.ASM"
#include "include/CFDRV.ASM"

STRING.COPYRIGHT:	DB "MON2014 Copyright (C) 2018-2019, Bradan J. Wolbeck"
STRING.COPYRIGHT.END:	DB EOS
STRING.PROMPT:		DB CR, LF, "] ", EOS
STRING.ERROR:		DB " ?", EOS
STRING.CLEAR_SCREEN:	DB ESC, "[2J", EOS
STRING.HOME_CURSOR:	DB ESC, "[H", EOS
STRING.ACTION.HELP:	DB CR, LF, "HELP:"
STRING.HELP.1:		DB CR, LF, "?",       TAB, TAB, TAB, "Print Help"
STRING.HELP.2:		DB CR, LF, "R",       TAB, TAB, TAB, "Reset Computer"
STRING.HELP.3:		DB CR, LF, "G ?ADDR", TAB, TAB, TAB, "Goto Address"
STRING.HELP.4:		DB CR, LF, "S ?ADDR ?V",   TAB, TAB, "Store Value"
STRING.HELP.5:		DB CR, LF, "X ?ADDR", TAB, TAB, TAB, "Examine Data"
STRING.HELP.6:		DB CR, LF, "C ?LBA32 ?ADDR R",  TAB, "Read CF Sector"
STRING.HELP.7:		DB CR, LF, "C ?LBA32 ?ADDR W",  TAB, "Write CF Sector"
STRING.HELP.END:	DB EOS
