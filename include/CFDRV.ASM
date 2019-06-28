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
	LD	HL,CFDRV.MSG.INIT
	CALL	PUTS
	; Initialize the CompactFlash card.
	; Set feature: 8-bit transfers.
	CALL	CFDRV.WAITBUSY
	LD	A,$01
	OUT	CFDRV.R1,A

	CALL	CFDRV.WAITBUSY
	LD	A,$EF
	OUT	CFDRV.R7,A

	; Set feature: Disable write cache.
	CALL	CFDRV.WAITBUSY
	LD	A,$82
	OUT	CFDRV.R1,A

	CALL	CFDRV.WAITBUSY
	LD	A,$EF
	OUT	CFDRV.R7,A

CFDRV.SETCOUNT:
	; Set sector count to $01
	CALL	CFDRV.WAITBUSY
	LD	A,$01
	OUT	CFDRV.R2,A

	; Done
	RET

CFDRV.WAITBUSY:
	; Wait until the busy bit ($80) of register 7 is unset.
	IN	A,CFDRV.R7
	AND	%10000000
	JR	NZ,CFDRV.WAITBUSY
	RET

CFDRV.WAITCMD:
	; Wait until the ready bit ($40) of register 7 is set,
	; and the busy bit ($80) is unset.
	IN	A,CFDRV.R7
	AND	%11000000
	XOR	%01000000
	JR	NZ,CFDRV.WAITCMD
	RET

CFDRV.WAITDAT:
	; Wait until the DRQ bit ($08) of register 7 is set,
	; and the busy bit ($80) is unset.
	IN	A,CFDRV.R7
	AND	%10001000
	XOR	%00001000
	JR	NZ,CFDRV.WAITDAT
	RET

CFDRV.SETLBA:
	; Load the LBA address from IX and IY
	CALL	CFDRV.WAITBUSY
	LD	A,IXL		; LBA Bits 0-7
	OUT	CFDRV.R3,A
	CALL	CFDRV.WAITBUSY
	LD	A,IXH		; LBA Bits 8-15
	OUT	CFDRV.R4,A
	CALL	CFDRV.WAITBUSY
	LD	A,IYL		; LBA Bits 16-23
	OUT	CFDRV.R5,A
	CALL	CFDRV.WAITBUSY
	LD	A,IYH		; LBA Bits 24-27
	OR	$E0		; Set LBA Mode
	OUT	CFDRV.R6,A
	; Done
	RET

CFDRV.READSEC:
	; Read a sector from the CF card (512 bytes),
	; and store beginning at the address provided by HL.
	LD	DE,HL
	LD	HL,CFDRV.MSG.READ
	CALL	PUTS
	LD	HL,DE
	; Set sector count to one.
	CALL	CFDRV.SETCOUNT
	; Wait until device ready for command.
	CALL	CFDRV.WAITCMD
	; Read sectors command.
	LD	A,$20
	OUT	CFDRV.R7,A
	; Wait until device ready with data.
	CALL	CFDRV.WAITDAT
	IN	A,CFDRV.R7
	AND	%00000001
	JR	NZ,CFDRV.READSEC
	LD	B,0
CFDRV.READSEC.LOOP:
	LD	A,'.'
	CALL	PUTCHAR
	; Read 512 bytes from IO starting at the pointer HL.
	CALL	CFDRV.WAITDAT
	IN	A,CFDRV.R0
	LD	(HL),A
	INC	HL
	CALL	CFDRV.WAITDAT
	IN	A,CFDRV.R0
	LD	(HL),A
	INC	HL
	DJNZ	CFDRV.READSEC.LOOP
	; Done
	RET

CFDRV.WRITESEC:
	; Write a sector to the CF card (512 bytes),
	; and read beginning at the address provided by HL.
	LD	DE,HL
	LD	HL,CFDRV.MSG.WRITE
	CALL	PUTS
	LD	HL,DE
	; Set sector count to one.
	CALL	CFDRV.SETCOUNT
	; Wait until device ready for command.
	CALL	CFDRV.WAITCMD
	; Write sectors command.
	LD	A,$30
	OUT	CFDRV.R7,A
	; Wait until device ready to accept data.
	CALL	CFDRV.WAITDAT
	IN	A,CFDRV.R7
	AND	%00000001
	JR	NZ,CFDRV.WRITESEC
	LD	B,0
CFDRV.WRITESEC.LOOP:
	LD	A,'.'
	CALL	PUTCHAR
	; Write 512 bytes to IO starting at the pointer HL.
	CALL	CFDRV.WAITDAT
	LD	A,(HL)
	OUT	CFDRV.R0,A
	INC	HL
	CALL	CFDRV.WAITDAT
	LD	A,(HL)
	OUT	CFDRV.R0,A
	INC	HL
	DJNZ	CFDRV.WRITESEC.LOOP
	; Done
	RET

CFDRV.MSG.INIT:		DB CR, LF, "CFDRV Init", EOS
CFDRV.MSG.SETLBA:	DB CR, LF, "CFDRV Set LBA", EOS
CFDRV.MSG.READ:		DB CR, LF, "CFDRV Read Xfer", EOS
CFDRV.MSG.WRITE:	DB CR, LF, "CFDRV Write Xfer", EOS
