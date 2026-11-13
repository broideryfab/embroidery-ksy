# Pfaff MAX

| | |
|---|---|
| Spec | [`pfaff_max.ksy`](pfaff_max.ksy) |
| Extensions | `.max` |
| Vendor | Pfaff |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists for this format**, so the spec is
unverified against real files and has no tests. Everything below is taken
from how other open-source readers describe the format.

## Structure

Unverified: little-endian.

| Offset | Content |
|---|---|
| 0x00 | 0xD5 bytes of header, not decoded |
| 0xD5 | stitch count, `u4` (see open questions) |
| 0xD9 | stitch records, 8 bytes each |

Record (Unverified): X as signed 24-bit, one flag byte, Y as signed 24-bit,
one flag byte. X and Y are **absolute** positions, not deltas. The flag
bytes are not understood. The spec reads the records as `num_records`
entries, so a file shorter than its count fails to parse.

## Versions

None known.

## Units and coordinates

Unverified. Positions are absolute. One reader scales them by 1.235 and
treats the result as 0.1 mm; another divides by 10 to get millimetres. The
two do not agree, so the unit is open. Y is flipped by one of them, so the
file's Y direction is likely down; also unverified.

## Open questions

- Does the stitch count at 0xD5 exist? One reader reads it, the other
  starts records at 0xD5 and runs to end of file. The spec follows the
  first.
- The unit (the 1.235 factor versus 0.1 mm per count).
- The flag bytes: commands such as jump, trim, color change and end are
  not known.
- The header: one reader's writer emits a fixed 0xD5-byte block containing
  ASCII text (thread names such as "Madeira Rayon 40", numbers). It may hold
  a color table. Nothing is decoded.
- Whether Pfaff software writes `.max` at all, or the format belongs to
  another product.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No
`.max` file was found in EmbroidePy/samples or elsewhere with a license that
allows redistribution. A file made by us would only test our own
assumptions. Needs: a real `.max` produced by Pfaff software, with the right
to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- pyembroidery `MaxReader.py` (MIT): header size, count, record layout and
  scale factor, read for understanding.
- libembroidery `pfaff.c` (Zlib): `readMax` and `writeMax`, which start the
  records at 0xD5 and decode them differently; read only.
- No files observed.
