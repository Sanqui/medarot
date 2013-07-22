#gawk sort order
export LC_CTYPE=C

.SUFFIXES: .asm .o .gbc

all: medarot.gbc

text/medarots.bin: 
	python textpre.py list 16 < text/medarots.txt > $@

text/battles.bin: 
	python textpre.py bank < text/battles.mediawiki > $@

medarot.o: medarot.asm text/medarots.bin text/battles.bin
	rgbasm -o medarot.o medarot.asm

medarot.gbc: medarot.o
	rgblink -o $@ $<
	rgbfix -v -k 9C -l 0x33 -m 0x03 -p 0 -r 3 -t "MEDAROT KABUTO" $@
	cmp baserom.gbc $@

clean:
	rm -f medarot.o medarot.gbc text/medarots.bin text/battles.bin
