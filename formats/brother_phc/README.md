# Brother PHC

| | |
|---|---|
| Spec | [`brother_phc.ksy`](brother_phc.ksy) |
| Extensions | `.phc` |
| Vendor | Brother |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from the skip logic of other open-source readers, which locate the PEC stitch records without decoding most of the header.

## Structure

All integers are little-endian. Unverified: the file starts with `#PHC` and a version digit at offset 7 (ASCII).

| Offset | Size | Content |
|---|---|---|
| 0x00 | 4 + 4 | `magic` `#PHC`, `version` |
| 0x2b | 1 | `pre_graphics_size` |
| 0x2c | 4 | `graphics_end_size` (called file length by libembroidery) |
| 0x30 | 2 | `pec_offset` |
| 0x4a | 1 | `thumbnail_height` |
| 0x4c | 1 | `thumbnail_byte_width` |
| 0x4d | 2 | `num_color_indices` |
| 0x4f | n | `color_indices`: u1 index into Brother's PEC thread palette |
| then | | thumbnails (not decoded) |
| A = `pec_offset` + `pre_graphics_size` | 2 | `section_a_size`, then section A |
| B = A + 2 + `section_a_size` | 4 | `section_b_size`, then section B |
| C = B + 4 + `section_b_size` + 10 | 1 | `num_colors_2` |
| C + 1 + `num_colors_2` + 0x1d | | PEC stitch records, up to the end record |

The stitch records are the ones of [`brother_pec`](../brother_pec/README.md), imported as `brother_pec::stitch_record`. The skips between the sections are unknown data. The last skip follows pyembroidery; libembroidery reads a u2 instead of a u1 at C and skips that count plus 0x12 without the 10 extra bytes. The two cannot be reconciled without a real file, so `stitches_pos` is Unverified.

## Versions

Unverified: version digit at offset 7; no values known.

## Units and coordinates

Unverified: same as PEC (0.1 mm, relative moves). libembroidery flips Y after reading and pyembroidery does not; which is right is not known.

## Open questions

- The two readers' last skip (see above): which one is correct.
- Contents of sections A and B and of the header outside the listed fields.
- Number and layout of thumbnails: pyembroidery reads `num_color_indices` images of `thumbnail_byte_width * thumbnail_height` bytes after the colors; not confirmed.
- Meaning of `pre_graphics_size`, `graphics_end_size` and `pec_offset`.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.phc`
file was found in EmbroidePy/samples or elsewhere with a license that allows
redistribution, so the spec is unverified against real files and has no
tests. Needs: a real `.phc` produced by the vendor's software or a machine,
with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- pyembroidery `PhcReader.py` (MIT): offsets and chained skips, read for understanding.
- libembroidery `brother.c` `readPhc` (Zlib): same offsets with a different final skip; read only.
- No files observed.
