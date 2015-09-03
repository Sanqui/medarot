export LC_CTYPE=C

#User defined 

TARGET := medarot
TARGET_TYPE := gbc
SOURCE_TYPE := asm
PYTHON := python

#Resource names
RSRC_TEXT := Battles Dialogue_1 Dialogue_2 Dialogue_3
RSRC_SNIP := Snippet_1 Snippet_2 Snippet_3 Snippet_4 Snippet_5
RSRC_LIST := attacks attributes items medarots medarotters partdescriptions skills medals medarots
ADDITIONAL_FILE_PREFIX := Additional_

#Type of downloaded text data (RSRC_*)
TEXT_TYPE := mediawiki
TEXT_TYPE_LIST := txt
BIN_TYPE := bin

#Directory information
BASE := .

#Output directory for intermediate files
BUILD := $(BASE)/build
BUILD_ADDITIONAL := $(BUILD)/additional
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
	$(PYTHON) preparation/get_text.py

#Generate Binary files (tilemaps, text, lists, etc...)
preparation: $(BUILD) $(TEXT) $(BUILD_ADDITIONAL) $(LISTS_OBJ) $(SNIPPETS_OBJ) $(STORYTEXT_OBJ) $(BUILD)/tilemaps.bin

#Build tilemaps
$(BUILD)/tilemaps.bin: $(wildcard $(TEXT)/tilemaps/*.txt) $(SRC)/vwftable.asm $(TEXT)/chars.tbl
	$(PYTHON) preparation/textpre.py tilemaps 0x4000 > $(BUILD)/tilemaps.bin

#Handle snippets and dialog
$(BUILD)/%.$(BIN_TYPE): $(TEXT)/%.$(TEXT_TYPE) $(SRC)/vwftable.asm 
	$(PYTHON) preparation/textpre.py bank 0x4000 $(BUILD_ADDITIONAL) < $(TEXT)/$(*F).$(TEXT_TYPE) > $(BUILD)/$(*F).$(BIN_TYPE)

#Handle Lists
$(BUILD)/%.$(BIN_TYPE): $(TEXT)/%.$(TEXT_TYPE_LIST)
	$(PYTHON) preparation/textpre.py list < $(TEXT)/$(*F).$(TEXT_TYPE_LIST) > $(BUILD)/$(*F).$(BIN_TYPE)
	
#ROM object is dependent on all asm files, but they're all grouped into a single asm (e.g. medarot.asm)
$(BUILD)/$(TARGET).o: $(wildcard $(SRC)/*.$(SOURCE_TYPE)) preparation autopad $(wildcard $(BUILD)/*.$(BIN_TYPE))
	$(CC) $(CC_ARGS) -o $@ $(SRC)/$(TARGET).$(SOURCE_TYPE) 

$(TARGET_OUT): $(BUILD)/$(TARGET).o
	$(LD) $(LD_ARGS) -o $@ $<
	$(FIX) $(FIX_ARGS) $@

rom: 
	$(CC) $(CC_ARGS) -o $(BUILD)/$(TARGET).o $(SRC)/$(TARGET).$(SOURCE_TYPE)
	$(LD) $(LD_ARGS) -o $(TARGET_OUT) $(BUILD)/$(TARGET).o
	$(FIX) $(FIX_ARGS) $(TARGET_OUT)

autopad: $(SNIPPETS_OBJ) $(STORYTEXT_OBJ) 
	$(PYTHON) preparation/autopad.py 0x4000 $(BUILD_ADDITIONAL)/*.$(BIN_TYPE)
	

clean: cleanadditional
	rm -rf $(BUILD) $(TARGET_OUT)

cleanadditional:
	rm -rf $(BUILD_ADDITIONAL)

#Make directories if necessary
$(BUILD):
	mkdir $(BUILD)
	
$(BUILD_ADDITIONAL):
	mkdir $(BUILD_ADDITIONAL)
	
$(TEXT):
	mkdir $(TEXT)
