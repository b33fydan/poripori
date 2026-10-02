#!/usr/bin/env python3
"""Check data/arecibo/bits.txt before it goes on screen.

    python3 tools/verify_arecibo.py [render.png]

1. The string is 1,679 bits (73 x 23), with the SHA-1 that four sources
   share (see data/arecibo/SOURCES.md).
2. Cell by cell it matches Wikimedia Commons' one-pixel-per-bit picture
   (data/arecibo/reference-commons-tiny-cc0.png, CC0, black = 1).
3. Decoded, it reads as published: the numbers 1 to 10 left to right, the
   atomic numbers 1, 6, 7, 8, 15, the formulas of DNA's sugar, bases and
   phosphate, a nucleotide count of 4,294,441,822, a human 14 wavelengths
   tall, a population of 4,292,853,750 and a telescope 2,430 wavelengths
   across.
4. Every lit cell falls in a region of data/arecibo/sections.json.

With a path, it also writes a 10 px per bit picture of the grid, to compare
by eye with the published one.
"""

import hashlib
import json
import sys
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parent.parent
DATA = ROOT / "data" / "arecibo"
ROWS, COLUMNS = 73, 23
SHA1 = "483d7c33edff5a806cd8c04d095cae3ccc5cb6f4"


def main():
    bits = (DATA / "bits.txt").read_text().strip()
    ok = True

    def check(label, passed, detail=""):
        nonlocal ok
        ok &= passed
        print(f"{'PASS' if passed else 'FAIL'}  {label}{('  ' + detail) if detail else ''}")

    check("1,679 bits of 0 and 1", len(bits) == ROWS * COLUMNS and set(bits) <= {"0", "1"}, f"{len(bits)} bits, {bits.count('1')} ones")
    check("SHA-1 shared by Cornell, Wikipedia, U Oregon and OEIS", hashlib.sha1(bits.encode()).hexdigest() == SHA1)
    grid = [[int(bits[r * COLUMNS + c]) for c in range(COLUMNS)] for r in range(ROWS)]

    reference = Image.open(DATA / "reference-commons-tiny-cc0.png").convert("L")
    check("reference picture is 23 x 73", reference.size == (COLUMNS, ROWS), str(reference.size))
    mismatches = [(r, c) for r in range(ROWS) for c in range(COLUMNS)
                  if (reference.getpixel((c, r)) < 128) != bool(grid[r][c])]
    check("matches the Commons picture cell by cell", not mismatches, f"{len(mismatches)} mismatched cells {mismatches[:5]}")

    def column(c, rows):
        """A column read top to bottom, most significant bit first."""
        return int("".join(str(grid[r][c]) for r in rows), 2)

    # The numbers 1 to 10: one per marked column (marker on row 3), read on
    # rows 0-2; 8, 9 and 10 carry their 8 on the next column.
    markers = [c for c in range(COLUMNS) if grid[3][c]]
    numbers = [column(c, range(0, 3)) + (8 * column(c + 1, range(0, 3)) if c + 1 < COLUMNS and c + 1 not in markers else 0)
               for c in markers]
    check("numbers read 1 to 10, left to right", numbers == list(range(1, 11)), str(numbers))

    atoms = [column(c, range(5, 9)) for c in range(9, 14)]
    check("atomic numbers H C N O P = 1 6 7 8 15", atoms == [1, 6, 7, 8, 15] and all(grid[9][c] for c in range(9, 14)), str(atoms))

    # Formulas: five 3-bit columns per group, counting H, C, N, O and P atoms.
    def formula(r0, c0):
        counts = [column(c, range(r0, r0 + 3)) for c in range(c0, c0 + 5)]
        return "".join(f"{e}{n if n > 1 else ''}" for e, n in zip("HCNOP", counts) if n)

    # As published: deoxyribose C5H7O, adenine C5H4N5, thymine C5H5N2O2,
    # cytosine C4H4N3O, guanine C5H4N5O, phosphate PO4 (written here in H C N O P order).
    sugar, adenine, thymine, cytosine, guanine, phosphate = "H7C5O", "H4C5N5", "H5C5N2O2", "H4C4N3O", "H4C5N5O", "O4P"
    formulas = [[formula(r0, c0) for c0 in groups] for r0, groups in ((11, (0, 6, 12, 18)), (16, (0, 18)), (21, (0, 6, 12, 18)), (26, (0, 18)))]
    expected = [[sugar, adenine, thymine, sugar], [phosphate, phosphate], [sugar, cytosine, guanine, sugar], [phosphate, phosphate]]
    check("DNA formulas: deoxyribose, A, T, C, G, phosphate", formulas == expected, str(formulas))

    dna = column(11, range(26, 42)) * 2 ** 16 + column(10, range(26, 42))
    check("nucleotide count 4,294,441,822", dna == 4_294_441_822 and grid[42][10] == 1, f"{dna:,}")

    height = sum(grid[50][c] << (c - 1) for c in range(1, 5))
    check("human height 14 wavelengths", height == 14 and grid[50][0] == 1, str(height))

    population = sum(grid[r][c] << (6 * (r - 48) + (c - 17)) for r in range(48, 54) for c in range(17, 23))
    check("world population 4,292,853,750", population == 4_292_853_750 and grid[48][16] == 1, f"{population:,}")

    telescope = int("".join(str(grid[71][c]) for c in range(7, 13)) + "".join(str(grid[72][c]) for c in range(7, 13)), 2)
    check("telescope 2,430 wavelengths across", telescope == 2430 and grid[72][13] == 1, f"{telescope:,}")

    sections = json.loads((DATA / "sections.json").read_text())
    regions = sections["regions"]
    unassigned = []
    for r in range(ROWS):
        for c in range(COLUMNS):
            if grid[r][c] and not any(reg["rows"][0] <= r < reg["rows"][1] and reg["columns"][0] <= c < reg["columns"][1] for reg in regions):
                unassigned.append((r, c))
    check("every lit cell has a region", not unassigned, f"{len(unassigned)} unassigned {unassigned[:5]}")

    if len(sys.argv) > 1:
        image = Image.new("L", (COLUMNS * 10, ROWS * 10), 0)
        for r in range(ROWS):
            for c in range(COLUMNS):
                if grid[r][c]:
                    image.paste(255, (c * 10, r * 10, c * 10 + 10, r * 10 + 10))
        image.save(sys.argv[1])
        print(f"wrote {sys.argv[1]}")

    print("all checks pass" if ok else "SOME CHECKS FAILED")
    sys.exit(0 if ok else 1)


if __name__ == "__main__":
    main()
