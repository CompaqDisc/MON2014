; CompactFlash Driver for MON2014
;
; Copyright (C) 2019, Bradan J. Wolbeck (CompaqDisc)
; <bwolbeck@compaqdisc.com>
;
; Please see LICENSE in this project's root directory for license information.

CFDRV.R0:	.EQU CFDRV.CFG.PORT + $00
CFDRV.R1:	.EQU CFDRV.CFG.PORT + $01
CFDRV.R2:	.EQU CFDRV.CFG.PORT + $02
CFDRV.R3:	.EQU CFDRV.CFG.PORT + $03
CFDRV.R4:	.EQU CFDRV.CFG.PORT + $04
CFDRV.R5:	.EQU CFDRV.CFG.PORT + $05
CFDRV.R6:	.EQU CFDRV.CFG.PORT + $06
CFDRV.R7:	.EQU CFDRV.CFG.PORT + $07

CFDRV.RDATA	.EQU CFDRV.R0
CFDRV.RERROR	.EQU CFDRV.R1
CFDRV.RFEATURE	.EQU CFDRV.R1
CFDRV.RSCOUNT	.EQU CFDRV.R2
CFDRV.RLBA0	.EQU CFDRV.R3
CFDRV.RLBA1	.EQU CFDRV.R4
CFDRV.RLBA2	.EQU CFDRV.R5
CFDRV.RLBA3	.EQU CFDRV.R6
CFDRV.RSTATUS	.EQU CFDRV.R7
CFDRV.RCOMMAND	.EQU CFDRV.R7

CFDRV.INIT:
	; Initialize the CompactFlash card.
	CALL	CFDRV.WAITBUSY
	; Set feature: 8-bit transfers.
	LD	A,$01
	OUT	CFDRV.R1,A
	LD	A,$EF
	OUT	CFDRV.R7,A
	; Set feature: Disable write cache.
	LD	A,$82
	OUT	CFDRV.R1,A
	LD	A,$EF
	OUT	CFDRV.R7,A
	; Done
	RET

CFDRV.WAITBUSY:
	; Wait until the busy bit ($80) of register 7 is unset.
	IN	A,CFDRV.R7
	AND	$80
	RET	Z
	JR	CFDRV.WAITBUSY

CFDRV.WAITREADY:
	; Wait until the ready bit ($40) of register 7 is set.
	IN	A,CFDRV.R7
	AND	$40
	RET	NZ
	JR	CFDRV.WAITREADY

CFDRV.WAITDRQ:
	; Wait until the DRQ bit ($08) of register 7 is set.
	IN	A,CFDRV.R7
	AND	$08
	RET	NZ
	JR	CFDRV.WAITDRQ

CFDRV.READSEC:
	; Read a sector from the CF card (512 bytes),
	; and store beginning at the address provided by HL.
	; LBA of sector on stack. (Hardcoded to 0 for now)
CFDRV.READSEC.WAIT1:
	; Busy must be unset and Ready must be set.
	CALL	CFDRV.WAITBUSY
	CALL	CFDRV.WAITREADY
	; Confirm conditions simultaneously met.
	IN	A,CFDRV.R7
	AND	$C0
	CP	$40
	; If not, try again.
	JR	NZ,CFDRV.READSEC.WAIT1
; Continue
	; Set sector count to $01
	LD	A,$01
	OUT	CFDRV.R2,A
	; Load the LBA address (hard coded to 0 for now)
	XOR	A
	OUT	CFDRV.R3,A
	OUT	CFDRV.R4,A
	OUT	CFDRV.R5,A
	OR	$E0
	OUT	CFDRV.R6,A
	; Read sectors command.
	LD	A,$20
	OUT	CFDRV.R7,A
CFDRV.READSEC.WAIT2:
	; Busy must be unset, and DRQ must be set.
	CALL	CFDRV.WAITBUSY
	CALL	CFDRV.WAITDRQ
	; Confirm conditions simultaneously met.
	IN	A,CFDRV.R7
	AND	$88
	CP	$08
	; If not, retry.
	JR	NZ,CFDRV.READSEC.WAIT2
; Continue
	; Read 512 bytes to the pointer HL.
	; Set port
	LD	C,CFDRV.R0

	LD	HL,$D000
	LD	B,$FF
	INIR

	LD	HL,$D100
	LD	B,$FF
	INIR

	; Done
	RET
