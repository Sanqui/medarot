#gawk sort order
export LC_CTYPE=C

.SUFFIXES: .asm .o .gbc

all: medarot.gbc

text/text: 
	python textpre.py list 0x10 < text/medals.txt > text/medals.bin
	python textpre.py list 0x10 < text/medarots.txt > text/medarots.bin
	python textpre.py bank 0x4000 < text/Battles.mediawiki > text/Battles.bin
	python textpre.py bank 0x4000 < text/Dialogue_1.mediawiki > text/Dialogue_1.bin
	python textpre.py bank 0x4000 < text/Dialogue_2.mediawiki > text/Dialogue_2.bin
	python textpre.py bank 0x4000 < text/Dialogue_3.mediawiki > text/Dialogue_3.bin
	python textpre.py bank 0x2000 < text/Snippet_1.mediawiki > text/Snippet_1.bin
	python textpre.py bank 0x2000 < text/Snippet_2.mediawiki > text/Snippet_2.bin
	python textpre.py bank 0x2000 < text/Snippet_3.mediawiki > text/Snippet_3.bin
	python textpre.py bank 0x2000 < text/Snippet_4.mediawiki > text/Snippet_4.bin
	python textpre.py bank 0x2000 < text/Snippet_5.mediawiki > text/Snippet_5.bin
	python textpre.py tilemaps 0x4000 > tilemaps.bin
	touch text/text

medarot.o: medarot.asm text text/text
	rgbasm -o medarot.o medarot.asm

medarot.gbc: medarot.o
	rgblink -o $@ $<
	rgbfix -v -k 9C -l 0x33 -m 0x13 -p 0 -r 3 -t "MEDAROT KABUTO" $@

clean:
	rm -f medarot.o medarot.gbc text/medarots.bin text/battles.bin text/story1.bin text/text
