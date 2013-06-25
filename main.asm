SECTION "bank0",HOME
SECTION "rst0",HOME[$0]
	pop hl
	add a
	rst $28
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp [hl]

SECTION "rst8",HOME[$8] ; HackPredef
    ld [TempA], a ; 3
	jp Rst8Cont

SECTION "rst10",HOME[$10] ; Bankswitch
    ld [hBank], a
	ld [$2000], a
	ret

SECTION "rst18",HOME[$18] 
	ld a, [$c6e0]
	;ld [$2000], a
	rst $10
	ret

SECTION "rst20",HOME[$20]
	add l
	ld l, a
	ret c
	dec h
	ret

SECTION "rst28",HOME[$28]
	add l
	ld l, a
	ret nc
	inc h
	ret

SECTION "rst30",HOME[$30]
    add a
    rst $28
    ld a, [hli]
    ld h, [hl]
    ld l, a
    ret

SECTION "rst38",HOME[$38] ; Unused
	ld a, [hli]
	ld l, [hl]
	ld h, a
	ret

SECTION "vblank",HOME[$40] ; vblank interrupt
	jp $049b

SECTION "lcd",HOME[$48] ; lcd interrupt
	jp $04d0

SECTION "timer",HOME[$50] ; timer interrupt
	nop

SECTION "serial",HOME[$58] ; serial interrupt
	jp $3e12

SECTION "joypad",HOME[$60] ; joypad interrupt
	reti

Rst8Cont:
    ld a, [hBank]
	ld [BankOld],a
	ld a, BANK(HackPredef)
	ld [$2000], a
    call HackPredef
    ld [TempA], a
    ld a, [BankOld]
    cp a, $17
    jr z, .bs
    ld a, [$c6e0]
.bs
	ld [$2000], a
	ld a, [TempA]
	ret
	
SECTION "romheader",HOME[$100]

INCBIN "baserom.gbc", $100, $50

SECTION "start",HOME[$150]

INCBIN "baserom.gbc", $150,$cb7-$150

CopyVRAMData: ;  cb7
	ld a, [hli]
	di
	call $17cb
	ld [de], a
	ei
	inc de
	dec bc
	ld a, b
	or c
	jr nz, CopyVRAMData ; 0xcc2 $f3
	ret
; 0xcc5


INCBIN "baserom.gbc", $cc5,$1cc9-$cc5

PutChar:
	ld a, [$c6c6]
	or a
	ret nz
	ld a, [$c6c0]
	sub $2
	jr nc, .asm_1cda ; 0x1cd3 $5
	ld a, $1
	ld [$c600], a
.asm_1cda
	ld a, [$c6c1]
	or a
	jr .nowait
	dec a
	ld [$c6c1], a
	ret
.nowait
	push bc
	ld a, b
	and $f0
	swap a
	push af
	ld hl, $1d3b
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	rst $10
	pop af
	ld hl, $1d4b
	ld b, $0
	ld c, a
	sla c
	rl b
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	pop bc
	ld a, b
	and $f
	ld b, a
	sla c
	rl b
	add hl, bc
	ld a, [hli]
	ld h, [hl]
	ld l, a
	push hl
	ld a, [$c6c0]
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	cp $4f
	jp z, $1d6b
	cp $4e
	jp z, $1e22
	cp $4d
	jp z, $1e46
	cp $4c
	jp z, $1e62
	cp $4b
	jp z, $1ed6
	cp $4a
	jp z, $1f5f
	jp WriteChar
; 0x1d3b


INCBIN "baserom.gbc", $1d3b,$1f96-$1d3b

WriteChar: ; 1f96
	ld a, [hl]
	ld d, a
	ld a, $40
	sub d
	jp c, $1fc2
	ld hl, $1ff2
	ld c, d
	ld b, $0
	sla c
	rl b
	add hl, bc
	ld a, [hli]
	push hl
	push af
	ld a, [$c6c2]
	ld h, a
	ld a, [$c6c3]
	ld l, a
	ld bc, $ffe0
	add hl, bc
	pop af
	;di
	;call $17cb
	;ld [hl], a ; "/°
	;ei
	db 0, 0, 0, 0, 0, 0 ; waste of cycles
	pop hl
	ld a, [hl]
	ld d, a
	ld a, [$c6c2]
	ld h, a
	ld a, [$c6c3]
	ld l, a
	ld a, d
	;di ; 1
	;call $17cb ; 3
	;ld [hl], a ; 1
	
	ld [hSaveA], a ; 2
	xor a ; 1
	rst $8 ; 1
	ld a, [hSaveA]
	nop
	
	;ei
	;inc hl
	ld a, h
	ld [$c6c2], a
	ld a, l
	ld [$c6c3], a
	ld a, [$c6c0]
	inc a
	ld [$c6c0], a
	ld a, [$c6c4]
	ld [$c6c1], a
	pop hl
	cp $ff
	ret nz
	xor a
	ld [$c6c1], a
	jp $1d11
; 0x1ff2


INCBIN "baserom.gbc", $1ff2,$2dba-$1ff2

; 
    ld a, $17
;    ld [$2000], a
    rst $10
    nop
    nop

INCBIN "baserom.gbc", $2dbf,$2e58-$2dbf

; 
    ld a, $17
;    ld [$2000], a
    rst $10
    nop
    nop

INCBIN "baserom.gbc", $2e5d,$2f43-$2e5d

    ld a, $17
;    ld [$2000], a
    rst $10
    nop
    nop

INCBIN "baserom.gbc", $2f48,$2fcf-$2f48

PutString: ; 2fcf
	ld a, h
	ld [$c640], a
	ld a, l
	ld [$c641], a
	ld a, b
	ld [$c642], a
	ld a, c
	ld [$c643], a
.char
	ld a, [$c640]
	ld h, a
	ld a, [$c641]
	ld l, a
	ld a, [hl]
	cp $50
	ret z
	ld [$c64e], a
	call $2068
	ld a, [$c64f]
	or a
	jp z, $300d
	ld a, [$c642]
	ld h, a
	ld a, [$c643]
	ld l, a
	ld bc, $ffe0
	add hl, bc
	ld a, [$c64f]
	;di
	;call $17cb
	;ld [hl], a ; "/°
	;ei
	db 0, 0, 0, 0, 0, 0 ; waste of cycles
	ld a, [$c642]
	ld h, a
	ld a, [$c643]
	ld l, a
	ld a, [$c64e]
	
	;di ; 1
	;call $17cb ; 3
	;ld [hl], a ; 1
	
	ld [hSaveA], a ; 2
	xor a ; 1
	rst $8 ; 1
	ld a, [hSaveA]
	nop
	;db 0, 0, 0, 0, 0, 0, 0	
	;ei
	;inc hl
	
	ld a, h
	ld [$c642], a
	ld a, l
	ld [$c643], a
	ld a, [$c640]
	ld h, a
	ld a, [$c641]
	ld l, a
	inc hl
	;nop
	ld a, h
	ld [$c640], a
	ld a, l
	ld [$c641], a
	jp .char
; 0x303b

INCBIN "baserom.gbc", $303b,$35bc-$303b

    ld a, $17
;    ld [$2000], a
    rst $10
    nop
    nop

INCBIN "baserom.gbc", $35c1,$4000-$35c1

SECTION "bank1",DATA,BANK[$1]
INCBIN "baserom.gbc", $4000,$4000

SECTION "bank2",DATA,BANK[$2]
INCBIN "baserom.gbc", $8000,$4000

SECTION "bank3",DATA,BANK[$3]
INCBIN "baserom.gbc", $c000,$4000

SECTION "bank4",DATA,BANK[$4]
INCBIN "baserom.gbc", $10000,$4000

SECTION "bank5",DATA,BANK[$5]
INCBIN "baserom.gbc", $14000,$4000

SECTION "bank6",DATA,BANK[$6]
INCBIN "baserom.gbc", $18000,$4000

SECTION "bank7",DATA,BANK[$7]
INCBIN "baserom.gbc", $1c000,$27a0

; free space

VWFFont:
INCBIN "gfx/vwffont.1bpp"

VWFTable:
INCLUDE "vwftable.asm"

HackPredefTable:
    dw WriteCharAdvice

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
    cp $80
    jr c, .high
    sub a, $80
    jr .gotchar
.high
    add a, $20
.gotchar
    ld [VWFChar], a
    ; Store the character tile in BuildArea0.
    ld hl, VWFFont
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
    cp $e1-$80 ; may need tweaking
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

SECTION "bank8",DATA,BANK[$8]
INCBIN "baserom.gbc", $20000,$4000

SECTION "bank9",DATA,BANK[$9]
INCBIN "baserom.gbc", $24000,$4000

SECTION "banka",DATA,BANK[$a]
INCBIN "baserom.gbc", $28000,$4000

SECTION "bankb",DATA,BANK[$b]
INCBIN "baserom.gbc", $2c000,$4000

SECTION "bankc",DATA,BANK[$c]
INCBIN "baserom.gbc", $30000,$4000

SECTION "bankd",DATA,BANK[$d]
INCBIN "baserom.gbc", $34000,$4000

SECTION "banke",DATA,BANK[$e]
INCBIN "baserom.gbc", $38000,$4000

SECTION "bankf",DATA,BANK[$f]
INCBIN "baserom.gbc", $3c000,$4000

SECTION "bank10",DATA,BANK[$10]
INCBIN "baserom.gbc", $40000,$4000

SECTION "bank11",DATA,BANK[$11]
INCBIN "baserom.gbc", $44000,$4000

SECTION "bank12",DATA,BANK[$12]
INCBIN "baserom.gbc", $48000,$4000

SECTION "bank13",DATA,BANK[$13]
INCBIN "baserom.gbc", $4c000,$4000

SECTION "bank14",DATA,BANK[$14]
INCBIN "baserom.gbc", $50000,$4000

SECTION "bank15",DATA,BANK[$15]
INCBIN "baserom.gbc", $54000,$4000

SECTION "bank16",DATA,BANK[$16]
INCBIN "baserom.gbc", $58000,$4000

SECTION "bank17",DATA,BANK[$17]
INCBIN "baserom.gbc", $5c000,$4000

SECTION "bank18",DATA,BANK[$18]
INCBIN "baserom.gbc", $60000,$4000

SECTION "bank19",DATA,BANK[$19]
INCBIN "baserom.gbc", $64000,$4000

SECTION "bank1a",DATA,BANK[$1a]
INCBIN "baserom.gbc", $68000,$4000

SECTION "bank1b",DATA,BANK[$1b]
INCBIN "baserom.gbc", $6c000,$4000

SECTION "bank1c",DATA,BANK[$1c]
INCBIN "baserom.gbc", $70000,$4000

SECTION "bank1d",DATA,BANK[$1d]
INCBIN "baserom.gbc", $74000,$4000

SECTION "bank1e",DATA,BANK[$1e]
INCBIN "baserom.gbc", $78000,$4000

SECTION "bank1f",DATA,BANK[$1f]
INCBIN "baserom.gbc", $7c000,$4000
