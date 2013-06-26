import sys

pad = int(sys.argv[1])

table = {}

i = 0xa5

with open('chars.tbl') as f:
    for char in f.readlines():
        char = char.strip('\n')
        if not char.startswith("="):
            table[char] = i
            i += 1
        else:
            i = int(char[1:], 16)

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
