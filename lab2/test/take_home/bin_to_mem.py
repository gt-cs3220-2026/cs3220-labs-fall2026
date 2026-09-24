#!/usr/bin/env python3
import pathlib
import sys

# objcopy's binary starts at the first section, PC 0x200.
data = bytes(0x200) + pathlib.Path(sys.argv[1]).read_bytes()
data += bytes((-len(data)) % 4)
with open(sys.argv[2], "w") as output:
    for offset in range(0, len(data), 4):
        output.write(f"{int.from_bytes(data[offset:offset + 4], 'little'):08x}\n")
