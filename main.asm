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
	jp z, Char4F
	cp $4e
	jp z, Char4E
	cp $4d
	jp z, Char4D
	cp $4c
	jp z, Char4C
	cp $4b
	jp z, Char4B
	cp $4a
	jp z, Char4A
	jp WriteChar

TextTableBanks: ; 0x1d3b
    db $0c
    db $0d
    db $0e
    db $0f
    db BANK(StoryText1)
    db $13
    db $00
    db $00
    db $18
    db $00
    db $1a
    db $00
    db $00
    db BANK(BattleText)
    db $00
    db $00

TextTableOffsets: ; 0x1d4b
    dw $7e00
    dw $7e00
    dw $7e00
    dw $7e00
    dw StoryText1
    dw $7800
    dw $4000
    dw $4000
    dw $4000
    dw $4000
    dw $4000
    dw $4000
    dw $4000
    dw BattleText
    dw $4000
    dw $4000

Char4F: ; 1d6b end of text
	inc hl
	ld a, [hl]
	or a
	jp nz, .Char4fMore
	ld a, [$ff8d]
	and $3
	jr nz, .asm_1d8b ; 0x1d75 $14
	ld a, [$ff8c]
	and $3
	jr z, .asm_1d89 ; 0x1d7b $c
	ld a, [$c6c5]
	cp $10
	jp z, $1d8b
	inc a
	ld [$c6c5], a
.asm_1d89
	pop hl
	ret
.asm_1d8b
	ld a, $22
	ld [$ffa1], a
	xor a
	ld [$c5c7], a
	ld [$c6c5], a
	call $1ab0
	ld a, $1
	ld [$c6c6], a
	pop hl
	ret

.Char4fMore: ; 0x1da0
	ld a, [hl]
	cp $1
	jr nz, .asm_1db6 ; 0x1da3 $11
	xor a
	ld [$c5c7], a
	ld [$c6c5], a
	call $1ab0
	ld a, $1
	ld [$c6c6], a
	pop hl
	ret
.asm_1db6
	ld a, [hl]
	cp $2
	jr nz, .asm_1de4 ; 0x1db9 $29
	ld a, [$ff8d]
	and $3
	jr nz, .asm_1dd5 ; 0x1dbf $14
	ld a, [$ff8c]
	and $3
	jr z, .asm_1d89 ; 0x1dc5 $c2
	ld a, [$c6c5]
	cp $10
	jp z, $1dd5
	inc a
	ld [$c6c5], a
	pop hl
	ret
.asm_1dd5
	ld a, $22
	ld [$ffa1], a
	xor a
	ld [$c6c5], a
	ld a, $1
	ld [$c6c6], a
	pop hl
	ret
.asm_1de4
	ld a, [hl]
	cp $3
	jr nz, .asm_1e1b ; 0x1de7 $32
	ld a, [$ff8d]
	and $3
	jr nz, .asm_1e03 ; 0x1ded $14
	ld a, [$ff8c]
	and $3
	jr z, .asm_1d89 ; 0x1df3 $94
	ld a, [$c6c5]
	cp $10
	jp z, $1e03
	inc a
	ld [$c6c5], a
	pop hl
	ret
.asm_1e03
	ld a, $22
	ld [$ffa1], a
	ld b, $1
	ld c, $1
	ld e, $2f
	call $0f84
	xor a
	ld [$c6c5], a
	ld a, $1
	ld [$c6c6], a
	pop hl
	ret
.asm_1e1b
	ld a, $1
	ld [$c6c6], a
	pop hl
	ret
Char4E:
	ld hl, $9c00
	ld bc, $0081
	ld a, [$c5c7]
	cp $1
	jr z, .asm_1e32 ; 0x1e2d $3
	ld bc, $0061
.asm_1e32
	add hl, bc
	ld a, h
	ld [$c6c2], a
	ld a, l
	ld [$c6c3], a
	ld a, [$c6c0]
	inc a
	ld [$c6c0], a
	pop hl
	jp $1d11

Char4D: ; 0x1e46
; text speed
	inc hl
	ld a, [hl]
	ld [$c6c1], a
	ld [$c6c4], a
	ld a, [$c6c0]
	add $2
	ld [$c6c0], a
	pop hl
	ld a, [$c6c1]
	cp $ff
	ret nz
	xor a
	ld [$c6c1], a
	ret

Char4C: ; 0x1e62
; new text box
	pop hl
	ld hl, $9c00
	ld bc, $0092
	ld a, [$c5c7]
	cp $1
	jr z, .asm_1e73 ; 0x1e6e $3
	ld bc, $0072
.asm_1e73
	add hl, bc
	ld a, $fa
	di
	call $17cb
	ld [hl], a
	ei
	ld a, [$ff8d]
	and $3
	jr nz, .asm_1e94 ; 0x1e80 $12
	ld a, [$ff8c]
	and $3
	ret z
	ld a, [$c6c5]
	cp $10
	jp z, $1e94
	inc a
	ld [$c6c5], a
	ret
.asm_1e94
	ld a, $22
	ld [$ffa1], a
	xor a
	ld [$c6c5], a
	ld b, $1
	ld c, $1
	ld e, $2f
	call $0f84
	ld a, [$c5c7]
	cp $1
	jr z, .asm_1eb5 ; 0x1eaa $9
	ld b, $0
	ld c, $0
	ld e, $30
	call $0f84
.asm_1eb5
	ld hl, $9c00
	ld bc, $0041
	ld a, [$c5c7]
	cp $1
	jr z, .asm_1ec5 ; 0x1ec0 $3
	ld bc, $0021
.asm_1ec5
	add hl, bc
	ld a, h
	ld [$c6c2], a
	ld a, l
	ld [$c6c3], a
	ld a, [$c6c0]
	inc a
	ld [$c6c0], a
	ret

Char4B: ; 0x1ed6
; call subtext
	inc hl
	ld a, [hli]
	ld h, [hl]
	ld l, a
	ld a, [$c6c5]
	ld c, a
	ld b, $0
	add hl, bc
	ld a, [hl]
	cp $50
	jr nz, .asm_1f04 ; 0x1ee4 $1e
	ld a, [$c6c0]
	inc a
	inc a
	inc a
	ld [$c6c0], a
	xor a
	ld [$c6c5], a
	ld a, [$c6c4]
	ld [$c6c1], a
	pop hl
	cp $ff
	ret nz
	xor a
	ld [$c6c1], a
	jp $1d11
.asm_1f04
	ld d, a
	ld a, $40
	sub d
	jp c, $1f2f
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
	di
	call $17cb
	ld [hl], a
	ei
	pop hl
	ld a, [hl]
	ld d, a
	ld a, [$c6c2]
	ld h, a
	ld a, [$c6c3]
	ld l, a
	ld a, d
	di
	call $17cb
	ld [hl], a
	ei
	inc hl
	ld a, h
	ld [$c6c2], a
	ld a, l
	ld [$c6c3], a
	ld a, [$c6c5]
	inc a
	ld [$c6c5], a
	ld a, [$c6c4]
	ld [$c6c1], a
	pop hl
	cp $ff
	ret nz
	xor a
	ld [$c6c1], a
	jp $1d11


Char4A: ; 0x1f5f
; \r
	ld c, $1
	ld a, $41
	ld [$c650], a
	ld a, [$c5c7]
	cp $1
	jr z, .asm_1f74 ; 0x1f6b $7
	ld c, $0
	ld a, $21
	ld [$c650], a
.asm_1f74
	ld b, $1
	ld e, $2f
	call $0f84
	ld hl, $9c00
	ld a, [$c650]
	ld b, $0
	ld c, a
	add hl, bc
	ld a, h
	ld [$c6c2], a
	ld a, l
	ld [$c6c3], a
	ld a, [$c6c0]
	inc a
	ld [$c6c0], a
	pop hl
	ret
; 0x1f96

WriteChar: ; 1f96
	ld a, [hl]
	ld d, a
	ld a, $40
	;sub d
	nop
	jp $1fc2;c, $1fc2
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


INCBIN "baserom.gbc", $1ff2,$2d85-$1ff2

LoadFontDialogue: ; 2d85
    ld a, 5 ; LoadFontDialogueAdvice
    rst $8
    ;ld a, 3
    ;call $12e8 ; Decompress
    nop
    nop
    ret
;2d8b

INCBIN "baserom.gbc", $2d8b,$2dba-$2d8b

; 2dba
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
    ld a, $1 ; 2 ; PutStringAdvice
    rst $8 ; 1
    nop
    
	;ld a, h ; 1
	;ld [$c640], a ; 3
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

INCBIN "baserom.gbc", $4000,$4417-$4000

    nop
    nop
    ld a, 2 ; LoadFont_
    rst $8

INCBIN "baserom.gbc", $441c,$4ad9-$441c

; before naming screen
    ld a, 2 ; LoadFont_
    rst $8

INCBIN "baserom.gbc", $4adc,$64a6-$4adc

; after battle won
    ld a, 2 ; LoadFont_
    rst $8
;    call $15f ; probably not necessary

INCBIN "baserom.gbc", $64a9,$8000-$64a9

SECTION "bank2",DATA,BANK[$2]

INCBIN "baserom.gbc", $8000,$8038-$8000

; on start menu
    nop
    nop
    ld a, 2 ; LoadFont_
    rst $8

INCBIN "baserom.gbc", $803d,$8b71-$803d

; when returning to menu from items
    ld a, 2 ; LoadFont_
    rst $8

INCBIN "baserom.gbc", $8b74,$9482-$8b74

; on medal screen and parts screen
    nop
    nop
    ld a, 3 ; LoadFont2
    rst $8

INCBIN "baserom.gbc", $9487,$9c78-$9487

; when returning to menu
    nop
    nop
    ld a, 2 ; LoadFont_
    rst $8

INCBIN "baserom.gbc", $9c7d,$9c84-$9c7d

; when returning from save screen
    ld a, 2 ; LoadFont_
    rst $8

INCBIN "baserom.gbc", $9c87,$a90b-$9c87

; on medarot choice selection
    nop
    nop
    ld a, 3 ; LoadFont2
    rst $8

INCBIN "baserom.gbc", $a910,$c000-$a910


SECTION "bank3",DATA,BANK[$3]
INCBIN "baserom.gbc", $c000,$4000

SECTION "bank4",DATA,BANK[$4]

INCBIN "baserom.gbc", $10000,$10637-$10000

    ld a, 4 ; dec a n load font 2
    rst $8

INCBIN "baserom.gbc", $1063a,$1120c-$1063a

SetUpMedarotData: ; 1120c 4:520c
	ld a, [$c753]
	call $02bb
	ld a, [$c64e]
	ld [$c745], a
	xor a
	ld [$c65a], a
	ld hl, $af00
	ld b, $0
	ld a, [$c65a]
	ld c, a
	ld a, $8
	call $02b8
	ld a, $3
	ld [de], a
	ld a, $1
	ld hl, $0000
	add hl, de
	ld [hl], a
	ld a, [$c650]
	ld hl, $5326
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld hl, $0001
	add hl, de
	ld [hl], a
	ld a, [$c656]
	ld hl, $000b
	add hl, de
	ld [hl], a
	call $0162
	ld a, [$c5f0]
	and $3
	ld hl, $c650
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld hl, $000d
	add hl, de
	ld [hl], a
	call $0162
	ld a, [$c5f0]
	and $3
	ld hl, $c650
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld hl, $000e
	add hl, de
	ld [hl], a
	call $0162
	ld a, [$c5f0]
	and $3
	ld hl, $c650
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld hl, $000f
	add hl, de
	ld [hl], a
	call $0162
	ld a, [$c5f0]
	and $3
	ld hl, $c650
	ld b, $0
	ld c, a
	add hl, bc
	ld a, [hl]
	ld hl, $0010
	add hl, de
	ld [hl], a
	ld a, [$c65a]
	inc a
	ld hl, $0011
	add hl, de
	ld [hl], a
	ld a, [$c64e]
	push af
	call $539b
	pop af
	ld [$c64e], a
	ld hl, $000d
	add hl, de
	ld a, [hl]
	and $7f
	ld c, a
	call $02be
	push de
	ld b, $10 ; MEDAROT NAME LENGTH
	ld hl, -$0010;$0002
	add hl, de
	ld d, h
	ld e, l
	ld hl, $c6a2
.asm_112cb
	ld a, [hli]
	ld [de], a
	inc de
	dec b
	jr nz, .asm_112cb ; 0x112cf $fa
	pop de
	ld a, $1
	ld hl, $00c8
	add hl, de
	ld [hl], a
	ld hl, $0080
	add hl, de
	ld a, $1
	ld [hl], a
	ld hl, $000b
	add hl, de
	ld a, [hl]
	ld hl, $0081
	add hl, de
	ld [hl], a
	ld a, [$c654]
	ld b, a
	ld a, [$c934]
	add b
	ld c, a
	sub $b
	jr c, .asm_112f9 ; 0x112f5 $2
	ld c, $a
.asm_112f9
	ld a, c
	ld hl, $0083
	add hl, de
	ld [hl], a
	ld a, [$c655]
	ld b, a
	ld a, [$c935]
	add b
	ld c, a
	sub $7
	jr c, .asm_1130e ; 0x1130a $2
	ld c, $6
.asm_1130e
	ld a, c
	ld hl, $0084
	add hl, de
	ld [hl], a
	ld a, [$c65a]
	inc a
	ld [$c65a], a
	ld a, [$c64e]
	dec a
	ld [$c64e], a
	jp nz, $521c
	ret
; 0x11326

INCBIN "baserom.gbc", $11326,$132ea -$11326

; entering battle selecting medarot
    ld a, 3 ; LoadFont2
    rst $8

INCBIN "baserom.gbc", $132ed,$136cc -$132ed

DrawMedarotData:
	xor a
	ld [$c652], a
	ld hl, $ac00
	ld b, $0
	ld a, [$c652]
	ld c, a
	ld a, $8
	call $02b8
	ld a, [de]
	or a
	jp z, $770d
	ld hl, $0002
	add hl, de
	call $546f
	ld [$c650], a
	push de
	ld hl, $98e0
	ld b, $0
	ld a, [$c652]
	ld c, a
	ld a, $6
	call $02b8
	pop de
	ld a, [$c650]
	ld b, $0
	ld c, a
	add hl, bc
	ld b, h
	ld c, l
	ld hl, $0002
	add hl, de
	call $0264
	ld a, [$c652]
	inc a
	ld [$c652], a
	cp $3
	jp nz, $76d0
	xor a
	ld [$c652], a
	ld hl, $af00
	ld b, $0
	ld a, [$c652]
	ld c, a
	ld a, $8
	call $02b8
	ld a, [de]
	or a
	jp z, $7749
	push de
	ld hl, $98ec
	ld b, $0
	ld a, [$c652]
	ld c, a
	ld a, $6
	call $02b8
	pop de
	ld b, h
	ld c, l
	ld hl, -$0010;$0002
	add hl, de
	call $0264
	ld a, [$c652]
	inc a
	ld [$c652], a
	cp $3
	jp nz, $771d
	ret
; 0x13756

INCBIN "baserom.gbc", $13756,$14000 -$13756

SECTION "bank5",DATA,BANK[$5]
INCBIN "baserom.gbc", $14000,$4000

SECTION "bank6",DATA,BANK[$6]
INCBIN "baserom.gbc", $18000,$4000

SECTION "bank7",DATA,BANK[$7]
INCBIN "baserom.gbc", $1c000,$27a0

; free space

FontKana:
    INCBIN "gfx/fontkana.1bpp"

VWFFont:
INCBIN "gfx/vwffont.1bpp"

VWFTable:
INCLUDE "vwftable.asm"

HackPredefTable:
    dw WriteCharAdvice ; 0
    dw PutStringAdvice ; 1
    dw LoadFont_ ; 2
    dw LoadFont2 ; 3
    dw Dec0AAndLoadFont2 ; 4
    dw LoadFontDialogueAdvice ; 5
    dw ResetVWF ; 6

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
    ld hl, VWFCurTileNum
    inc [hl]
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
INCBIN "baserom.gbc", $5c000,$5ec36-$5c000

MedarotNames:
    INCBIN "text/medarots.bin"

INCBIN "baserom.gbc", $5ec36+(16*60),$60000-($5ec36+(16*60))

SECTION "bank18",DATA,BANK[$18]
INCBIN "baserom.gbc", $60000,$4000

SECTION "bank19",DATA,BANK[$19]
INCBIN "baserom.gbc", $64000,$4000

SECTION "bank1a",DATA,BANK[$1a]
INCBIN "baserom.gbc", $68000,$4000

SECTION "bank1b",DATA,BANK[$1b]
INCBIN "baserom.gbc", $6c000,$6eacb-$6c000

; main battle scr, returning from stats
    ;call $15f
    ld a, 4 ; Dec0AAndLoadFont2
    rst $8

INCBIN "baserom.gbc", $6eace,$6ec7e-$6eace

StatsScreen: ; 6ec7e
	ld hl, $ac00
	ld a, [$c0d7]
	ld b, $0
	ld c, a
	ld a, $8
	call $02b8
	push de
	ld hl, -$0010;$0002
	add hl, de
	push hl
	call $028e
	ld h, $0
	ld l, a
	ld bc, $984b
	add hl, bc
	ld b, h
	ld c, l
	pop hl
	call $0264
	pop de
	push de
	ld hl, $0081
	add hl, de
	ld a, [hl]
	ld de, $9410
	call $027c
	pop de
	ld a, $41
	ld hl, $988a
	call $6d0e
	push de
	ld hl, $0081
	add hl, de
	ld a, [hl]
	call $0282
	ld hl, $c6a2
	ld bc, $98ac
	call $0264
	pop de
	call $6fc4
	ld hl, $000d
	add hl, de
	ld a, [hl]
	and $7f
	ld [$a03d], a
	push de
	call $6d2c
	pop de
	ld hl, $000e
	add hl, de
	ld a, [hl]
	and $7f
	ld [$a03f], a
	push de
	call $6d54
	pop de
	ld hl, $000f
	add hl, de
	ld a, [hl]
	and $7f
	ld [$a041], a
	push de
	call $6d7c
	pop de
	ld hl, $0010
	add hl, de
	ld a, [hl]
	and $7f
	ld [$a043], a
	push de
	call $6da4
	pop de
	call $6ece
	ret
; 0x6ed0e

INCBIN "baserom.gbc", $6ed0e,$70000-$6ed0e

SECTION "bank1c",DATA,BANK[$1c]
INCBIN "baserom.gbc", $70000,$4000

SECTION "bank1d",DATA,BANK[$1d]

    INCBIN "baserom.gbc", $74000,$4000

SECTION "bank1e",DATA,BANK[$1e]
INCBIN "baserom.gbc", $78000,$4000

SECTION "bank1f",DATA,BANK[$1f]
INCBIN "baserom.gbc", $7c000,$4000
StoryText1:


; look!  it's a new bank!
SECTION "bank20",DATA,BANK[$20]
    
    INCBIN "text/story1.bin"
    
SECTION "bank21",DATA,BANK[$21]

BattleText:
    INCBIN "text/battles.bin"
