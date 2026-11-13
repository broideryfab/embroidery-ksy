# Brother PHB

| | |
|---|---|
| Spec | [`brother_phb.ksy`](brother_phb.ksy) |
| Extensions | `.phb` |
| Vendor | Brother |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from the skip logic of other open-source readers, which locate the PEC stitch records without decoding the header.

## Structure

All integers are little-endian. Unverified: the file starts with `#PHB` and a 4-character version ("0003" in a comment of one reader). Readers then use fixed offsets and chained length fields:

| Offset | Size | Content |
|---|---|---|
| 0x00 | 4 + 4 | `magic` `#PHB`, `version` |
| 0x54 | 4 | `section_a_size`; A = 0x52 + this |
| 0x71 | 2 | `num_color_indices` |
| 0x73 | n | `color_indices`: u1 index into Brother's PEC thread palette |
| A | 4 | `section_b_size`, then section B |
| B = A + `section_b_size` + 2 | 4 | `section_c_size`, then section C |
| C = B + `section_c_size` | | unknown; at C + 14 a u1 `num_colors_2` |
| C + 15 + `num_colors_2` + 0x15 | | PEC stitch records, up to the end record |

The stitch records are the ones of [`brother_pec`](../brother_pec/README.md), imported as `brother_pec::stitch_record`. Nothing else in the file is decoded: the header before 0x52, sections A, B and C, and the `num_colors_2` bytes with the 20 bytes after them are skipped by other readers. The offsets are exposed as instances (`section_a_pos`, `section_b_pos`, `section_c_pos`, `stitches_pos`).

## Versions

Unverified: `#PHB0003` is the only version mentioned (a comment in pyembroidery).

## Units and coordinates

Unverified: same as PEC (0.1 mm, relative moves). libembroidery flips the Y axis after reading and pyembroidery does not; which is right is not known.

## Open questions

- Contents of the three sections and of the header before 0x52.
- Whether the color list at 0x71 and the second color count match.
- Whether PEC thumbnails or a PEC-style header exist somewhere in sections A to C.
- Whether the end record is always present.
- Exact meaning of the skips (+2, +14, +4, +17 in the readers).

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.phb`
file was found in EmbroidePy/samples or elsewhere with a license that allows
redistribution, so the spec is unverified against real files and has no
tests. Needs: a real `.phb` produced by the vendor's software or a machine,
with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- pyembroidery `PhbReader.py` (MIT): offsets and chained skips, read for understanding.
- libembroidery `brother.c` `readPhb` (Zlib): same chain; confirms the offsets and shows the extra Y flip; read only.
- No files observed.
