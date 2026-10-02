# The Arecibo Message: sources for the bits

`bits.txt` holds the message's 1,679 bits as one line, 73 rows of 23, row by row from the top. `tools/verify_arecibo.py` checks it; every check passed on 2026-10-02.

## The bits: four sources, identical

All four were fetched on 2026-10-02. Each gives the same 1,679 bits (397 ones). The SHA-1 of the bit string is `483d7c33edff5a806cd8c04d095cae3ccc5cb6f4`.

1. **Cornell University News Service:** the official 1999 text file. Cornell ran the National Astronomy and Ionosphere Center, which operated Arecibo. This is the authoritative source. It was fetched through the Wayback Machine's August 2003 capture:
   https://web.archive.org/web/20030815074830id_/http://www.news.cornell.edu:80/releases/Nov99/Arecibocode.txt
   - **Do not use the earlier capture.** The February 2001 capture of the same file has three wrong bits, at (row, column) (0, 6), (1, 8) and (1, 12). They break the numbers 4, 5 and 7. Copies of that version may still circulate:
     https://web.archive.org/web/20010227222805id_/http://www.news.cornell.edu:80/releases/Nov99/Arecibocode.txt
2. **Wikipedia, "Arecibo message":** the collapsed "Message as binary string" box, revision 1377734615 (2026-09-30):
   https://en.wikipedia.org/w/index.php?title=Arecibo_message&oldid=1377734615
3. **University of Oregon,** Jim Brau's ASTR 123 notes. Wikipedia cites this page for its bits, so sources 2 and 3 aren't independent of each other:
   https://pages.uoregon.edu/jimbrau/astr123/Notes/ch28/73by23.html
4. **OEIS A248747,** the 73-row picture in its example section. It was read through the OEIS Foundation's data mirror, because oeis.org served a bot check:
   https://raw.githubusercontent.com/oeis/oeisdata/main/seq/A248/A248747.seq (canonical page https://oeis.org/A248747)

## The picture

- **Reference image:** `reference-commons-tiny-cc0.png` is Wikimedia Commons' "Arecibo message tiny.png" by Pengo, licensed **CC0**. It has one pixel per bit, with black meaning 1 (SHA-1 `65b3c8331cad9afc506c16e5be8ab55c48e36d77`):
  https://commons.wikimedia.org/wiki/File:Arecibo_message_tiny.png
- **Results:**
  - `bits.txt` matches it cell for cell, with 0 mismatches.
  - It also matched the coloured and monochrome Commons SVGs, with 0 mismatches. Those are by Arne Nordmann and others, CC BY-SA 3.0. They were used for checking only and aren't in this repository.

## Orientation

- **Rows:** in every source, row 0 is the top. The numbers come first and the telescope last.
- **Today's standard picture** (Wikipedia and Commons, also reused by the Arecibo Observatory's 2019–2022 message challenge) puts the first bit of each row on the left. The numbers 1 to 10 then read left to right, and the Sun is on the left.
- **The 1970s and 1999 pictures** (Cornell, the SETI Institute, U Oregon) are the mirror image. In those, each row is read right to left, as Cornell's 1999 caption says.
- **The film uses today's standard orientation,** the picture viewers know. Nothing about the bits changes; only the picture is flipped.

## Sections and decoded values

`sections.json` assigns every lit cell to a region and a chapter, in reading order from top to bottom. The regions are worked out from the bits, and they agree with the grouping in the coloured Commons picture. The verifier decodes each region's numbers and checks them against the published values:

| Chapter | Rows | Decodes to |
|---|---|---|
| Numbers | 0–3 | 1 to 10 |
| Elements | 5–9 | atomic numbers 1, 6, 7, 8, 15 (H, C, N, O, P) |
| Formulas | 11–29 | deoxyribose C5H7O, adenine C5H4N5, thymine C5H5N2O2, cytosine C4H4N3O, guanine C5H4N5O, phosphate PO4 |
| DNA | 26–45 | nucleotide count 4,294,441,822 (columns 10–11), and the double helix |
| Human | 45–54 | a human figure, height 14 wavelengths (1.764 m at 126 mm), world population 4,292,853,750 |
| Solar System | 56–59 | the Sun and nine planets, with Earth raised toward the human |
| Telescope | 60–72 | the Arecibo dish, 2,430 wavelengths across (306.18 m at 126 mm) |

- **Still to source:** the 126 mm wavelength and the other facts that will appear on screen are listed with their sources in `docs/FACTS.md` as they're added.
- **Not seen:** the primary paper's figure. The paper is Staff of the NAIC, "The Arecibo Message of November, 1974", *Icarus* 26, 462–466 (1975), doi:10.1016/0019-1035(75)90116-5. It's paywalled.
