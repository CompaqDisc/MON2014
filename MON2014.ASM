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

	; Idealy the main structure should look like:
	; Prompt > Get Input > Parse/Correct > Error/Execute > Repeat

	; Set HL to head of input buffer
	; Get string to buffer.
	LD	HL,A_BUFFER
	CALL	GETS

MON2014.PARSE_INPUT:
	LD	A,(HL)

	; switch(A)
	CP	'R'				; case 'R':
	RET	Z

	CP	'G'				; case 'G':
	JR	Z,MON2014.COMMAND.GOTO

	CP	'S'				; case 'S':
	JR	Z,MON2014.COMMAND.STORE

	CP	'X'				; case 'X':
	JR	Z,MON2014.COMMAND.EXAMINE

	CP	'C'				; case 'C':
	JR	Z,MON2014.COMMAND.CFCARD	; CF not yet implemented

	CP	'?'				; case '?':
	JR	Z,MON2014.COMMAND.HELP

	JR	MON2014.ERROR			; default:

MON2014.COMMAND.GOTO:
	INC	HL				; Skip past command and space
	INC	HL
	CALL	HEX2BC
	LD	HL,BC
	JP	(HL)

MON2014.COMMAND.STORE:
	INC	HL				; Skip past command and space
	INC	HL
	CALL	HEX2BC
	INC	HL
	INC	HL
	INC	HL
	CALL	HEX2A
	LD	HL,BC
	LD	(HL),A
	JR	MON2014.PROMPT_USER

MON2014.COMMAND.EXAMINE:
	JR	MON2014.ERROR

MON2014.COMMAND.CFCARD:
	; Fixed-LBA test read.
	LD	IX,$0000	; Low LBA
	LD	IY,$0000	; High LBA
	CALL	CFDRV.SETLBA
	LD	HL,$D000	; Data Buffer
	CALL	CFDRV.READSEC
	JR	MON2014.PROMPT_USER

MON2014.COMMAND.HELP:
	LD	HL,STRING.ACTION.HELP
	CALL	PUTS
	JR	MON2014.PROMPT_USER

MON2014.ERROR:
	; Print a trailing '?', indicating an error.
	LD	HL,STRING.ERROR
	CALL	PUTS
	JR	MON2014.PROMPT_USER

HEX2BC:
	; Takes HL as a pointer to a buffer.
	; Gets value from ASCII HEX (reads 4 bytes) and stores in BC.
	CALL	HEX2A
	LD	B,A
	INC	HL
	INC	HL
	CALL	HEX2A
	LD	C,A
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

#include "include/STDIO.ASM"
#include "include/CFDRV.ASM"

STRING.COPYRIGHT:	DB "MON2014 Copyright (C) 2018-2019, Bradan J. Wolbeck"
STRING.COPYRIGHT.END:	DB EOS
STRING.PROMPT:		DB CR, LF, "] ", EOS
STRING.ERROR:		DB " ?", EOS
STRING.CLEAR_SCREEN:	DB ESC, "[2J", EOS
STRING.HOME_CURSOR:	DB ESC, "[H", EOS
STRING.ACTION.HELP:	DB CR, LF, "HELP:"
STRING.HELP.1:		DB CR, LF, "?",       TAB, TAB, "Print Help"
STRING.HELP.2:		DB CR, LF, "R",       TAB, TAB, "Return to ROM BASIC"
STRING.HELP.3:		DB CR, LF, "G ?ADDR", TAB, TAB, "Goto Address"
STRING.HELP.4:		DB CR, LF, "S ?ADDR ?V",   TAB, "Store Value"
STRING.HELP.5:		DB CR, LF, "X ?ADDR", TAB, TAB, "Read Data"
STRING.HELP.6:		DB CR, LF, "C R ?S ?ADDR", TAB, "Read CF Sector"
STRING.HELP.7:		DB CR, LF, "C W ?S ?ADDR", TAB, "Write CF Sector"
STRING.HELP.END:	DB EOS
