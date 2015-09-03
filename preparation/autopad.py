from io import open
import sys

size = int(sys.argv[1],16)

for s in sys.argv[2:]:
    file = open(s,'ab')
    file.seek(0,2)
    i = size - file.tell()
    str = ''.join([b'\x00'] * i)
    file.write(str)
    file.close()


