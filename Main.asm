; Sega Master System test program


.include	"SMS.inc"

	.org	$00

; ================================================================
; Macros
; ================================================================

; USAGE: lcolor reg, R, G, B
; R = Red component (0-3)
; G = Green component (0-3)
; B = Blue component (0-3)
; EXAMPLE: lcolor 3,0,3 >> a = %00110011 (magenta)
.macro lcolor
		ld a, \1 | (\2 << 2) | (\3 << 4)
.endm
	
; USAGE: color R, G, B
; R = Red component (0-3)
; G = Green component (0-3)
; B = Blue component (0-3)
; EXAMPLE: color 3,0,3 >> .db %00110011 ; magenta
.macro color
	.db \1 | (\2 << 2) | (\3 << 4)
.endm

; USAGE: coord reg,x,y
; x = X coordinate
; y = Y coordinate
; EXAMPLE: coord de,5,6 >> de = VDP offset for given coordinates
.macro coord
	ld	de,$3800 + ((\1 * 2) + (\2 * 64))
.endm
	
; USAGE: lbbc x,y
; x = First parameter
; y = Second parameter
; EXAMPLE: lbbc 42,56 >> b = 42, c = 56
.macro	lbbc
	ld	bc,(\1 << 8) | \2
.endm

; Same as above but for de
.macro	lbde
	ld	de,(\1 << 8) | \2
.endm

; Same as lbbc but for hl
.macro	ldhl
	ld	hl,(\1 << 8) | \2
.endm

; USAGE: SetVDP register, data
; reg = VDP register (see SMS.inc for a list of registers)
; data = obvious
; EXAMPLE: SetVDP rVDPBorderColor,8 >> send command to change border color to VDP
.macro SetVDP 
	ld	de,((VDP_WriteReg | \1) << 8) | \2
	rst	$08
.endm
	
; USAGE: WaitForVDP
; No parameters, it's just three nops...
.macro WaitForVDP
	nop
	nop
	nop
.endm

; ================================================================
; RAM defines
; ================================================================

.ramsection "System variables" slot 1 returnorg
	sys_CurrentFrame	db
.ends

; ================================================================
; Start of actual code
; ================================================================

	.org	$00
EntryPoint:
	di
	im		1
	jr		Init
	
	.org	$8
.SetVDP:
	ld		c,rVDPAddr
	out		[c],e
	out		[c],d
	ret

	.org	$10
.FillRAM:
	jp		FillRAM

Init:
	ld		de,$fffc
	ld		hl,InitValues
	ld		bc,4
	ldir
	jp		Start
InitValues:		.db	0,0,1,2
	
; --------------------------------

; Interrupt handler
HandleIRQ:
	push	af
	in		a,[rVDPStatus]
	pop		af
	reti

	.org	$38
; Interrupt IRQ vector
.HandleIRQ:
	jr	HandleIRQ

; --------------------------------
	.org	$66

; NMI handler
; Executed when the Pause button is pressed
NMI:
	retn
	
; ================================================================

	.org	$80
Start:	
	ld		sp,$dffe
	; set up VDP
	SetVDP	rVDPFlags1,(1 << bVDP_Mode4) | (1 << bVDP_ScreenStretch) | (1 << bVDP_EnableScanlineIRQ)
	SetVDP	rVDPFlags2,(1 << bVDP_Unused2) | (1 << bVDP_DisplayOn) ; | (1 << bVDP_EnableVBlankIRQ)
	SetVDP	rVDPScreenBase,$ff
	SetVDP	rVDPSpriteBase,$ff
	SetVDP	rVDPTileBase,$fb
	SetVDP	rVDPBorderColor,$f0 | 0
	SetVDP	rVDPScrollX,0
	SetVDP	rVDPScrollY,0
	SetVDP	rVDPScanlineInt,80
	
	call	ClearVRAM
	ld		hl,TextPal
	call	LoadBGPal
	
	ld		hl,Font
	ld		bc,Font_End-Font
	ld		de,0
	call	VDPCopy
	
	ld		hl,strDevSound
	coord	3,1
	call	PrintString
	

	ld		hl,strNowPlaying
	coord	1,3
	call	PrintString
	ld		hl,[DS_SongNamePtr]
	coord	1,4
	call	PrintString

;	ld		hl,strControls1
;	coord	1,3
;	call	PrintString
;	ld		hl,strControls2
;	coord	1,4
;	call	PrintString
;	ld		hl,strControls3
;	coord	1,5
;	call	PrintString
;	ld		hl,strControls4
;	coord	1,6
;	call	PrintString
	xor		a
 	ld		[sys_CurrentFrame],a
	
	; To start playing a song:
	; 1. Load HL with a pointer to the song's header
	; 2. Call DS_PlaySong
	ld		hl,mus_Victory
	call	DS_PlaySong

; protip: don't do this
@loop
	ld		bc,1601+255
-	dec		bc
	inc		b
	djnz	-

	xor		a
	out		[rVDPAddr],a
	ld		a,VDP_WritePal
	out		[rVDPAddr],a
	lcolor	3,0,0
	out		[rVDPData],a

	call	DS_Update	; do this once per frame

	xor		a
	out		[rVDPAddr],a
	ld		a,VDP_WritePal
	out		[rVDPAddr],a
	lcolor	0,0,0
	out		[rVDPData],a

	ld		hl,sys_CurrentFrame
	inc		[hl]
	
	ld		hl,[DS_SongNamePtr]
	coord	1,4
	call	PrintString
	
@wait
	in		a,rVDPStatus
	bit		bVDPStatus_VBlank,a
	jr		z,@wait
	; VBlank operations go here	
	jr		@loop

strDevSound:	.db	"DevSound SMS v0.1 by DevEd",0
strNowPlaying:	.db	"Now playing:",0
;strControls1:	.db	"Controls:",0
;strControls2:	.db "D-pad  . . . . . . Select song",0
;strControls3:	.db	"I  . . . . . . . . . Play song",0
;strControls4:	.db	"II . . . . . . . . . Stop song",0
	
; ================================================================
; GFX routines
; ================================================================
	
ClearVRAM:
	ld		bc,$3fff
	xor		a
	out		[rVDPAddr],a
	or		VDP_WriteVRAM
	out		[rVDPAddr],a
-	xor		a
	WaitForVDP
	out		[rVDPData],a
	dec		bc
	ld		a,b
	or		c
	jr		nz,-
	
	ret
	
; INPUT: hl = data pointer, de = VRAM destination, bc = size
VDPCopy:
	ld		a,e
	out		[rVDPAddr],a
	ld		a,d
	and		$3f
	or		VDP_WriteVRAM
	out		[rVDPAddr],a
	
-	ld		a,[hl]
	inc		hl
	WaitForVDP
	out		[rVDPData],a
	dec		bc
	ld		a,b
	or		c
	jr		nz,-
	ret
	
; INPUT: hl = palette pointer
LoadBGPal:
	xor		a
	jr		DoLoadPal
	
; INPUT: hl = palette pointer
LoadSpritePal:
	ld		a,16
	; fall through to DoLoadPal

; HL = palette pointer, E = palette offset
DoLoadPal:
	out		[rVDPAddr],a
	ld		a,VDP_WritePal
	out		[rVDPAddr],a
	ld		b,$10
-	ld		a,[hl]
	inc		hl
	out		[rVDPData],a
	WaitForVDP
	djnz	-
	ret

; INPUT: hl = string offset, de = VRAM address to print to
PrintString:
	ld		a,e
	out		[rVDPAddr],a
	ld		a,d
	and		$3f
	or		%01000000
	out		[rVDPAddr],a
-	ld		a,[hl]
	and		a
	ret		z	; return if terminator byte reached
	inc		hl
	sub		' '	; uncomment if font is loaded to start of VRAM
	out		[rVDPData],a
	WaitForVDP
	xor		a
	out		(rVDPData),a
	jr		-
	
; ================================================================
; RST handlers
; ================================================================

; INPUT: hl = destination, bc = size, e = byte
FillRAM:
	ld		[hl],e
	inc		hl
	dec		bc
	ld		a,b
	or		c
	jr		nz,FillRAM
	ret

; ================================================================
; Graphics data
; ================================================================

Font:			.incbin	"gfx/font.4bpp"
Font_End
	
TextPal:
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	0,0,0
	color	2,2,3
	color	3,3,3

; ================================================================
; DevSound routines
; ================================================================

.include "DevSound.asm"

; Insert your music files here.
.include	"music/Victory.sng"