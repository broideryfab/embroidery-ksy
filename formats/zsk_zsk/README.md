# ZSK USA ZSK

| | |
|---|---|
| Spec | [`zsk_zsk.ksy`](zsk_zsk.ksy) |
| Extensions | `.zsk` |
| Vendor | ZSK USA |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format, not to be confused with [ZSK DSZ](../zsk_dsz/README.md). Only libembroidery documents it, and only through its reader; the result is the least certain spec in this set.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 0x230 | Unknown |
| 0x230 | 1 + 3 + 72 per color | Color entries: number, RGB, 72 unknown bytes; ended by a number byte 0 |
| after list | 0x2e | Unknown |
| then | 3 × n | Records: flags, X magnitude, Y magnitude |

Flags: bit 3 X negative, bit 2 Y negative, bit 1 jump, bit 5 special record: X magnitude 2 is a trim, 0xff the end, anything else a color change to the (1-based) color number in the Y byte (when not 0). libembroidery's writer stores the color count in the first number byte and counts down; the last entry has number 0.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves. The reader reads the three bytes as signed values, which would make magnitudes above 127 negative; this looks like a bug and the spec reads them unsigned. Y direction unknown.

## Open questions

- Everything in the first 0x230 bytes and the 72 bytes per color.
- RGB channel order.
- Whether magnitudes are signed or unsigned, and the Y direction.
- The 0x2e bytes after the color list.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.zsk` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.zsk` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- libembroidery `unsorted.c` `readZsk` / `writeZsk` (Zlib): offsets, color list, record layout, read for understanding.
- pyembroidery has no reader for this format.
- No files observed.
