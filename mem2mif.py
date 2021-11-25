#!/usr/bin/env python3
# coding: utf-8

"""A script to convert the handwritten .mem file to a quartus .mif format"""

if __name__ == "__main__":
    with open("program.mem", "r") as f:
        memfile = f.readlines()

    memory = {}

    for key, value in enumerate(
        [
            int(line.strip().split()[0], 16)
            for line in memfile
            if not line.startswith("//") and not (line.strip() == "")
        ]
    ):
        memory[key] = value

    with open("program.mif", "w") as f:
        f.write("WIDTH=16;\n")
        f.write(f"DEPTH=512;\n\n")
        f.write("ADRESS_RADIX=HEX;\n")
        f.write("DATA_RADIX=HEX;\n\n")
        f.write("CONTENT BEGIN\n")
        for key in memory:
            f.write(f"\t{key:03X}  :   {memory[key]:04X};\n")

        # Write all empty with C000 (gol RESET)
        f.write(f"\t[{len(memory):03X}..1FF]  :   C000;\n")
        f.write("END;")
