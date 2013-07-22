#gawk sort order
export LC_CTYPE=C

.SUFFIXES: .asm .o .gbc

all: medarot.gbc

text/text: 
	python textpre.py list 0x10 < text/medarots.txt > text/medarots.bin
	python textpre.py bank 0x4000 < text/battles.mediawiki > text/battles.bin
	python textpre.py bank 0x4000 < text/story1.mediawiki > text/story1.bin
	touch text/text

medarot.o: medarot.asm text text/text
	rgbasm -o medarot.o medarot.asm

medarot.gbc: medarot.o
	rgblink -o $@ $<
	rgbfix -v -k 9C -l 0x33 -m 0x1b -p 0 -r 3 -t "MEDAROT KABUTO" $@

clean:
	rm -f medarot.o medarot.gbc text/medarots.bin text/battles.bin text/story1.bin text/text
