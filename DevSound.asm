; ================================================================
; DevSound sound driver for SEGA Master System by DevEd
; ================================================================

.def	EnableYM		0	; Set to 1 to enable YM (FM unit only!)
.def	EnableStereo	0	; Set to 1 to enable stereo (Game Gear only!)

; ---- Macros ----

; define instrument
.macro	dins
ins_\1:	.dw	@vol,@arp
.endm

; define instrument + reuse volume table
.macro	dinsvol
ins_\1:	.dw \2,@arp
.endm

; define instrument + reuse arp table
.macro	dinsarp
ins_\1:	.dw	@vol,\2
.endm

.macro	dbw
	.db	\1
	.dw	\2
.endm

.macro	Drum
	.db	cFixedIns
	.db	\2
	.dw	ins_\1
.endm

; ---- RAM defines ----


_TrackPtr	=	0
_VolPtr		=	2
_ArpPtr		=	4
_Note		=	6
_Tick		=	7
_Volume		=	8
_VolScale	=	9
_EchoPos	=	10
_EchoDelay	=	11
_VibTick	=	12
_VibParams	=	13
_Arpeggio	=	14
_ArpTick	=	15

.ramsection "DevSound variables" slot 1 returnorg
	DS_RAMStart			ds	0
	
	DS_MusicPlaying		db	; 1
	DS_SFXPlaying		db	; 2
	DS_Tick				db	; 3
	DS_Timer			db	; 4
	DS_SongSpeed1		db	; 5
	DS_SongSpeed2		db	; 6
	DS_CH1LoopCount		db	; 7
	DS_CH2LoopCount		db	; 8
	DS_CH3LoopCount		db	; 9
	DS_CH4LoopCount		db	; 10
	DS_CH1RetPtr		dw	; 12
	DS_CH2RetPtr		dw	; 14
	DS_CH3RetPtr		dw	; 16
	DS_CH4RetPtr		dw	; 18
	DS_SongNamePtr		dw	; 20
	DS_CH1ArpSpeed		db	; 21
	DS_CH2ArpSpeed		db	; 22
	DS_CH3ArpSpeed		db	; 23
	DS_CH4ArpSpeed		db	; 24 (not used)
	DS_CH1InsPtr		dw	; 26
	DS_CH2InsPtr		dw	; 28
	DS_CH3InsPtr		dw	; 30
	DS_CH4InsPtr		dw	; 32
	
	DS_PSG1				ds	0
	DS_PSG1_TrackPtr	dw	; 2
	DS_PSG1_VolPtr		dw	; 4
	DS_PSG1_ArpPtr		dw	; 6
	DS_PSG1_Note		db	; 7
	DS_PSG1_Tick		db	; 8
	DS_PSG1_Volume		db	; 9
	DS_PSG1_VolScale	db	; 10
	DS_PSG1_EchoPos		db	; 11
	DS_PSG1_EchoDelay	db	; 12
	DS_PSG1_VibTick		db	; 13
	DS_PSG1_VibParams	db	; 14
	DS_PSG1_Arpeggio	db	; 15
	DS_PSG1_ArpTick		db	; 16

	DS_PSG2				ds	0
	DS_PSG2_TrackPtr	dw	; 2
	DS_PSG2_VolPtr		dw	; 4
	DS_PSG2_ArpPtr		dw	; 6
	DS_PSG2_Note		db	; 7
	DS_PSG2_Tick		db	; 8
	DS_PSG2_Volume		db	; 9
	DS_PSG2_VolScale	db	; 10
	DS_PSG2_EchoPos		db	; 11
	DS_PSG2_EchoDelay	db	; 12
	DS_PSG2_VibTick		db	; 13
	DS_PSG2_VibParams	db	; 14
	DS_PSG2_Arpeggio	db	; 15
	DS_PSG2_ArpTick		db	; 16
	
	DS_PSG3				ds	0
	DS_PSG3_TrackPtr	dw	; 2
	DS_PSG3_VolPtr		dw	; 4
	DS_PSG3_ArpPtr		dw	; 6
	DS_PSG3_Note		db	; 7
	DS_PSG3_Tick		db	; 8
	DS_PSG3_Volume		db	; 9
	DS_PSG3_VolScale	db	; 10
	DS_PSG3_EchoPos		db	; 11
	DS_PSG3_EchoDelay	db	; 12
	DS_PSG3_VibTick		db	; 13
	DS_PSG3_VibParams	db	; 14
	DS_PSG3_Arpeggio	db	; 15
	DS_PSG3_ArpTick		db	; 16

	DS_PSG4				ds	0
	DS_PSG4_TrackPtr	dw	; 2
	DS_PSG4_VolPtr		dw	; 4
	DS_PSG4_ArpPtr		dw	; 6
	DS_PSG4_Note		db	; 7
	DS_PSG4_Tick		db	; 8
	DS_PSG4_Volume		db	; 9
	DS_PSG4_VolScale	db	; 10
	DS_PSG4_EchoPos		db	; 11	; not used
	DS_PSG4_EchoDelay	db	; 12	; not used
	DS_PSG4_VibTick		db	; 13	; not used
	DS_PSG4_VibParams	db	; 14	; not used
	DS_PSG4_Arpeggio	db	; 15	; not used
	DS_PSG4_ArpTick		db	; 16	; not used
	
	; TODO: YM stuff
	
	DS_PSG1_EchoBuffer	ds	32
	DS_PSG2_EchoBuffer	ds	32
	DS_PSG3_EchoBuffer	ds	32
	
	DS_TempSP			dw	; break glass in case of emergency
	DS_TempFreq1		dw
	DS_TempFreq2		dw
	DS_TempFreq3		dw
	DS_TempFreq4		dw
	DS_TempByte			db
	
	DS_RAMEnd			ds	0
.ends

; ---- Start of code ----

DS_PlaySong:	jp	DevSound_PlaySong
DS_Update:		jp	DevSound_Update
DS_StopMusic:	jp	DevSound_StopMusic
	
.db	"DevSound-SMS by DevEd | email: deved8@gmail.com"

; --------------------------------

; Initialize DevSound.
; Call this once during your init
; code, before playing music.
; INPUT: none
; OUTPUT: none
; DESTROYS:	a, bc

DevSound_Init:
	push	hl
	; clear sound driver RAM
	ld		hl,DS_RAMStart
	ld		bc,(DS_RAMEnd-DS_RAMStart)+$ff
	xor		a
-	ld		[hl],a
	inc		hl
	; thanks to baze from the sizecoding discord for this trick!
	dec		bc
	inc		b
	djnz	-
	; initialize the PSG
	call	DevSound_ClearPSG
	; initialize stereo (Game Gear only!)
	.if EnableStereo == 1
		ld		a,%11111111
		out		[rStereo],a
	.endif
	; initialize all channels to maximum volume
	ld		a,$f
	ld		[DS_PSG1_VolScale],a
	ld		[DS_PSG2_VolScale],a
	ld		[DS_PSG3_VolScale],a
	ld		[DS_PSG4_VolScale],a
	pop		hl
	ret

; --------------------------------

; Call this once in order to start
; playing a song.
; INPUT: hl = pointer to song
; OUTPUT: none
; DESTROYS: a, de, hl
DevSound_PlaySong:
	call	DevSound_Init
	; skip first 5 bytes for now
	; TODO: Verify that first four bytes contain string "DSNG"
	ld		de,5
	add		hl,de
	; get track pointers
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG1_TrackPtr],a
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG1_TrackPtr+1],a
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG2_TrackPtr],a
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG2_TrackPtr+1],a
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG3_TrackPtr],a
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG3_TrackPtr+1],a
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG4_TrackPtr],a
	ld		a,[hl]
	inc		hl
	ld		[DS_PSG4_TrackPtr+1],a
	; get song speed
	ld		a,[hl]
	inc		hl
	ld		[DS_SongSpeed1],a
	ld		a,[hl]
	inc		hl
	ld		[DS_SongSpeed2],a
	inc		hl	; skip reserved byte
	; set song name pointer
	ld		[DS_SongNamePtr],hl
	; initialize tick counts to 1
	ld		a,1
	ld		[DS_PSG1_Tick],a
	ld		[DS_PSG2_Tick],a
	ld		[DS_PSG3_Tick],a
	ld		[DS_PSG4_Tick],a
	ld		[DS_Timer],a
	; set "music playing" flags
	or		$f0
	ld		[DS_MusicPlaying],a
	ret

; --------------------------------

; Stop playing music.
; INPUT: none
; OUTPUT: none
; DESTROYS: none
DevSound_StopMusic:
	push	af
	push	hl
	push	bc
	; initialize all pointers to dummy values
	ld		hl,DummyChannel
	ld		[DS_PSG1_TrackPtr],hl
	ld		[DS_PSG2_TrackPtr],hl
	ld		[DS_PSG3_TrackPtr],hl
	ld		[DS_PSG4_TrackPtr],hl
	ld		hl,DummyTable
	ld		[DS_PSG1_VolPtr],hl
	ld		[DS_PSG2_VolPtr],hl
	ld		[DS_PSG3_VolPtr],hl
	ld		[DS_PSG4_VolPtr],hl
	ld		[DS_PSG1_ArpPtr],hl
	ld		[DS_PSG2_ArpPtr],hl
	ld		[DS_PSG3_ArpPtr],hl
	ld		hl,DummySongName
	ld		[DS_SongNamePtr],hl
	; clear "music playing" flag
	xor		a
	ld		[DS_MusicPlaying],a
	; clear all PSG registers
	call	DevSound_ClearPSG
	pop		bc
	pop		hl
	pop		af
	ret

; --------------------------------

; Clear all PSG registers.
; INPUT: none
; OUTPUT: none
; DESTROYS: a, bc

DevSound_ClearPSG:
	ld		c,rPSG
	; frequency
	ld		a,$3f
	ld		b,PSGCmd_Frequency | PSG_CH1 | $f
	out		[c],b
	out		[c],a
	ld		b,PSGCmd_Frequency | PSG_CH2 | $f
	out		[c],b
	out		[c],a
	ld		b,PSGCmd_Frequency | PSG_CH3 | $f
	out		[c],b
	out		[c],a
	; volume
	ld		a,PSGCmd_Volume | PSG_CH1 | $f
	out		[c],a
	ld		a,PSGCmd_Volume | PSG_CH2 | $f
	out		[c],a
	ld		a,PSGCmd_Volume | PSG_CH3 | $f
	out		[c],a
	ld		a,PSGCmd_Volume | PSG_CH4 | $f
	out		[c],a
	ret
	
; --------------------------------

; Call this once every frame in
; order to update sound registers.
; INPUT: none
; OUTPUT: none
DevSound_Update:
	ld		[DS_TempSP],sp
	push	af
	ld		a,[DS_MusicPlaying]
	and		a	; is music playing?
	jr		nz,@doupdate
	pop		af
	ret
@doupdate
	ld		a,[DS_Timer]
	dec		a
	jr		z,+
	ld		[DS_Timer],a
	call	DS_UpdateRegisters
	pop		af
	ret
+	ld		[DS_Timer],a
	ld		a,[DS_Tick]
	inc		a
	ld		[DS_Tick],a
	; reset timer
	rra		; get low bit
	jr		nc,@eventick
@oddtick
	ld		a,[DS_SongSpeed1]
	jr		@settimer
@eventick
	ld		a,[DS_SongSpeed2]
@settimer
	ld		[DS_Timer],a
	push	hl
	ld		a,[DS_MusicPlaying]
	rla	; is channel 1 playing?
	call	c,DS_UpdateCH1
	rla	; is channel 2 playing?
	call	c,DS_UpdateCH2
	rla	; is channel 3 playing?
	call	c,DS_UpdateCH3
	rla	; is channel 4 playing?
	call	c,DS_UpdateCH4

	call	DS_UpdateRegisters
	pop		hl
	pop		af
	ret

DS_UpdateCH1:
	ld		hl,DS_PSG1_TrackPtr
	jr		DS_UpdateChannel

DS_UpdateCH2:
	ld		hl,DS_PSG2_TrackPtr
	jr		DS_UpdateChannel
	
DS_UpdateCH3:
	ld		hl,DS_PSG3_TrackPtr
	jr		DS_UpdateChannel
	
DS_UpdateCH4:
	ld		hl,DS_PSG4_TrackPtr
	; fall through
	
DS_UpdateChannel:
	push	af
	push	bc
	push	de
	push	ix
	push	iy

	; get channel ID
	ld		a,l
	sub		DS_PSG1-DS_RAMStart
	rra		; /2	
	rra		; /4	
	rra		; /8	
	rra		; /16
	ld		e,a
	; get tick
@tickproc
	ld		a,>DS_RAMStart
	ld		ixh,a
	ld		a,l
	ld		ixl,a
	ld		a,[ix+_Tick]
	dec		a
	jr		z,@doupdate
	ld		[ix+_Tick],a
	jr		@doneupdate
	
@doupdate
	ld		l,[ix+_TrackPtr]
	ld		h,[ix+(_TrackPtr+1)]
@getbyte
	ld		a,[hl]
	bit		7,a
	jr		nz,@cmdproc
@noteproc
	; set note
	cp		nRest
	jr		z,@isrest
	cp		nEcho
	jr		nz,@isnote
@isecho
	; TODO
	; treated as rest for now
@isrest
	; TODO
	; fall through for now
@isnote
	ld		[ix+_Note],a
	inc		hl
	; set tick
	ld		a,[hl]
	ld		[ix+_Tick],a
@resetnote	; start here after cFix
	; write pointer back
	inc		hl
	ld		[ix+_TrackPtr],l
	ld		[ix+(_TrackPtr+1)],h
	; reset instrument
	ld		hl,DS_CH1InsPtr
	ld		d,0
	add		hl,de
	add		hl,de
	ld		a,[hl]
	inc		hl
	ld		h,[hl]
	ld		l,a
	ld		a,[hl]
	inc		hl
	ld		[ix+_VolPtr],a
	ld		a,[hl]
	inc		hl
	ld		[ix+(_VolPtr+1)],a
	ld		a,[hl]
	inc		hl
	ld		[ix+_ArpPtr],a
	ld		a,[hl]
	inc		hl
	ld		[ix+(_ArpPtr+1)],a
	jr		@doneupdate
	
@cmdproc
	; TODO
	and		$7f
	cp		(DS_CmdProcTable@end-DS_CmdProcTable)/2	; is command valid?
	jr		nc,@panic								; if not, panic!!!!
	inc		hl
	push	hl
	add		a
	ld		c,a
	ld		b,0
	ld		hl,DS_CmdProcTable
	add		hl,bc
	ld		a,[hl]
	inc		hl
	ld		h,[hl]
	ld		l,a
	jp		hl
	
@doneupdate
	pop		iy
	pop		ix
	pop		de
	pop		bc
	pop		af
	ret

@panic
	; oh god oh fuck
	ld		hl,DS_TempSP
	ld		a,[hl]
	inc		l
	ld		h,[hl]
	ld		l,a
	ld		sp,hl
	jp		DevSound_StopMusic
	
DS_CmdProcTable:
	.dw		@setInstrument	; Set instrument
	.dw		@setLoopCount	; Set loop count
	.dw		@goto			; Set track pointer
	.dw		@callBlock		; Save current pointer and set track pointer
	.dw		@setVolume		; Set volume level
	.dw		@setArpeggio	; Set arpeggio
	.dw		@setVibrato		; Set vibrato
	.dw		@setEcho		; Set echo delay
	.dw		@endBlock		; Restore track pointer after cCall
	.dw		@endChannel		; End track
	.dw		@fixed			; Set instrument and play note A-1 with given length 
	.dw		@doLoop			; Decrement loop count and set track pointer if loop count is non-zero
	.dw		@setSpeed		; Set song speed
@end

@setInstrument
	pop		hl
	; get instrument pointer
	push	hl
	ld		a,[hl]
	inc		hl
	ld		h,[hl]
	ld		l,a
	; store instrument pointer
	ld		d,0				; de = channel ID
	ld		iy,DS_CH1InsPtr
	add		iy,de
	add		iy,de			; add channel ID x2
	ld		[iy+0],l		; store low byte
	ld		[iy+1],h		; store high byte
	pop		hl
	inc		hl
	inc		hl
	jp		DS_UpdateChannel@getbyte
@setLoopCount
	pop		hl
	; get loop count
	ld		a,[hl]
	; store loop count
	ld		d,0				; de = channel ID
	ld		iy,DS_CH1LoopCount
	add		iy,de
	ld		[iy+0],a		; store low byte
	inc		hl
	; done
	jp		DS_UpdateChannel@getbyte
@goto
	pop		hl
	; get pointer
@dogoto
	ld		a,[hl]
	inc		hl
	ld		h,[hl]
	ld		l,a
	; set pointer
	ld		[ix+_TrackPtr],l
	ld		[ix+(_TrackPtr+1)],h
	; done
	jp		DS_UpdateChannel@getbyte
@callBlock
	pop		hl
	push	hl
	; add 2 to pointer
	inc		hl
	inc		hl
	; store return pointer
	ld		d,0				; de = channel ID
	ld		iy,DS_CH1RetPtr
	add		iy,de
	add		iy,de			; add channel ID x2
	ld		[iy+0],l		; store low byte
	ld		[iy+1],h		; store high byte
	pop		hl
	jr		@dogoto	; last part already covered by @goto
@setVolume
	pop		hl
	ld		a,[hl]
	ld		[ix+_VolScale],a
	inc		hl
	; done
	jp		DS_UpdateChannel@getbyte
@setArpeggio
	pop		hl
	ld		a,[hl]
	inc		hl
	; store speed
	ld		d,0				; de = channel ID
	ld		iy,DS_CH1ArpSpeed
	add		iy,de
	add		iy,de			; add channel ID x2
	ld		[iy+0],a		; store byte
	ld		a,[hl]
	inc		hl
	ld		[ix+_Arpeggio],a
	; store parameters
	; done
	jp		DS_UpdateChannel@getbyte
@setVibrato
	pop		hl
	; store delay
	ld		a,[hl]
	ld		[ix+_VibTick],a
	inc		hl
	; store parameters
	ld		a,[hl]
	ld		[ix+_VibParams],a
	inc		hl
	; done
	jp		DS_UpdateChannel@getbyte
@setEcho
	pop		hl
	; set delay
	ld		a,[hl]
	ld		[ix+_EchoDelay],a
	inc		hl
	; done
	jp		DS_UpdateChannel@getbyte
@endBlock
	pop		hl
	; get return pointer
	ld		hl,DS_CH1RetPtr
	ld		d,0
	add		hl,de
	add		hl,de
	ld		a,[hl]
	inc		l
	ld		h,[hl]
	ld		l,a
	; hl = return pointer
	; done
	jp		DS_UpdateChannel@getbyte
@endChannel
	ld		a,e
	ld		hl,@@bits
	add		l
	ld		l,a
	jr		nc,+	; have we crossed a page boundary?
	inc		h		; if yes, compensate
+	ld		d,[hl]
	ld		a,[DS_MusicPlaying]
	xor		d
	ld		[DS_MusicPlaying],a
	pop		hl
	jp		DS_UpdateChannel@doneupdate
@@bits
	.db		%10000000,%01000000,%00100000,%00010000
@fixed
	pop		hl
	; set note
	xor		a
	ld		[ix+_Note],a
	; set tick
	ld		a,[hl]
	ld		[ix+_Tick],a
	inc		hl
	; set instrument
	push	hl
	ld		a,[hl]
	inc		hl
	ld		h,[hl]
	ld		l,a
	; store instrument pointer
	ld		d,0				; de = channel ID
	ld		iy,DS_CH1InsPtr
	add		iy,de
	add		iy,de			; add channel ID x2
	ld		[iy+0],l		; store low byte
	ld		[iy+1],h		; store high byte
	pop		hl
	inc		hl
	jp		DS_UpdateChannel@resetnote
@doLoop
	pop		hl
	; get loop count
	ld		d,0				; de = channel ID
	push	hl
	ld		hl,DS_CH1LoopCount
	add		hl,de			; add channel ID
	dec		[hl]
	jp		nz,@goto
@noloop
	pop		hl
	inc		hl
	inc		hl
	jp		DS_UpdateChannel@getbyte
@setSpeed
	pop		hl
	ld		a,[hl]
	ld		[DS_SongSpeed1],a
	inc		hl
	ld		a,[hl]
	ld		[DS_SongSpeed2],a
	inc		hl
	jp		DS_UpdateChannel@getbyte
	
; --------------------------------

DS_UpdateRegisters:
	ld		a,[DS_MusicPlaying]
	ld		hl,DS_PSG1
	ld		bc,0
	rla
	call	c,DS_UpdateChannelRegisters
	inc		c
	rla
	call	c,DS_UpdateChannelRegisters
	inc		c
	rla
	call	c,DS_UpdateChannelRegisters
	inc		c
	rla
	call	c,DS_UpdateChannelRegisters
	ret

; bc = channel id
DS_UpdateChannelRegisters:
	push	af
	push	bc
	ld		hl,@volbytes
	add		hl,bc
	ld		e,[hl]

	ld		a,c
	ld		[DS_TempByte],a
	rl		c			; x2
	rl		c			; x4
	rl		c			; x8
	rl		c			; x16
	ld		ix,DS_PSG1
	add		ix,bc		; ix = pointer to RAM for current channel

	; run volume table
	ld		l,[ix+_VolPtr]
	ld		h,[ix+(_VolPtr+1)]
	; get byte
	ld		a,[hl]
	inc		hl
	cp		$ff
	jr		z,@skipvol
	cp		$fe
	jr		z,+
	; default case: write volume
	ld		[ix+_Volume],a
	jr		@donevol
+	ld		a,[hl]
	inc		a
	neg
	ld		c,a
	ld		b,$ff
	add		hl,bc
	ld		a,[hl]
	inc		hl
	ld		[ix+_Volume],a
	; fall through
@donevol
	ld		[ix+_VolPtr],l
	ld		[ix+(_VolPtr+1)],h
@skipvol
	; write volume	
	ld		a,[ix+_Volume]
	ld		b,a
	ld		a,[ix+_VolScale]
	sub		b
;	xor		$f
	or		e
	or		PSGCmd_Volume
	out		[rPSG],a

	; run arp table
	ld		l,[ix+_ArpPtr]
	ld		h,[ix+(_ArpPtr+1)]
	ld		a,[DS_TempByte]
	cp		3
	jr		z,DS_UpdateCH4Mode
	; get byte
	ld		a,[hl]
	inc		hl
	cp		$ff
	jr		z,@skiparp
	cp		$fe
	jr		z,+
	; default case: store arp value
	ld		e,a
	jr		@donearp
+	ld		a,[hl]
	inc		a
	neg
	ld		c,a
	ld		b,$ff
	add		hl,bc
	ld		a,[hl]
	inc		hl
	ld		e,a
	; fall through
@donearp
	ld		[ix+_ArpPtr],l
	ld		[ix+(_ArpPtr+1)],h
@skiparp

	ld		a,[ix+_Note]
	add		e
	ld		e,a
	ld		d,0

	; TODO: arpeggio effect

	; TODO: write to echo buffer

	ld		hl,DevSound_FreqTable
	add		hl,de
	add		hl,de
	ld		a,[hl]
	inc		hl
	ld		h,[hl]
	ld		l,a
	ld		a,[DS_TempByte]
	ld		c,a
	ld		b,0
	ld		iy,DS_TempFreq1
	add		iy,bc
	add		iy,bc
	ld		[iy+0],l
	ld		[iy+1],h

	; a = channel ID
	call	DS_WriteFrequency

	pop		bc
	pop		af
	ret


@volbytes
	.db	PSG_CH1,PSG_CH2,PSG_CH3,PSG_CH4

DS_UpdateCH4Mode
	; TODO
	; get byte
	ld		a,[hl]
	inc		hl
	cp		$ff
	jr		z,@skiparp
	cp		$fe
	jr		z,+
	; default case: store arp value
	ld		e,a
	jr		@donearp
+	ld		a,[hl]
	inc		a
	neg
	ld		c,a
	ld		b,$ff
	add		hl,bc
	ld		a,[hl]
	inc		hl
	; fall through
@donearp
	ld		[ix+_ArpPtr],l
	ld		[ix+(_ArpPtr+1)],h
@skiparp
	inc		a
	ld		e,a
	ld		a,[DS_PSG4_Note]
	cp		e
	jr		z,+				; don't rewrite if new value = old value (prevents phase reset)
	ld		a,e
	ld		[DS_PSG4_Note],a
	xor		$7
	or		%11100000
	out		[rPSG],a
+	pop		bc
	pop		af
	inc		c
	ret


; a = channel ID
DS_WriteFrequency:
	ld		hl,DS_TempByte
	and		a
	jr		z,@ch1
	dec		a
	jr		z,@ch2
	; default case: assume ch3
@ch3
	ld		de,[DS_TempFreq3]
	ld		[hl],e
	ld		a,d
	rrd
	or		PSGCmd_Frequency | PSG_CH3
	out		[rPSG],a
	ld		a,[hl]
	out		[rPSG],a
	ret
@ch2
	ld		de,[DS_TempFreq2]
	ld		[hl],e
	ld		a,d
	rrd
	or		PSGCmd_Frequency | PSG_CH2
	out		[rPSG],a
	ld		a,[hl]
	out		[rPSG],a
	ret
@ch1
	ld		de,[DS_TempFreq1]
	ld		[hl],e
	ld		a,d
	rrd
	or		PSGCmd_Frequency | PSG_CH1
	out		[rPSG],a
	ld		a,[hl]
	out		[rPSG],a
	ret
  
; --------------------------------

; Frequency table
; Taken from FamiTracker
DevSound_FreqTable:
	;		  C    C#   D    D#   E    F    F#   G    G#   A    A#   B
	.dw		                                             $3F8,$3BF,$389	; 1
	.dw		$356,$326,$2F9,$2CE,$2A6,$280,$25C,$23A,$21A,$1FB,$1DF,$1C4	; 2
	.dw		$1AB,$193,$17C,$167,$152,$13F,$12D,$11C,$10C,$0FD,$0EF,$0E1	; 3
	.dw		$0D5,$0C9,$0BD,$0B3,$0A9,$09F,$096,$08E,$086,$07E,$077,$070	; 4
	.dw		$06A,$064,$05E,$059,$054,$04F,$04B,$046,$042,$03F,$03B,$038	; 5
	.dw		$034,$031,$02F,$02C,$02a,$027,$025,$023,$021,$01F,$01D,$01B	; 6
	.dw		$01A,$018,$017,$015,$014,$013,$012,$011,$010,$00F,$00E,$00D	; 7 (only C-7 used directly)
	.dw		$00c,$00b,$00a,$009,$008,$007,$006,$005,$004,$003,$002,$001	; 8 (DO NOT USE)

; --------------------------------

; Note values

nA_1	=	0	; lowest possible note
nAs1	=	1
nB_1	=	2
nC_2	=	3
nCs2	=	4
nD_2	=	5
nDs2	=	6
nE_2	=	7
nF_2	=	8
nFs2	=	9
nG_2	=	10
nGs2	=	11
nA_2	=	12
nAs2	=	13
nB_2	=	14
nC_3	=	15
nCs3	=	16
nD_3	=	17
nDs3	=	18
nE_3	=	19
nF_3	=	20
nFs3	=	21
nG_3	=	22
nGs3	=	23
nA_3	=	24
nAs3	=	25
nB_3	=	26
nC_4	=	27
nCs4	=	28
nD_4	=	29
nDs4	=	30
nE_4	=	31
nF_4	=	32
nFs4	=	33
nG_4	=	34
nGs4	=	35
nA_4	=	36
nAs4	=	37
nB_4	=	38
nC_5	=	39
nCs5	=	40
nD_5	=	41
nDs5	=	42
nE_5	=	43
nF_5	=	44
nFs5	=	45
nG_5	=	46
nGs5	=	47
nA_5	=	48
nAs5	=	49
nB_5	=	50
nC_6	=	51
nCs6	=	52
nD_6	=	53
nDs6	=	54
nE_6	=	55
nF_6	=	56
nFs6	=	57
nG_6	=	58
nGs6	=	59
nA_6	=	60
nAs6	=	61
nB_6	=	62
nC_7	=	63 ; highest possible note wihout transposition

nRest	=	64
nEcho	=	65
nFix	=	$80	; only used for arpeggio sequences

; --------------------------------

; Command values
cSetInstrument	=	$80
cSetLoopCount	=	$81
cGoto			=	$82
cCallBlock		=	$83
cSetVolume		=	$84
cSetArpeggio	=	$85
cSetVibrato		=	$86
cSetEchoDelay	=	$87
cEndBlock		=	$88
cEndChannel		=	$89
cFixedIns		=	$8a
cGotoLoop		=	$8b
cSetSpeed		=	$8c

; Command aliases
cIns			=	cSetInstrument
cLoopCount		=	cSetLoopCount
cCall			=	cCallBlock
cVol			=	cSetVolume
cArp			=	cSetArpeggio
cVib			=	cSetVibrato
cEcho			=	cSetEchoDelay
cRet			=	cEndBlock
cEnd			=	cEndChannel
cLoop			=	cGotoLoop
cSpeed			=	cSetSpeed

; --------------------------------

; Global instruments

dins	Kick
@vol	.db	15,15,15,8,5,2,0,$ff
@arp	.db	0,0,0,2,$fe,1

dins	Hat
@vol	.db	11,9,0,$ff
@arp	.db	2,$fe,1

dins	Snare
@vol	.db	15,15,14,14,13,13,12,12,11,11,10,9,9,8,7,7,6,5,5,4,3,2,1,0,$ff
@arp	.db	2,1,0,2,$fe,1

dins	Cymbal
@vol	.db	15,14,14,13,13,12,12,12,11,11,11,10,10,10,10,9,9,9,9,8,8,8,8,7,7,7,7,6,6,6,5,5,5,5,5,5,4,$fe,1
@arp	.db	2,2,1,1,2,$fe,1

; --------------------------------

; Dummy tables
DummyTable:
DummyChannel:	.db	$ff
DummySongName:	.db	"NO SONG         ",0
