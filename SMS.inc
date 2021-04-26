; Sega Master System + Game Gear hardware defines

.smstag
.computesmschecksum

.rombankmap
	bankstotal	1
	banksize	$8000
	banks		1
.endro

.memorymap
	defaultslot	0
	slotsize	$8000
	slot 0		$0000	; ROM
	slotsize	$2000
	slot 1		$c000	; Work RAM
.endme

; ================================================================
; System registers
; ================================================================

rMemCtrl				=	$3e	; do not use, the BIOS takes care of this
rIOCtrl					=	$3f
rVCnt					=	$7e
rHCnt					=	$7f
rVDPData				=	$be
rVDPAddr				=	$bf
rVDPStatus				=	$bf
rIOPortAB				=	$dc
rIOPortBC				=	$dd

; ================================================================
; Sound registers
; ================================================================

rPSG					=	$7f
rStereo					=	$06	; Game Gear only!

; --------------------------------

; The following registers are only available on a Mark III with FM sound unit!
rYMLatch				=	$F0
rYMData					=	$F1
rYMAvailable			=	$F2	; use bit 0 to detect presence of FM sound unit

; custom patch data
rYMModulatorCtrl		=	$00
rYMTotalLevel			=	$02
rYMModulatorKS			=	$02
rYMModulatorAD			=	$04
rYMModulatorSR			=	$06
rYMCarrierCtrl			=	$01
rYMCarrierKS			=	$03
rYMCarrierAD			=	$05
rYMCarrierSR			=	$07

; frequency registers
rYM1Freq				=	$10
rYM2Freq				=	$11
rYM3Freq				=	$12
rYM4Freq				=	$13
rYM5Freq				=	$14
rYM6Freq				=	$15
rYM7Freq				=	$16
rYM8Freq				=	$17
rYM9Freq				=	$18
; octave number (also contains high bit of frequency + sustain + key on)
rYM1Octave				=	$20
rYM2Octave				=	$21
rYM3Octave				=	$22
rYM4Octave				=	$23
rYM5Octave				=	$24
rYM6Octave				=	$25
rYM7Octave				=	$26
rYM8Octave				=	$27
rYM9Octave				=	$28

; patch registers
rYM1Patch				=	$30
rYM2Patch				=	$31
rYM3Patch				=	$32
rYM4Patch				=	$33
rYM5Patch				=	$34
rYM6Patch				=	$35
rYM7Patch				=	$36
rYM8Patch				=	$37
rYM9Patch				=	$38

rYM7PercVol				=	$36
rYM8PercVol				=	$37
rYM9PercVol				=	$38

; misc registers
rYMPercussion			=	$0e
rYMCtrl					=	$0f

; ================================================================
; VDP registers
; ================================================================

rVDPPort0				=	$00
rVDPPort1				=	$01
rVDPPort2				=	$02
rVDPPort3				=	$03	; unused
rVDPPort4				=	$04	; unused
rVDPPort5				=	$05
rVDPPort6				=	$06
rVDPPort7				=	$07
rVDPPort8				=	$08
rVDPPort9				=	$09
rVDPPort10				=	$0a
rVDPPort11				=	$0b	; unused
rVDPPort12				=	$0c	; unused
rVDPPort13				=	$0d	; unused
rVDPPort14				=	$0e	; unused
rVDPPort15				=	$0f	; unused

rVDPFlags1				=	rVDPPort0
rVDPFlags2				=	rVDPPort1
rVDPScreenBase			=	rVDPPort2
rVDPSpriteBase			=	rVDPPort5
rVDPTileBase			=	rVDPPort6
rVDPBorderColor			=	rVDPPort7
rVDPScrollX				=	rVDPPort8
rVDPScrollY				=	rVDPPort9
rVDPScanlineInt			=	rVDPPort10

; ================================================================
; rIOCtrl constants
; ================================================================

bPortA_TRDir			=	0	; 0 = output, 1 = input
bPortA_THDir			=	1	; 0 = output, 1 = input
bPortB_TRDir			=	2	; 0 = output, 1 = input
bPortB_THDir			=	3	; 0 = output, 1 = input
bPortA_TROut			=	4	; 0 = low, 1 = high
bPortA_THOut			=	5	; 0 = low, 1 = high
bPortB_TROut			=	6	; 0 = low, 1 = high
bPortB_THOut			=	7	; 0 = low, 1 = high

; ================================================================
; rVDPStatus constants
; ================================================================

bVDPStatus_VBlank		=	7	; set during VBlank
bVDPStatus_Scanline		=	6	; set on scanline IRQ
bVDPStatus_Collision	=	5	; set if two sprites are overlapping

; ================================================================
; rIOPortAB constants
; ================================================================

bPort1_Up				=	0	; 0 = pressed, 1 = not pressed
bPort1_Down				=	1	; 0 = pressed, 1 = not pressed
bPort1_Left				=	2	; 0 = pressed, 1 = not pressed
bPort1_Right			=	3	; 0 = pressed, 1 = not pressed
bPort1_Btn1				=	4	; 0 = pressed, 1 = not pressed
bPort1_Btn2				=	5	; 0 = pressed, 1 = not pressed
bPort2_BtnUp			=	6	; 0 = pressed, 1 = not pressed
bPort2_BtnDown			=	0	; 0 = pressed, 1 = not pressed

; ================================================================
; rIOPortBC constants
; ================================================================

bPort2_BtnLeft			=	0	; 0 = pressed, 1 = not pressed
bPort2_BtnRight			=	1	; 0 = pressed, 1 = not pressed
bPort2_Btn1				=	2	; 0 = pressed, 1 = not pressed
bPort2_Btn2				=	3	; 0 = pressed, 1 = not pressed
bPortC_Reset			=	4	; 0 = pressed, 1 = not pressed (SMS only!)
bPortC_ConsoleType		=	5	; 0 = Genesis/Mega Drive, 1 = SMS/GG

; ================================================================
; VDP constants
; ================================================================

; rVDPPort1
bVDP_TopStatus			=	7
bVDP_RightStatus		=	6
bVDP_HideLeftColumn		=	5
bVDP_EnableScanlineIRQ	=	4
bVDP_ShiftSpritesLeft	=	3
bVDP_Mode4				=	2
bVDP_ScreenStretch		=	1
bVDP_NoSync				=	0

; rVDPPort2
bVDP_Unused2			=	7
bVDP_DisplayOn			=	6
bVDP_EnableVBlankIRQ	=	5
bVDP_Extend4Rows		=	4
bVDP_Extend6Rows		=	3
bVDP_Unused3			=	2
bVDP_Sprites8x16		=	1
bVDP_SpritesDoubleSize	=	0

; rVDPPort6
bVDP_TileBase2000		=	2

VDP_WriteVRAM			=	%01000000
VDP_WriteReg			=	%10000000
VDP_WritePal			=	%11000000

; ================================================================
; Sound related constants
; ================================================================

; The following bits are only available when the FM unit is present!

; rYMModulatorCtrl + rYMCarrierCtrl
bYM_AMEnable			=	7
bYM_VibratoEnable		=	6
bYM_EnvelopeDecay		=	5	; clear to switch to sustain mode
bYM_KeyScaleRate		=	4
; remaining bits control multi sample wave selection (?)

; rYMCarrierKS
bYM_RectifyModulator	=	4
bYM_RectifyCarrier		=	3

; rYMPercussion
bYM_EnablePercussion	=	5
bYM_Kick				=	4
bYM_Snare				=	3
bYM_Tom					=	2
bYM_Cymbal				=	1
bYM_HiHat				=	0

; rYMCtrl
bYM_Enabled				=	3
bYM_SampleMode			=	0

; rYMOctave
bYM_Sustain				=	5
bYM_KeyOn				=	4
bYM_FreqHi				=	0

; Patch numbers
YM_UserDefined			=	0
YM_Violin				=	1
YM_Guitar				=	2
YM_Piano				=	3
YM_Flute				=	4
YM_Clarinet				=	5
YM_Oboe					=	6
YM_Trumpet				=	7
YM_Organ				=	8
YM_Tube					=	9
YM_Synth				=	10
YM_Harp					=	11
YM_Vibraphone			=	12
YM_SynthBass			=	13
YM_WoodBass				=	14
YM_ElecBass				=	15

; --------------------------------

; The following bits are only available on Game Gear!
bStereo_CH1L			=	0
bStereo_CH2L			=	1
bStereo_CH3L			=	2
bStereo_CH4L			=	3
bStereo_CH1R			=	4
bStereo_CH2R			=	5
bStereo_CH3R			=	6
bStereo_CH4R			=	7


; ================================================================
; PSG commands
; ================================================================

PSG_CH1					=	%00000000
PSG_CH2					=	%00100000
PSG_CH3					=	%01000000
PSG_CH4					=	%01100000

; volume level
PSGCmd_Volume			=	%10010000

; frequency
PSGCmd_Frequency		=	%10000000

; noise flags
PSGNoise_Low			=	%00000000
PSGNoise_Mid			=	%00000001
PSGNoise_High			=	%00000010
PSGNoise_UseCH3Freq		=	%00000011
PSGNoise_FeedbackOff	=	%00000100
