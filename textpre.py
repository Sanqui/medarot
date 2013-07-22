import sys
import struct

mode = sys.argv[1]
pad = int(sys.argv[2], 16)

table = {}
tablejp = {}

i = 0xa5


with open('chars.tbl') as f:
    for char in f.readlines():
        char = char.strip('\n')
        if not char.startswith("="):
            table[char] = i
            i += 1
        else:
            i = int(char[1:], 16)
    
for line in open("extras/medarot1.tbl").readlines():
    if line.strip():
        a, b = line.strip('\n').split("=", 1)
        tablejp[int(a, 16)] = b.replace("\\n", '\n')

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
            
            for char in string:
                try:
                    text_data += chr(table[char]) if len(eng) else chr(tablejp[char])
                except KeyError: # temporary
                    pass
            text_data += b"\x4f\x00" # end chars
    
    data = pts_data + text_data
    data = data.ljust(pad-1, b'\x00') # XXX why -1?
    
    assert len(data) <= pad, "Data size exceeds pad value: "+ hex(len(data))+" > "+hex(pad)
    
    print data
        
