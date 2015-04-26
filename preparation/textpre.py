# encoding: utf-8
from __future__ import unicode_literals
import sys
import struct
from io import open

mode = sys.argv[1]
pad = int(sys.argv[2], 16)

table = {}
tablejp = {}

i = 0x00

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


with open('text/chars.tbl', encoding='utf-8') as f:
    for char in f.readlines():
        char = char.strip('\n')
        if not char.startswith("@"):
            table[char.replace('\\n', '\n')] = i
            i += 1
        else:
            i = int(char[1:], 16)
    
for line in open("text/extras/medarot1.tbl", encoding='utf-8').readlines():
    if line.strip():
        a, b = line.strip('\n').split("=", 1)
        tablejp[b.replace("\\n", '\n')] = int(a, 16)

vwf_table = [0]*0x80
with open('src/vwftable.asm') as f:
    for line in f.readlines():
        if line and not line.startswith(';'):
            for num in line.split(', '):
                try:
                    vwf_table.append(int(num.lstrip('db ')))
                except ValueError:
                    pass

#sys.stderr.write(str(vwf_table))

NL = 0x4E
NB = 0x4C

def pack_string(string, table, ignore_vwf):
    string = string.rstrip('\n').replace('\n\n', '␤').replace('\r','')
    
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
                        if even_line: word_data += chr(NL)
                        else: word_data += chr(NB)
                        #even_line = not even_line
                    elif char == "␤":
                        word_data += chr(NB)
                        #even_line = False
                    else:
                        word_data += chr(table[char])
                        word_px += vwf_table[table[char]]+1
                except KeyError: # temporary
                    sys.stderr.write("Warning: Unknown char: " + char.encode('ascii', 'backslashreplace') + "\n")
                    word_data += chr(table["?"])
                    word_px += vwf_table[table["?"]]+1
                if not ignore_vwf:
                    if char in (" ", "\n", "␤"):
                        if line_px + word_px > (18*8 if even_line else 17*8):
                            if even_line: nl = chr(NL)
                            else: nl = chr(NB)
                            text_data += line_data[:-1] + nl
                            line_data, line_px = word_data, word_px
                            even_line = not even_line
                        else:
                            line_data += word_data
                            line_px += word_px
                        word_data, word_px = b"", 0
                    if char in "\n␤":
                        text_data += line_data
                        line_data, line_px = b"", 0
                        if char == "\n":
                            even_line = not even_line
                        else:
                            even_line = True
    if not ignore_vwf:
        if line_px + word_px > (18*8 if even_line else 17*8):
            if even_line: nl = chr(NL)
            else: nl = chr(NB)
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

MODE_LITERAL = 0
MODE_REPEAT = 1
MODE_INC = 2
MODE_DEC = 3

def compress_tmap(tmap):
    compressed = b"\x01"
    literal_bytes = []
    while tmap:
        curbyte = ord(tmap[0])
        methods = {MODE_REPEAT: 0, MODE_INC: 0, MODE_DEC: 0}
        # repeat
        for i, byte in zip(range(64), tmap[1:]):
            if ord(byte) != curbyte:
                break
            methods[MODE_REPEAT] += 1
        
        # inc
        for i, byte in zip(range(64), tmap[1:]):
            if ord(byte) != (curbyte+1+i)&0xff:
                break
            methods[MODE_INC] += 1
        
        # dec
        for i, byte in zip(range(64), tmap[1:]):
            if ord(byte) != (curbyte-1-i)&0xff:
                break
            methods[MODE_DEC] += 1
        
        best = max(methods, key=methods.get)
        if methods[best] >= 1:# or curbyte == 0xfe:
            while literal_bytes:
                compressed += chr((MODE_LITERAL << 0x6) + len(literal_bytes)-1 if len(literal_bytes) < 64 else 63)
                for byte in literal_bytes[:64]:
                    compressed += chr(byte)
                literal_bytes = literal_bytes[64:]
            #if curbyte != 0xfe:
            compressed += chr((best << 0x6) + methods[best]-1)
            compressed += chr(curbyte)
            tmap = tmap[methods[best]+1:]
            #else:
            #    compressed += chr(0xfe)
            #    tmap = tmap[1:]
        else:
            literal_bytes.append(curbyte)
            tmap = tmap[1:]
        
        #print best, methods, hex(curbyte),  literal_bytes, compressed
    while literal_bytes:
        compressed += chr((MODE_LITERAL << 0x6) + len(literal_bytes)-1 if len(literal_bytes) < 64 else 63)
        for byte in literal_bytes[:64]:
            compressed += chr(byte)
        literal_bytes = literal_bytes[64:]
    compressed += b'\xff'
    return compressed


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
                string = "/0x{:x}/".format(pointer)
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
    
elif mode == "tilemaps":
    tmaps = []
    for i in range(0xf1): # XXX hardcoded
        tmap = b''
        #tmap = b"\x00"
        with open('text/tilemaps/{:02x}.txt'.format(i), 'r', encoding='utf-8') as f:
            mode = f.readline().strip()
            escape = b""
            column = 0
            for char in f.read():
                if escape:
                    escape += char
                    if len(escape) == 4:
                        assert escape.startswith('\\x')
                        tmap += chr(int(escape[2:], 16))
                        column += 1
                        #tmap += chr(table["?"])
                        escape = b""
                else:
                    if char == '\\':
                        escape = char
                    elif char == '\n':
                        if column < 0x20:
                            tmap += b"\xfe"
                        column = 0
                    elif char == " ":
                        tmap += b"\x00"
                        column += 1
                    elif char in table.keys():
                        tmap += chr(table[char])
                        column += 1
                    elif char in tablejp.keys():
                        tmap += chr(tablejp[char])
                        column += 1
                    else:
                        sys.stderr.write(u"Unknown char: "+hex(ord(char))+'\n')
                        raise ValueError()
            #tmap += b"\xff"
            tmaps.append((mode, tmap))
            #sys.stderr.write("tmap {}: {}\n".format(hex(i), hex(len(tmap))))
    pts = []
    data = b""
    for i, tilemap in enumerate(tmaps):
        mode, tilemap = tilemap
        dupe = False
        for j, t_ in enumerate(tmaps[:i]):
            if t_ == tilemap:
                offset = pts[j]
                pts.append(offset)
                dupe = True
                break
        if dupe: continue
        offset = 0x4000+len(tmaps)*2+len(data)
        #pts_data += struct.pack(b"<H", offset)
        pts.append(offset)
        if mode == "[DIRECT]":
            compressed = compress_tmap(tilemap)
        else:
            compressed = None
        #sys.stderr.write("tmap {}: {} c:{}\n".format(hex(i), hex(len(tilemap)), hex(len(compressed)) if compressed else "N/A"))
        if compressed and len(compressed) < len(tilemap)+2:
            data += compressed
        else:
            data += b'\x00'+tilemap+b'\xff'
    pts_data = b""
    for ptr in pts:
        pts_data += struct.pack(b"<H", ptr)
    #sys.stderr.write(hex(len(data))+'\n')
    assert len(pts_data+data) <= pad, "Tilemap data too long: "+str(hex(len(pts_data+data)))+'\n'
    sys.stdout.write(pts_data+data)




