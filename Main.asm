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

; USAGE: coord x,y
; x = X coordinate
; y = Y coordinate
; EXAMPLE: coord 5,6 >> de = VDP offset for given coordinates
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
.macro	lbhl
	ld	hl,(\1 << 8) | \2
.endm

; USAGE: SetVDP register, data
; reg = VDP register (see SMS.inc for a list of registers)
; data = obvious
; EXAMPLE: SetVDP rVDPBorderColor,8 >> send command to change border color to VDP
.macro SetVDP 
	ld	de,((VDP_WriteReg | \1) << 8) | \2
	rst	$30
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
	sys_CurrentFrame	db	; frame counter
	sys_P1_BtnsHeld		db	; P1 buttons
	sys_P1_BtnsLast		db	; used to get newly pressed buttons

	MenuPos				db	; current menu position
	MenuMax				db	; number of menu items
	MenuLast			db	; last menu position
.ends

; ================================================================
; Start of actual code
; ================================================================

	.org	$00
EntryPoint:
	di
	im		1
	; Initialize SEGA mapper
	ld		de,$fffc
	ld		hl,InitValues
	ld		bc,4
	ldir
	jr		Start
InitValues:		.db	0,0,1,2
	
; --------------------------------

	.org	$30
.SetVDP:
	ld		c,rVDPAddr
	out		[c],e
	out		[c],d
	ret

	.org	$38
; Interrupt handler

HandleIRQ:
	push	af
	in		a,[rVDPStatus]
	pop		af
	reti

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

	; clear memory
	ld		hl,$c000
	ld		bc,$2000+255
	xor		a
-	ld		[hl],a
	inc		hl
	dec		bc
	inc		b
	djnz	-
	
	call	ClearVRAM
	ld		hl,TextPal
	call	LoadBGPal
	
	ld		hl,Font
	ld		bc,Font_End-Font
	ld		de,0
	call	VDPCopy
	
	; devsound "banner"
	ld		hl,strDevSound
	coord	3,1
	call	PrintString
	
	; now playing
	ld		hl,strNowPlaying
	coord	1,3
	call	PrintString

	; first song
	coord	3,6
	ld		hl,strSong1
	call	PrintString
	; second song
	coord	3,7
	ld		hl,strSong2
	call	PrintString

	ld		hl,strControls1
	coord	1,19
	call	PrintString
	ld		hl,strControls2
	coord	1,20
	call	PrintString
	ld		hl,strControls3
	coord	1,21
	call	PrintString
	ld		hl,strControls4
	coord	1,22
	call	PrintString
	
	ld		a,1	; number of songs
	ld		[MenuMax],a
	ld		[MenuLast],a

	; To start playing a song:
	; 1. Load HL with a pointer to the song's header
	; 2. Call DS_PlaySong
	ld		hl,mus_Victory
	call	DS_PlaySong

MainLoop:
	; protip: don't do this
	ld		bc,1601+255
-	dec		bc
	inc		b
	djnz	-

	xor		a
	out		[rVDPAddr],a
	ld		a,VDP_WritePal
	out		[rVDPAddr],a
	lcolor	1,0,0
	out		[rVDPData],a

	call	DS_Update	; do this once per frame to update music

	xor		a
	out		[rVDPAddr],a
	ld		a,VDP_WritePal
	out		[rVDPAddr],a
	lcolor	0,0,0
	out		[rVDPData],a

	ld		hl,sys_CurrentFrame
	inc		[hl]
	
	; Print song name.
	; DS_SongNamePtr contains a pointer to a 16-byte null-terminated
	; string containing the name of the song. Useful if you ever
	; need to print the name of the currently playing song (e.g. on
	; a sound test screen).
	ld		hl,[DS_SongNamePtr]
	coord	1,4
	call	PrintString

	call	ReadInput
	; TODO: selection menu

	ld		a,[sys_P1_BtnsHeld]
	ld		b,a
	ld		a,[sys_P1_BtnsLast]
	cp		b
	jp		z,@skip

	ld		a,b

	bit		bPort1_Up,a
	jr		nz,@cursordown
	bit		bPort1_Down,a
	jr		nz,@cursorup
	bit		bPort1_Btn1,a
	jr		nz,@playsong
	bit		bPort1_Btn2,a
	jr		z,@skip
@stopsong
	; Use DS_StopMusic to stop music playback.
	call	DS_StopMusic
	jr		@skip
@playsong
	ld		a,[MenuPos]
	add		a
	ld		hl,SongPointers
	add		l
	ld		l,a
	jr		nc,+
	inc		h
+	ld		a,[hl]
	inc		l
	ld		h,[hl]
	ld		l,a
	call	DS_PlaySong
	jr		@skip
@cursordown
	ld		a,[MenuPos]
	ld		[MenuLast],a
	dec		a
	cp		$ff
	jr		nz,+
	ld		a,[MenuMax]
+	ld		[MenuPos],a
	jr		@skip
@cursorup
	ld		a,[MenuPos]
	ld		[MenuLast],a
	inc		a
	ld		b,a
	ld		a,[MenuMax]
	cp		b
	ld		a,b
	jr		nc,+
	xor		a
+	ld		[MenuPos],a
	; fall through

@skip
	; draw cursor
	coord	1,6
	ld		a,[MenuPos]
	ld		hl,0
	ld		l,a
	ld		h,0
	add		hl,hl	; x2
	add		hl,hl	; x4
	add		hl,hl	; x8
	add		hl,hl	; x16
	add		hl,hl	; x32
	add		hl,hl	; x64
	add		hl,de
	ex		de,hl
	ld		a,e
	out		[rVDPAddr],a
	ld		a,d
	and		$3f
	or		%01000000
	out		[rVDPAddr],a
	ld		a,'>'-' '
	out		[rVDPData],a
	WaitForVDP
	xor		a
	out		(rVDPData),a

	; draw blank tile at previous cursor position
	coord	1,6
	ld		a,[MenuLast]
	ld		hl,0
	ld		l,a
	ld		h,0
	add		hl,hl	; x2
	add		hl,hl	; x4
	add		hl,hl	; x8
	add		hl,hl	; x16
	add		hl,hl	; x32
	add		hl,hl	; x64
	add		hl,de
	ex		de,hl
	ld		a,e
	out		[rVDPAddr],a
	ld		a,d
	and		$3f
	or		%01000000
	out		[rVDPAddr],a
	xor		a
	out		[rVDPData],a
	WaitForVDP
	xor		a
	out		(rVDPData),a
	
@wait
	in		a,rVDPStatus
	bit		bVDPStatus_VBlank,a
	jr		z,@wait
	; VBlank operations go here	
	jp		MainLoop

strDevSound:	.db	"DevSound SMS v0.1 by DevEd",0
strNowPlaying:	.db	"Now playing:",0
strSong1:		.db	"Demo song 1",0
strSong2:		.db	"Demo song 2",0
strControls1:	.db	"Controls:",0
strControls2:	.db "D-pad  . . . . . . Select song",0
strControls3:	.db	"I  . . . . . . . . . Play song",0
strControls4:	.db	"II . . . . . . . . . Stop song",0

SongPointers:
	.dw		mus_Victory
	.dw		mus_InsertTitle
@end

; --------------------------------

; Input handler
; Destroys: a, bc, hl
ReadInput:
	ld		a,[sys_P1_BtnsHeld]
	ld		[sys_P1_BtnsLast],a
	; player 1
	in		a,[rIOPortAB]
	cpl
	ld		c,a
	and		%00111111	; xx21RLDU
	ld		[sys_P1_BtnsHeld],a
	ret

; --------------------------------
	
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
.include	"music/InsertTitle.sng"