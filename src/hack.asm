; free space

FontKana:
    INCBIN "gfx/fontkana.1bpp"

VWFFont:
INCBIN "gfx/vwffont.1bpp"

VWFTable:
INCLUDE "src/vwftable.asm"

HackPredefTable:
    dw WriteCharAdvice ; 0
    dw PutStringAdvice ; 1
    dw LoadFont_ ; 2
    dw LoadFont2 ; 3
    dw Dec0AAndLoadFont2 ; 4
    dw LoadFontDialogueAdvice ; 5
    dw ResetVWF ; 6
    ;dw Char4FAdvice ; 7
    dw $0000
    dw GetTextOffset ; 8
    dw IncTextOffset ; 9
    dw ZeroTextOffset ; $a
    dw IncTextOffsetAndResetVWF ; $b
	dw SelectNameOffset ; $c
	dw Char4BAdvice ;d

HackPredef:
    ; save hl
    ld a, h
    ld [TempH], a
    ld a, l
    ld [TempL], a
    
    push bc
    ld hl, HackPredefTable
    ld b, 0
    ld a, [TempA] ; old a
    ld c, a
    add hl, bc
    add hl, bc
    ld a, [hli]
    ld c, a
    ld a, [hl]
    ld b, a
    push bc
    pop hl
    pop bc
    
    push hl
    ld a, [TempH]
    ld h, a
    ld a, [TempL]
    ld l, a
    ret ; jumps to hl

WriteCharAdvice:
    ld a, [hSaveA]
    cp a, $49 ; Set English
    jr nz, .more
    ld a, 1
    ld [VWFCharset], a
    ret
.more
    cp a, $48 ; Set Japanese
    jr nz, .regular
    xor a
    ld [VWFCharset], a
    ret
.regular
    ;and a
    ;ret z
    ; better safe than sorry
    push bc
    push de
    call WriteVWFChar
    pop de
    pop bc
    ; original code
	;di ; 1
	;call $17cb ; 3
	;ld [hl], a 
	;ei
    ret

ResetVWF:
    push af
    push hl
    xor a
    ld [VWFCurTileCol], a
    ;ld [VWFCurTileNum], a
    ld hl, VWFCurTileNum
    inc [hl]
    ld a, [VWFCurTileNum]
    cp $b7-$80 ; may need tweaking
    jr c, .ok
    ld a, $00
    ld [VWFCurTileNum], a ; Prevent overflow
.ok
    pop hl
    pop af
	ret

PutStringAdvice:
    call ResetVWF
    ld a, 1
    ld [VWFCharset], a
    ; original code
	ld a, h ; 1
	ld [$c640], a ; 3
	ret

CopyColumn:
    ; b = source column
    ; c = dest column
    ; de = source number
    ; hl = dest number
    push hl
    push de
    ld a, $08
    ;ld [VWFCurTileRow], a
.Copy
    push af
    ld a, [de]
    and a, b
    jr nz, .CopyOne
.CopyZero
    ld a, %11111111
    xor c
    and [hl]
    jp .Next
.CopyOne
    ld a, c
    or [hl]
.Next
    ld [hli],a
    inc de
    ;ld a, [VWFCurTileRow]
    pop af
    dec a
    ;ld [VWFCurTileRow], a
    jp nz, .Copy
    pop de
    pop hl
    ret
    
WriteVWFChar:
    ;push de
    push hl
    ld [VWFChar], a
    ; Store the original tile location.
    push hl
    pop de
    ld hl, VWFTileLoc
    ld [hl], d
    inc hl
    ld [hl], e
    
    ; Check if VWF is enabled, bail if not.
    ;ld a, [W_VWF_ENABLED]
    ;dec a
    
    ; write to tilemap
    pop hl
    ld a, [VWFCurTileNum]
    add $80
    ;push af
    di
    call $17cb
    ld [hl], a
    ei
    push hl
    
    ; Get the character in VWF's font.
    ld a, [VWFChar]
    ;cp $80
    ;jr c, .gotchar
    sub a, $80
    ;jr .gotchar
;.high
;    add a, $20
.gotchar
    ld [VWFChar], a
    push af
    ; Store the character tile in BuildArea0.
    ld a, [VWFCharset]
    and a
    jr nz, .english
    ld hl, FontKana
    jr .gotcharset
.english
    ld hl, VWFFont
.gotcharset
    pop af
    ld b, 0
    ld c, a
    ld a, $8
    call AddNTimes
    ld bc, $0008
    ld de, VWFBuildArea0
    call CopyBytes ; copy bc source bytes from hl to de
    
    ld a, $1
    ld [VWFNumTilesUsed], a
    
    ; Get the character length from the width table.
    ld a, [VWFCharset]
    and a
    jr nz, .variable
    ld a, $8
    ld [VWFCharWidth], a
    jr .WidthWritten
.variable
    ld a, [VWFChar]
    ld c, a
    ld b, $00
    ld hl, VWFTable
    add hl, bc
    ld a, [hl]
    ld [VWFCharWidth], a
    ; if 0 width, skip this !!
    and a
    jr z, .NoDrawing
.WidthWritten
    ; Set up some things for building the tile.
    ; Special cased to fix column $0, which is invalid (not a power of 2)
    ld de, VWFBuildArea0
    ld hl, VWFBuildArea2
    ;ld b, a
    ld b, %10000000
    ld a, [VWFCurTileCol]
    and a
    jr nz, .ColumnIsFine
    ld a, $80
.ColumnIsFine
    ld c, a ; a
.DoColumn
    ; Copy the column.
    call CopyColumn
    rr c
    jr c, .TileOverflow
    rrc b
    ld a, [VWFCharWidth]
    dec a
    ld [VWFCharWidth], a
    jr nz, .DoColumn 
    jr .Done
.TileOverflow
    ld c, $80
    ld a, $2
    ld [VWFNumTilesUsed], a
    ld hl, VWFBuildArea3
    jr .ShiftB
.DoColumnTile2
    call CopyColumn
    rr c
.ShiftB
    rrc b
    ld a, [VWFCharWidth]
    dec a
    ld [VWFCharWidth], a
    jr nz, .DoColumnTile2
.Done
    ld a, c
    ld [VWFCurTileCol], a
.NoDrawing
    
    ;ld de, W_VWF_BUILDAREA1
    ;ld hl, W_VWF_BUILDAREA3
    
    
    
    ; 1bpp -> 2bpp
    ;ld b, 0
    ;ld c, $10
    ;ld hl, VWFBuildArea2
    ;;call DelayFrame
    ;ld de, VWFCopyArea
    ;call FarCopyBytesDouble ; copy bc*2 bytes from a:hl to de ; XXX don't far

    ; Get the tileset offset.
    ld hl, $8800 ; $8ba0
    ld a, [VWFCurTileNum]
    ld b, $0
    ld c, a
    ld a, 16
    call AddNTimes
    
    push hl
    pop de
    
    ; Write the new tile(s)

    ld hl, VWFBuildArea2
    ld bc, $0008
    call CopyVRAMDataDouble


    ld a, [VWFNumTilesUsed]
    dec a
    dec a
    jr nz, .SecondAreaUnused
    ; if we went over one tile, copy it too.
    
    ld hl, VWFBuildArea3
    ld bc, $0008
    call CopyVRAMDataDouble
    
    ; If we went over one tile, make sure we start with it next time.
    ; also move through the tilemap.
    ld a, [VWFCurTileNum]
    inc a
    ld [VWFCurTileNum], a
    ld a, $00
    ld hl, VWFBuildArea3
    ld de, VWFBuildArea2
    ld bc, $0008
    call CopyBytes
    ld hl, VWFBuildArea3
    ld a, $0
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a
    ld [hli], a ; lazy
    
    pop hl
    inc hl
    ld a, [VWFCurTileNum]
    add $80
    
    di
    call $17cb
    ld [hl], a
    ei
    
    push hl
    jr .FixOverflow
.SecondAreaUnused
    ; stupid bugfix for when the char didn't overflow, but the next char starts on the next tile.
    ;ld a, [VWFCurTileCol]
    ;cp $1
    ;jr nz, .FixOverflow
    ;pop hl
    ;inc hl
    ;push hl
.FixOverflow
    ; If we went over the last character allocated for VWF tiles, wrap around.
    ld a, [VWFCurTileNum]
    cp $b7-$80 ; may need tweaking
    jr c, .AlmostDone
    ld a, $00
    ld [VWFCurTileNum], a ; Prevent overflow
.AlmostDone
    ;call WaitDMA
    pop hl
    
    ;ld a, h
    ;ld [$c6c2], a
    ;ld a, l
    ;ld [$c6c3], a
    
    ;pop de
    ret

CopyBytes: ; 0x3026
; copy bc bytes from hl to de
	inc b  ; we bail the moment b hits 0, so include the last run
	inc c  ; same thing; include last byte
	jr .HandleLoop
.CopyByte
	ld a, [hli]
	ld [de], a
	inc de
.HandleLoop
	dec c
	jr nz, .CopyByte
	dec b
	jr nz, .CopyByte
	ret
	
AddNTimes: ; 0x30fe
; adds bc n times where n = a
	and a
	ret z
.loop
	add hl, bc
	dec a
	jr nz, .loop
	ret
; 0x3105

CopyVRAMDataDouble: ;  cb7, hl=from, de=to, bc=how many/2
	ld a, [hli]
	di
	call $17cb
	ld [de], a
	inc de
	ld [de], a
	ei
	inc de
	dec bc
	ld a, b
	or c
	jr nz, CopyVRAMDataDouble ; 0xcc2 $f3
	ret

Font:
    INCBIN "gfx/font.1bpp"
FontEnd
Font1LastRow:
    INCBIN "gfx/font1lastrow.2bpp"
Font2LastRow:
    INCBIN "gfx/font2lastrow.2bpp"

LoadFontChars:
    ld hl, Font
    ld de, $8800
    ld bc, FontEnd-Font
    call CopyVRAMDataDouble
    ret

LoadFont_:
    call LoadFontChars
    ld hl, Font1LastRow
    ld de, $8F00
    ld bc, $100
    call CopyVRAMData
    ret

LoadFont2:
    ld a, 2 ; LoadFont_
    call LoadFontChars
    ld hl, Font2LastRow
    ld de, $8F00
    ld bc, $100
    call CopyVRAMData
    ret

Dec0AAndLoadFont2:
    ld a, [$c6e0]
    push af
    ld a, BANK(HackPredef)
    ld [$c6e0], a
    ld a, $a
    call $15f
    pop af
    ld [$c6e0], a
    jp LoadFont2
    
LoadFontDialogueAdvice:
    call LoadFont_
    call ResetVWF
    xor a
    ld [VWFCharset], a ; set japanese
	xor a
	ld [$c64e], a
    ret

;Char4FAdvice:
;	call ResetVWF
;	
;	; o
;	inc hl
;	ld a, [hl]
;	or a
;	ret

GetTextOffset:
    ld a, [$c6c0]
    ld c, a
    ld a, [WTextOffsetHi]
    ld b, a
    ret

IncTextOffset:
    ld a, [$c6c0]
    inc a
    ld [$c6c0], a
    ret nz
    ld a, [WTextOffsetHi]
    inc a
    ld [WTextOffsetHi], a
    ret

ZeroTextOffset:
    xor a
    ld [$c6c0], a
    ld [WTextOffsetHi], a
    ret

IncTextOffsetAndResetVWF:
    call IncTextOffset
    call ResetVWF
    ret
	
SelectNameOffset: ;If it's <= AF00, ld hl,$0002
	ld a,d
	;cp a,$AC
	sub $AF
	jr c,.asm_SNO_1
	ld hl,-$0010
	ret
.asm_SNO_1:
	ld hl,$0002
	ret
	
Char4BAdvice:
	pop af
	cp $0
	jr z, .Char4BAdviceEnd
	rst $10
	ld a,$0
	ld [$c6c5],a
.Char4BAdviceEnd
	ret
	