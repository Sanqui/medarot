export LC_CTYPE=C

#User defined 

TARGET := medarot
TARGET_TYPE := gbc
SOURCE_TYPE := asm

#Resource names
RSRC_TEXT := Battles Dialogue_1 Dialogue_2 Dialogue_3
RSRC_SNIP := Snippet_1 Snippet_2 Snippet_3 Snippet_4 Snippet_5
RSRC_LIST := medals medarots

#Type of downloaded text data (RSRC_*)
TEXT_TYPE := mediawiki
TEXT_TYPE_LIST := txt
BIN_TYPE := bin

#Directory information
BASE := .

#Output directory for intermediate files
BUILD := $(BASE)/build
#Source Directory
SRC := $(BASE)/src
#Resource Directory
TEXT := $(BASE)/text

#Compiler/Linker
CC := rgbasm
CC_ARGS :=
LD := rgblink
LD_ARGS :=
FIX := rgbfix
FIX_ARGS := -v -k 9C -l 0x33 -m 0x13 -p 0 -r 3 -t "MEDAROT KABUTO"

#End User Defined

#You shouldn't need to touch anything past this line! 

TARGET_OUT := $(TARGET).$(TARGET_TYPE)

STORYTEXT := $(foreach FILE,$(RSRC_TEXT),$(TEXT)/$(FILE).$(TEXT_TYPE))
SNIPPETS := $(foreach FILE,$(RSRC_SNIP),$(TEXT)/$(FILE).$(TEXT_TYPE))
LISTS := $(foreach FILE,$(RSRC_LIST),$(TEXT)/$(FILE).$(TEXT_TYPE_LIST))

STORYTEXT_OBJ := $(foreach FILE,$(RSRC_TEXT),$(BUILD)/$(FILE).$(BIN_TYPE))
SNIPPETS_OBJ := $(foreach FILE,$(RSRC_SNIP),$(BUILD)/$(FILE).$(BIN_TYPE))
LISTS_OBJ := $(foreach FILE,$(RSRC_LIST),$(BUILD)/$(FILE).$(BIN_TYPE))


all: $(TARGET_OUT)

#Download and build
auto: download $(TARGET_OUT)

#Download files
download: $(TEXT) 
	python preparation/get_text.py

#Generate Binary files (tilemaps, text, lists, etc...)
preparation: $(BUILD) $(TEXT) $(SNIPPETS_OBJ) $(LISTS_OBJ) $(STORYTEXT_OBJ) $(BUILD)/tilemaps.bin

#Build tilemaps
$(BUILD)/tilemaps.bin: $(wildcard $(TEXT)/tilemaps/*.txt)
	python preparation/textpre.py tilemaps 0x4000 > $(BUILD)/tilemaps.bin

#Handle snippets and dialog
#TODO: Handle snippets and dialog separately somehow so we don't need to waste so much space in the ROM for snippets
$(BUILD)/%.$(BIN_TYPE): $(TEXT)/%.$(TEXT_TYPE)
	python preparation/textpre.py bank 0x4000 < $(TEXT)/$(*F).$(TEXT_TYPE) > $(BUILD)/$(*F).$(BIN_TYPE)

#Handle Lists
$(BUILD)/%.$(BIN_TYPE): $(TEXT)/%.$(TEXT_TYPE_LIST)
	python preparation/textpre.py list 0x10 < $(TEXT)/$(*F).$(TEXT_TYPE_LIST) > $(BUILD)/$(*F).$(BIN_TYPE)

	
#ROM object is dependent on all asm files, but they're all grouped into a single asm (e.g. medarot.asm)
$(BUILD)/$(TARGET).o: $(wildcard $(SRC)/*.$(SOURCE_TYPE)) preparation
	$(CC) $(CC_ARGS) -o $@ $(SRC)/$(TARGET).$(SOURCE_TYPE) 

#TODO----

$(TARGET_OUT): $(BUILD)/$(TARGET).o
	$(LD) $(LD_ARGS) -o $@ $<
	$(FIX) $(FIX_ARGS) $@

clean:
	rm -rf $(BUILD) $(TARGET_OUT)

#Make directories if necessary
$(BUILD):
	mkdir $(BUILD)
$(TEXT):
	mkdir $(TEXT)