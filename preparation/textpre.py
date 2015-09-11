# encoding: utf-8
from __future__ import unicode_literals
import sys
import struct
from io import open

mode = sys.argv[1]
if "list" not in mode:
	pad = int(sys.argv[2], 16) #Ignored for list

if "bank" in mode:
    build = sys.argv[3]

table = {}
tablejp = {}

i = 0x00

global additional_file
global additional_file_bank
global additional_file_ptr

# Look at me!  I can copy-paste!
class Special():
    def __init__(self, byte, default=0, bts=1, end=False, names=None):
        self.byte = byte
        self.default = default
        self.bts = bts
        self.end = end
        self.names = names if names else {}

specials = {}
specials["&"] = Special(0x4b, bts=3, names={0x00C923: "NAME", 0x00DED1: "MEDA"})
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

def set_additional_file(buf = 0):
    global additional_file
    global additional_file_ptr
    global additional_file_bank
    n = 0
    additional_file = build + "/Additional_" + str(n) + ".bin"
    f = open(additional_file,'ab')
    f.seek(0,2) 
    pos = 0
    while(f.tell() + buf >= pad-1):
        
        f.close()
        n = n+1
        additional_file = build + "/Additional_" + str(n) + ".bin"
        f = open(additional_file,'ab')
        pos = f.seek(0,2)
     
    additional_file_bank = 0x2c + n
    additional_file_ptr = 0x4000 + pos
    return f

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
    quote_flag = False
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
                    
                    if not matched:
                        val = int(val, 16)
                    
                    if val == "": val = s.default
                    
                    if s.bts:
                        fmt = b"<"+(b"", b"B", b"H", b"xH")[s.bts]
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
                        if(char == "\""
                        and quote_flag == True):
                            word_data += chr(table["~\""])
                            word_px += vwf_table[table["~\""]]+1
                            quote_flag = False
                        elif(char == "\""):
                            quote_flag = True
                            word_data += chr(table[char])
                            word_px += vwf_table[table[char]]+1
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
    pad = 0
    for line in sys.stdin.readlines():
        if pad == 0:
            pad = int(line)
            continue
        if len(line) == 0: #Even if it isn't translated, the index or jp text should be shown
            continue
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
    global additional_file_ptr
    pointers = {}
    total_ptr = 0 #Total unique strings
    mediawiki = sys.stdin.read().decode('utf-8')
    mediawiki = mediawiki[mediawiki.find("{|"):]
    rows = mediawiki.split("|-")
    for row in rows:
        cols = row.split("\n|")[1:]
        if len(cols) == 4:
            pointers[int(cols[0], 16)] = (cols[2].rstrip(), cols[3].rstrip())
            if(not pointers[int(cols[0], 16)][1].startswith("=")):
                total_ptr += 1
            
    pts_data = b""
    text_data = b""
    
    offsets = {}

    free_space = pad-2*len(pointers)
    
    
    max_size = free_space/total_ptr #Enforce a max size for each unique string    
    file = set_additional_file()
        
    assert max_size > 4, "Maximum possible size of text below 5, need to find another solution"

    #Super lazy copy paste, this can be made wayyyy more efficient but as of the time of writing this, it's not worth the effort! 
    for pointer in sorted(pointers.keys()):   
        jap, eng = pointers[pointer]
        text_data_tmp = b""
		
        if not eng.startswith("="):            
            if len(eng):
                text_data_tmp += b"\x49" # set english
                string = eng
            else:
                text_data_tmp += b"\x49" # set english
                string = "/0x{:x}/".format(pointer)
                eng = string
                #text_data += b"\x48" # set japanese
                #string = jap
            
            text_data_tmp += pack_string(string, table if len(eng) else tablejp, not len(eng))
            l = len(text_data_tmp)
            
            if(l > max_size):
                free_space -= max_size
            else:
                free_space -= l
                
    
    assert free_space >= 0, "Free space less than 0"

    sys.stderr.write("Unique Strings: " + str(total_ptr) + "\n")
    sys.stderr.write("Free Space: " + str(free_space) + "\n")
    sys.stderr.write("Max Size: " + str(max_size) + "\n")
                
    #for pointer in sorted(pointers.keys()):
    for pointer in sorted(pointers.keys()):
        jap, eng = pointers[pointer]
        pts_data_tmp = b""
        text_data_tmp = b""

        if eng.startswith("="):
            #jap, eng = pointers[int(eng.lstrip('='), 16)]
            pts_data_tmp += struct.pack(b"<H", offsets[int(eng.lstrip('='), 16)])
        else:            
            offset = 0x4000+len(pointers)*2+len(text_data)
            offsets[pointer] = offset
            pts_data_tmp += struct.pack(b"<H", offset)
            
            if len(eng):
                text_data_tmp += b"\x49" # set english
                string = eng
            else:
                text_data_tmp += b"\x49" # set english
                string = "/0x{:x}/".format(pointer)
                eng = string
                #text_data += b"\x48" # set japanese
                #string = jap
            
            text_data_tmp += pack_string(string, table if len(eng) else tablejp, not len(eng))
            l = len(text_data_tmp)            
            
            if(l > max_size + free_space):
                tmp_new = b""
                tmp = text_data_tmp[0:max_size+free_space-5]
                j = ord(tmp[-1])
                if(\
                j == 0x4d\
                or j == 0x4f):
                    tmp_new += tmp[-1]
                    tmp = tmp[0:len(tmp)-1] + b'\x00'
                elif(b'\x4b' in tmp[-3:]):
                    idx = tmp[-3:].index(b'\x4b')
                    tmp_new += tmp[-3+idx:]
                    tmp = tmp[0:max_size+free_space-5+idx].ljust(max_size+free_space-1, b'\x00')   
                tmp_new += text_data_tmp[max_size+free_space-5:] + b'\x50'
                s = struct.pack(b"<BBHB", 0x4B, additional_file_bank, additional_file_ptr, 0x50)
                tmp += s              
                text_data_tmp = tmp
                if(file.tell() + len(tmp_new) > pad-1):
                    file.close()
                    file = set_additional_file(len(tmp_new))
                file.write(tmp_new)
                additional_file_ptr += len(tmp_new)
                free_space = 0 #If we enter this part, it means there's no free space left to use
            elif (l > max_size):
                free_space -= (l-max_size)
    
        text_data += text_data_tmp
        pts_data += pts_data_tmp
                      
    data = pts_data + text_data
    data = data.ljust(pad-1, b'\x00') # XXX why -1?

    sys.stdout.write(data)

    file.close()
    
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
