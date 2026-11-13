# Pfaff T09

| | |
|---|---|
| Spec | [`pfaff_t09.ksy`](pfaff_t09.ksy) |
| Extensions | `.t09` |
| Vendor | Pfaff |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists for this format**, so the spec is
unverified against real files and has no tests. Everything below is taken
from how one other open-source library describes the format.

## Structure

Unverified.

| Offset | Content |
|---|---|
| 0x00 | 12 bytes of header, content unknown (a writer emits zeros) |
| 0x0C | 3-byte records, up to and including the end record |

Record: `magnitude_a`, `magnitude_b`, `command`.

| `command` bit | Meaning |
|---|---|
| 0x40 | `magnitude_b` is negative (X) |
| 0x20 | `magnitude_a` is negative (Y) |
| 0x10 | stop (color change) |
| all zero (the byte is 0) | end of data |

The library's reader takes `magnitude_a` as the Y move and `magnitude_b` as
the X move. Its writer sets the low two bits of `command` to 0x03 on normal
stitches, a guess it says it took from T01.

## Versions

None known.

## Units and coordinates

Unverified: relative moves in 0.1 mm, at most 255 per axis. The Y direction
is unknown.

## Open questions

- The header, including whether it holds a stitch count, extents or colors.
- The library's writer and reader disagree (the writer puts the Y move in
  the first byte but fills the sign bits the other way round), so the axis
  assignment above is one reader's word only.
- Meaning of the low bits of `command`; jump, trim and color-change codes.
- Whether the end record is `00 00 00` or only a zero command byte.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No
`.t09` file was found in EmbroidePy/samples or elsewhere with a license that
allows redistribution. Needs: a real `.t09` produced by Pfaff software, with
the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- libembroidery `readT09` / `writeT09` (Zlib): header size, record layout and
  command bits, read for understanding. pyembroidery has no T09 reader.
- No files observed.
