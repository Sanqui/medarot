# encoding: utf-8
from __future__ import unicode_literals
import sys
import struct
from io import open

mode = sys.argv[1]
pad = int(sys.argv[2], 16)

table = {}
tablejp = {}

i = 0xa5

# Look at me!  I can copy-paste!
class Special():
    def __init__(self, byte, default=0, bts=1, end=False, names=None):
        self.byte = byte
        self.default = default
        self.bts = bts
        self.end = end
        self.names = names if names else {}

specials = {}
specials["&"] = Special(0x4b, bts=2, names={0xC923: "NAME"})
specials['S'] = Special(0x4d, default=2)
specials['*'] = Special(0x4f, end=True)
specials['`'] = Special(0x50, bts=0, end=True)


with open('chars.tbl', encoding='utf-8') as f:
    for char in f.readlines():
        char = char.strip('\n')
        if not char.startswith("="):
            table[char.replace('\\n', '\n')] = i
            i += 1
        else:
            i = int(char[1:], 16)
    
for line in open("extras/medarot1.tbl", encoding='utf-8').readlines():
    if line.strip():
        a, b = line.strip('\n').split("=", 1)
        tablejp[b.replace("\\n", '\n')] = int(a, 16)

vwf_table = [0]*0x80
with open('vwftable.asm') as f:
    for line in f.readlines():
        if line and not line.startswith(';'):
            for num in line.split(', '):
                try:
                    vwf_table.append(int(num.lstrip('db ')))
                except ValueError:
                    pass

#sys.stderr.write(str(vwf_table))

def pack_string(string, table, ignore_vwf):
    string = string.rstrip('\n')
    
    text_data = b""
    line_data = b""
    line_px = 0
    word_data = b""
    word_px = 0
    
    special = ""
    ended = False
    skip = False
    
    even_line = True
    
    for char in string:
        if skip:
            skip = False
            continue
        if special:
            if char in ">»":
                #sys.stderr.write( special + "\n")
                special = special[1:] # lstrip <
                is_literal = True
                try:
                    special_num = int(special, 16)
                except ValueError: # temporary
                    is_literal = False
                    
                if is_literal and not special.startswith("D"):
                    if special_num > 255:
                        sys.stderr.write("Warning: Invalid literal special {} (0x{:3x})".format(special_num, special_num))
                        continue
                    word_data += chr(special_num)
                    if not ignore_vwf:
                        word_px += vwf_table[special_num]
                else:
                    s = special[0]
                    if s not in specials.keys():
                        sys.stderr.write("Warning: Invalid special: {}".format(special))
                        special = ""
                        continue
                    s = specials[s]
                    val = special[1:]
                    word_data += chr(s.byte)
                    matched = False
                    for value, name in s.names.items():
                        if name == val:
                            val = value
                            matched = True
                    
                    if not matched: val = int(val, 16)
                    
                    if val == "": val = s.default
                    
                    if s.bts:
                        fmt = b"<"+(b"", b"B", b"H")[s.bts]
                        word_data += struct.pack(fmt, val)
                    
                    if s.end: ended = True
                    
                    if special[0] == "&":
                        if val == 0xd448: # num
                            word_px += 3*8
                        else:
                            word_px += 8*8
                
                special = ""
            else:
                special += char
        else:
            if char == "\\": skip = True
            if char in "<«":
                special = char
            else:
                try:
                    if char == "\n":
                        if even_line: word_data += chr(0x4e)
                        else: word_data += chr(0x4c)
                        even_line = not even_line
                    else:
                        word_data += chr(table[char])
                        word_px += vwf_table[table[char]]+1
                except KeyError: # temporary
                    sys.stderr.write("Warning: Unknown char: " + char.encode('ascii', 'backslashreplace') + "\n")
                    word_data += chr(table["?"])
                    word_px += vwf_table[table["?"]]+1
                if not ignore_vwf:
                    if char in (" ", "\n"):
                        if line_px + word_px > (18*8 if even_line else 17*8):
                            if even_line: nl = chr(0x4e)
                            else: nl = chr(0x4c)
                            even_line = not even_line
                            text_data += line_data[:-1] + nl
                            line_data, line_px = word_data, word_px
                            even_line = not even_line
                        else:
                            line_data += word_data
                            line_px += word_px
                        word_data, word_px = b"", 0
                    if char == "\n":
                        text_data += line_data
                        line_data, line_px = b"", 0
                        even_line = not even_line
    if not ignore_vwf:
        if line_px + word_px > (18*8 if even_line else 17*8):
            if even_line: nl = chr(0x4e)
            else: nl = chr(0x4c)
            text_data += line_data[:-1] + nl
            line_data = word_data
        else:
            line_data += word_data
        text_data += line_data
    else:
        text_data = word_data
    
    
    if not ended:
        text_data += b"\x4f\x00" # end chars
    
    return text_data


if mode == "list":
    for line in sys.stdin.readlines():
        bts = b""
        for char in line.strip():
            bts += chr(table[char])
        
        bts += b"\x50"
        
        if len(bts) > pad:
            raise ValueError("Too long: ",line)
        
        while len(bts) < pad:
            bts += b"\x00"
        sys.stdout.write(bts)

elif mode == "bank":
    pointers = {}
    
    mediawiki = sys.stdin.read().decode('utf-8')
    mediawiki = mediawiki[mediawiki.find("{|"):]
    rows = mediawiki.split("|-")
    for row in rows:
        cols = row.split("\n|")[1:]
        if len(cols) == 3:
            pointers[int(cols[0], 16)] = (cols[1].rstrip(), cols[2].rstrip())
    
    pts_data = b""
    text_data = b""
    
    offsets = {}
    
    for pointer in sorted(pointers.keys()):
        
            
        jap, eng = pointers[pointer]
        if eng.startswith("="):
            #jap, eng = pointers[int(eng.lstrip('='), 16)]
            pts_data += struct.pack(b"<H", offsets[int(eng.lstrip('='), 16)])
            
        else:
            offset = 0x4000+len(pointers)*2+len(text_data)
            offsets[pointer] = offset
            pts_data += struct.pack(b"<H", offset)
            
            
            if len(eng):
                text_data += b"\x49" # set english
                string = eng
            else:
                text_data += b"\x49" # set english
                string = "Some moonspeak"
                eng = string
                #text_data += b"\x48" # set japanese
                #string = jap
            
            #sys.stderr.write(string)
            #sys.stderr.write(string[2])
            
            text_data += pack_string(string, table if len(eng) else tablejp, not len(eng))
    
    data = pts_data + text_data
    data = data.ljust(pad-1, b'\x00') # XXX why -1?
    
    assert len(data) <= pad, "Data size exceeds pad value: "+ hex(len(data))+" > "+hex(pad)
    
    print data
        
