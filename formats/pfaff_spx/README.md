# Pfaff SPX

| | |
|---|---|
| Spec | [`pfaff_spx.ksy`](pfaff_spx.ksy) |
| Extensions | `.spx` |
| Vendor | Pfaff |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists for this format**, so the spec is
unverified against real files and has no tests. Everything below is taken
from how one other open-source reader describes the format.

## Structure

Unverified: big-endian.

| Offset | Content |
|---|---|
| 0x00 | 0x11E bytes of header, not decoded |
| 0x11E | records, 9 bytes each, to end of file |

Record (Unverified):

| Offset | Size | Content |
|---|---|---|
| 0 | 2 | unknown, skipped by the reader |
| 2 | 2 | Y delta, signed 16-bit (reader negates it) |
| 4 | 2 | X delta, signed 16-bit |
| 6 | 1 | signed byte, subtracted from the negated Y by the reader |
| 7 | 2 | unknown, skipped by the reader |

The spec exposes `dy` as the reader computes it; the raw fields are kept.
No end marker, color change or jump is known; the reader treats every record
as a plain stitch.

## Versions

None known.

## Units and coordinates

Unverified: relative moves. The unit is not known; the reader uses the
values as they are.

## Open questions

- Header content (thread colors, name, extents, stitch count).
- The meaning of the 2 + 2 skipped bytes and of the byte that adjusts Y; it
  may be a fine position or a command.
- Commands: color change, jump, trim and end.
- Unit and axis directions.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No
`.spx` file was found in EmbroidePy/samples or elsewhere with a license that
allows redistribution. Needs: a real `.spx` produced by Pfaff software, with
the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- pyembroidery `SpxReader.py` (MIT): header size and record layout, read for
  understanding. libembroidery has no `.spx` reader.
- No files observed.
