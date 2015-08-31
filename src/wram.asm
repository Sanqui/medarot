SECTION "WRAM Bank 1", WRAMX

SECTION "hack", WRAMX[$DFA0]
TempA: ds 1
BankOld: ds 1
TempH:
    ds 1
TempL:
    ds 1
VWFLetterNum:
    ds 1
VWFChar:
    ds 1
VWFTileLoc:
    ds 2
VWFCurTileNum:
    ds 1
VWFCurTileCol:
    ds 1
;VWFCurTileRow:
;    ds 1
VWFNumTilesUsed:
    ds 1
VWFCharWidth:
    ds 1
;VWFCurRow:
;    ds 1
VWFCharset:
    ds 1
VWFDisabled:
    ds 1
VWFResetDisabled: ; c00c
    ds 1
StringDepth: ; c00d
    ds 1
WTextOffsetHi: 
    ds 1

VWFBuildArea0:
    ds 8
VWFBuildArea1:
    ds 8
VWFBuildArea2:
    ds 8
VWFBuildArea3:
    ds 8

ListText: ;dfd1
	ds 8
	ds 8
	ds 8
	ds 8