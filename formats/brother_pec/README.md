# Brother PEC

| | |
|---|---|
| Spec | [`brother_pec.ksy`](brother_pec.ksy) |
| Extensions | `.pec` |
| Vendor | Brother |
| Priority | Tier 1 — launch |
| Status | 🟡 Partial |

Stitch block embedded in PES; also used standalone by older machines. The
spec's `pec_block` type is shared: [`brother_pes`](../brother_pes/) imports
it for the PEC block at the end of every PES file.

## Structure

A standalone file is the 8-byte magic `#PEC0001` followed by one PEC block.
Offsets below are relative to the start of the block (file offset 8 in a
`.pec` file, `pec_offset` in a `.pes` file).

| Offset | Size | Content |
|---|---|---|
| 0 | 512 | Header: label, thumbnail size, palette indices, space padding |
| 0x200 | 20 | Stitch header: graphics offset, design size, start point |
| 0x214 | variable | Stitch records, ending with `ff` |
| 0x200 + `graphics_offset` | 228 × n | Thumbnails, then producer-specific data |

### Header (512 bytes)

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0x00 | 3 | `label_key` | `LA:` |
| 0x03 | 16 | `label` | Design name, space-padded |
| 0x13 | 1 | `label_cr` | `0d` |
| 0x14 | 11 | `unknown_0x14` | Spaces |
| 0x1f | 1 | `unknown_0x1f` | `20`, or `ff` (Brother PES v5/v6, Premier+ PES) |
| 0x20 | 1 | `unknown_0x20` | `ff` |
| 0x21 | 1 | `unknown_0x21` | `00` |
| 0x22 | 1 | `thumbnail_byte_width` | 6 (48 pixels) |
| 0x23 | 1 | `thumbnail_height` | 38 |
| 0x24 | 12 | `unknown_0x24` | Spaces; Brother PES files have `64 20 00 20 00` at 0x28 |
| 0x30 | 1 | `num_colors_minus_one` | Color count − 1 |
| 0x31 | n | `palette_indices` | One index per color block into Brother's 64-color palette |
| 0x31 + n | rest | `padding` | Spaces up to 0x200 |

The palette indices refer to Brother's fixed PEC thread palette; the
palette itself (RGB values, names) is not in the file and not yet in this
spec. Blocks that reuse a thread repeat its index (Brother PE-Design writes
index 10 twice for `random1`).

### Stitch header (20 bytes, at 0x200)

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0x00 | 2 | `unknown_0x00` | 0 |
| 0x02 | 3 | `graphics_offset_low/high` | Offset of the thumbnails from 0x200, 24-bit little-endian |
| 0x05 | 1 | `unknown_0x05` | `31` |
| 0x06 | 2 | `unknown_0x06` | `ff f0` |
| 0x08 | 2 | `width` | Design width, 0.1 mm |
| 0x0a | 2 | `height` | Design height, 0.1 mm |
| 0x0c | 2 | `unknown_0x0c` | 480 |
| 0x0e | 2 | `unknown_0x0e` | 432 |
| 0x10 | 2 | `start_x_raw` | Big-endian, `0x9000` + distance from the left edge to the first position |
| 0x12 | 2 | `start_y_raw` | Big-endian, `0x9000` + distance from the top edge to the first position |

`width` and `height` match the DST header extents of the same designs
(random1: 947 × 969). The start values equal minus the smallest X and Y
reached, computed from the records, in the Wilcom, Brother, ew,
pyembroidery and Premier+ `.pec` samples. My Editor writes a fixed square box (999 × 999,
start 499) and Premier+ v10 the hoop size (3000 × 2000, start 1500 / 1000).

### Stitch records

Each record is a move, a color change or the end. A move is an X value then
a Y value, each in one of two forms:

| First byte | Size | Value |
|---|---|---|
| `0xxxxxxx` | 1 byte | 7-bit two's complement, −64…63 |
| `1ftjvvvv` | 2 bytes | 12-bit two's complement `vvvv` + second byte, −2048…2047 |

In the 2-byte form, bit 5 (`0x20`) is trim and bit 4 (`0x10`) is jump; bit 6
is 0 in every sample. Producers set the same flag on both axes of a record.

| Bytes | Spec instance | Meaning |
|---|---|---|
| move, no flag | `is_stitch` | Stitch |
| move, `0x10` flag | `is_jump` | Jump (move without stitching) |
| move, `0x20` flag | `is_trim` | Trim; ew writes `a0 00 a0 00` before each color change |
| `fe b0 xx` | `is_color_change` | Next color; `xx` alternates 2, 1, 2, … |
| `ff` | `is_end` | End of stitch data |

The spec decodes `dx`, `dy` and the flags per record. Absolute
coordinates are left to consuming applications.

### Thumbnails

At block offset 0x200 + `graphics_offset`, which is right after the end
record in every sample. Each image is 48 × 38 pixels, 1 bit per pixel,
6 bytes per row, top row first, least significant bit = leftmost pixel (the
border drawn in every image is symmetric only with this bit order). The
first image shows the whole design, followed by one per color. Premier+
writes only the first image.

The spec reads `num_colors + 1` images, or as many as fit, and keeps the
rest of the block as `trailer`: one `00` byte in My Editor `.pec` files,
and in PES files from Brother v4–v6 and Premier+ more data that is not
specified (in v5/v6 it starts with a second color count and palette list).

## Versions

Every sample has `#PEC0001`; the magic is checked as a fixed value. PES
files embed the block without the magic. The block layout is the same in
all 25 PEC samples and in the PEC blocks of all 73 PES samples in
EmbroidePy/samples (checked with a byte-level script, not with the
generated parser).

## Units and coordinates

- Unit: 0.1 mm for moves, `width`, `height` and the start point.
- Every move is relative to the previous position; the first move is
  relative to the start point.
- X grows to the right, **Y grows down** (screen coordinates), unlike DST.
  Confirmed by `spiralbox-wilcom.PEC`: its first moves are (0, +100),
  (+100, 0), (0, −100), (−100, 0), and the EmbroidePy dump of the design
  lists (0, 0) → (0, 100) → (100, 100) → (100, 0) → (0, 0), while the DST
  of the same design has −100 for the first Y move.

## Open questions

- Header bytes `0x14`–`0x2f` other than the thumbnail size: meaning of
  `ff 00`, of the `ff` at 0x1f (Brother PES v5/v6, Premier+) and of
  `64 20 00 20 00` (Brother PES).
- Stitch header constants `31`, `ff f0`, 480, 432 (always the same; 480 ×
  432 could be a hoop or screen size).
- High nibble `0x9` of the start values: looks like a 2-byte coordinate with
  the jump flag; not confirmed.
- Bit 6 of the 2-byte form: never set in the samples.
- `xx` after `fe b0`: alternates 2/1; meaning unknown.
- Premier+ PES files: the PEC block can have a single color and no color
  change records while the design has 10 colors (`random1-premier-v10.pes`
  in `brother_pes`); colors then come only from the PES section.
- Brother's 64-color thread palette (RGB, names, catalog numbers) is not
  in the spec yet; an enum or `_common` table would need a source we may
  publish.
- Label encoding: assumed ISO-8859-1; Premier+ writes arbitrary single
  bytes (`0xb8`, `0x09`), no sample has a meaningful non-ASCII label.
- Maximum label length: 16 bytes in the header; Brother PE-Design writes
  only 8 characters inside PES files.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Purpose-built samples (square,
two colors, trim, long stitch forcing the 2-byte form, empty design) are
still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the 25 `.pec` files and the PEC blocks of the 73 `.pes`
  files in EmbroidePy/samples (hex dumps, plus a small decoding script of
  our own that walked every record and checked header values against the
  records).
- EmbroidePy/samples `random1.txt`, `spiralbox.txt` (pyembroidery dumps of
  the same designs): stitch positions, color breaks, Y direction.
- The DST spec in this repository (`tajima_dst`) and its samples, for the
  extents of the same designs.
- BroideryFab internal plan `brother_pec.md` (working hypotheses, checked
  against the bytes).
