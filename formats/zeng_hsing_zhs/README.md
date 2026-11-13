# Zeng Hsing ZHS

| | |
|---|---|
| Spec | [`zeng_hsing_zhs.ksy`](zeng_hsing_zhs.ksy) |
| Extensions | `.zhs` |
| Vendor | Zeng Hsing |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Format with a color table and thread text. Stitch deltas are stored with their bits interleaved over two bytes.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 15 | Unknown |
| 0x0f | 4 | Offset of the stitch records (u32 LE) |
| 0x13 | 4 | Offset of the color table (u32 LE) |
| color table | 1 | Number of colors |
| | 3 × n | Colors, 24-bit big-endian RGB |
| | 2 | Length of thread text (u16 LE) |
| | n | Thread text, UTF-8 |
| stitch offset | 3 × n | Records: control, byte 1, byte 2 |

The two blocks are placed through the offsets; the spec reads them as instances. The reader's thread text format: split on `&$` into one entry per color (text before the first one is dropped); each entry split on `&#` into chart, description and catalog number (catalog number without its last two characters).

Records: X takes its even bits from byte 1 and odd bits from byte 2 (`(b1 & 0x55) | (b2 & 0xaa)`); Y the opposite (`(b2 & 0x55) | (b1 & 0xaa)`). Each is a signed byte; values of 63 and above (−63 and below) get one more unit away from zero. Control: `0x02` stitch, `0x01` jump, `0x04` color change, `0x80` end, `0x10` checksum (ignored), `0x41` unknown. The reader sums the deltas of records it does not act on into the next acted-on record and negates Y for its own coordinate system; those are consumer behaviors and not part of the spec.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves, Y up.

## Open questions

- The 15 bytes before the offsets.
- What the `0x41` and checksum records contain and when they occur.
- Where the stitch block ends if the file has data after it; the spec reads until control `0x80` or end of file.
- Unit of the deltas and the reason for the ±1 correction.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.zhs` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.zhs` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `ZhsReader.py` (MIT): offsets, color table, thread text, interleaved record layout, read for understanding.
- No files observed.
