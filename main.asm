SECTION "bank0",HOME
SECTION "rst0",HOME[$0]
	pop hl
	add a
	rst $28
	ld a, [hli]
	ld h, [hl]
	ld l, a
	jp [hl]

SECTION "rst8",HOME[$8]
	reti

SECTION "rst10",HOME[$10] ; Bankswitch
	ld [$2000], a
	ret

SECTION "rst18",HOME[$18] 
	ld a, [$c6e0]
	ld [$2000], a
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
	jr z, .asm_1ce5 ; 0x1cde $5
	dec a
	ld [$c6c1], a
	ret
.asm_1ce5
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
	di
	call $17cb
	ld [hl], a ; "/°
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


INCBIN "baserom.gbc", $1ff2,$2fcf-$1ff2

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
	di
	call $17cb
	ld [hl], a
	ei
	ld a, [$c642]
	ld h, a
	ld a, [$c643]
	ld l, a
	ld a, [$c64e]
	di
	call $17cb
	ld [hl], a
	ei
	inc hl
	ld a, h
	ld [$c642], a
	ld a, l
	ld [$c643], a
	ld a, [$c640]
	ld h, a
	ld a, [$c641]
	ld l, a
	inc hl
	ld a, h
	ld [$c640], a
	ld a, l
	ld [$c641], a
	jp .char
; 0x303b

INCBIN "baserom.gbc", $303b,$4000-$303b

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
