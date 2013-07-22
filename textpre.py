import sys
import struct

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


with open('chars.tbl') as f:
    for char in f.readlines():
        char = char.strip('\n')
        if not char.startswith("="):
            table[char.replace('\\n', '\n')] = i
            i += 1
        else:
            i = int(char[1:], 16)
    
for line in open("extras/medarot1.tbl").readlines():
    if line.strip():
        a, b = line.strip('\n').split("=", 1)
        tablejp[b.replace("\\n", '\n')] = int(a, 16)

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
    
    mediawiki = sys.stdin.read()
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
            pts_data += struct.pack("<H", offsets[int(eng.lstrip('='), 16)])
            
        else:
            offset = 0x4000+len(pointers)*2+len(text_data)
            offsets[pointer] = offset
            pts_data += struct.pack("<H", offset)
            
            
            if len(eng):
                text_data += b"\x49" # set english
                string = eng
            else:
                string = jap
            
            special = ""
            ended = False
            skip = False
            
            for char in string:
                if skip:
                    skip = False
                    continue
                if special:
                    if char == ">":
                        sys.stderr.write( special + "\n")
                        special = special[1:] # lstrip <
                        try:
                            special = int(special, 16)
                            text_data += chr(special)
                        except ValueError:
                            s = specials[special[0]]
                            val = special[1:]
                            text_data += chr(s.byte)
                            matched = False
                            for value, name in s.names.items():
                                if name == val:
                                    val = value
                                    matched = True
                            
                            if not matched: val = int(val, 16)
                            
                            if not val: val = s.default
                            
                            if s.bts:
                                fmt = "<"+["", "B", "H"][s.bts]
                                text_data += struct.pack(fmt, val)
                            
                            if s.end: ended = True
                        
                        special = ""
                    else:
                        special += char
                else:
                    if char == "\\": skip = True
                    if char == "<":
                        special = char
                    else:
                        try:
                            text_data += chr(table[char]) if len(eng) else chr(tablejp[char])
                        except KeyError: # temporary
                            sys.stderr.write("Warning: Unknown char: " + char + "\n")
                            text_data += chr(table["?"])
            if not ended:
                text_data += b"\x4f\x00" # end chars
    
    data = pts_data + text_data
    data = data.ljust(pad-1, b'\x00') # XXX why -1?
    
    assert len(data) <= pad, "Data size exceeds pad value: "+ hex(len(data))+" > "+hex(pad)
    
    print data
        
