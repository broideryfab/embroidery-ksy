# Janome JEF

| | |
|---|---|
| Spec | [`janome_jef.ksy`](janome_jef.ksy) |
| Extensions | `.jef` (also `.jef+`, see Versions) |
| Vendor | Janome / Elna |
| Priority | Tier 1 — launch |
| Status | 🟡 Partial |

Common home-machine format. Stores thread colors as indices into Janome's
palette; the palette itself is not in the file.

## Structure

All integers are little-endian.

| Offset | Size | Content |
|---|---|---|
| 0 | 116 | Header |
| 0x74 | 4 × n | Color table: Janome palette index per color (`color_indices`) |
| 0x74 + 4n | 4 × n | Second per-color table (`thread_types`), 13 in every sample |
| 0x74 + 8n | 0 or 22 | `header_extension`: empty in JEF, 22 bytes in JEF+ |
| `stitch_offset` | 2 × `point_count` | Stitch records, the last one is the end record `80 10` |
| after end | 0 or more | `trailer`: empty in JEF, extra data in JEF+ |

n = `color_count`.

### Header

| Offset | Type | Spec field | Meaning |
|---|---|---|---|
| 0x00 | u4 | `stitch_offset` | File offset of the first stitch record |
| 0x04 | u4 | `flags` | Unverified: `0x14` Janome / Premier+ / pyembroidery, `0x0a` My Editor and `-ew` `.jef`, `0x01` My Editor `.jef+` |
| 0x08 | 14 chars | `date_time` | Save time, ASCII `YYYYMMDDHHMMSS` |
| 0x16 | 2 | `reserved_0x16` | `00 00` |
| 0x18 | u4 | `color_count` | Number of colors |
| 0x1c | u4 | `point_count` | Length of the stitch data in 2-byte words, end record included |
| 0x20 | u4 | `hoop_code` | Hoop (see Hoop codes) |
| 0x24 | 4 × s4 | `design_extents` | Distance from the origin to the left, top, right, bottom edge of the design |
| 0x34 | 4 × s4 | `hoop_fits[0]` | Distance from each design edge to the edge of a 110 × 110 mm hoop |
| 0x44 | 4 × s4 | `hoop_fits[1]` | Same for 50 × 50 mm |
| 0x54 | 4 × s4 | `hoop_fits[2]` | Same for 140 × 200 mm |
| 0x64 | 4 × s4 | `hoop_fits[3]` | Same values as `hoop_fits[2]` in every sample |

`hoop_fits[k]` = half the hoop size minus the design extent on that side,
e.g. `random1-janome.jef`: left 550 − 479 = 71, top 550 − 500 = 50. When the
design does not fit the hoop, all four values are −1 (`ff ff ff ff`).

`design_extents` match the extents computed from the stitch records in the
Janome and Premier+ samples, and the `+X`/`-X`/`+Y`/`-Y` header values of the
DST version of the same design (`random1-wilcom.DST`: 468 / 479 / 500 / 469).

### Stitch records

| Bytes | Meaning |
|---|---|
| `dx dy` (dx ≠ `0x80`) | Stitch: signed 8-bit moves |
| `80 02 dx dy` | Jump (move without stitching) |
| `80 01 dx dy` | Color change; `dx dy` = `00 00` in every sample |
| `80 10` | End; no move bytes follow |

Moves are at most ±127 units per record; producers split longer moves into
several jumps. A stitch with dx = −128 cannot be written (it would read as
the escape byte). `point_count` counts 2-byte words: a stitch counts 1, a
jump or color change 2, the end record 1 (checked on all samples, e.g.
`random1-janome.jef`: 27 + 2 × (95 + 9) + 1 = 236).

The spec decodes `dx`, `dy`, `command` and the `is_*` flags per record.
Absolute coordinates, trims (runs of jumps) and the palette lookup are left
to consuming applications.

## Versions

There is no version field. Observed variants:

- **Plain JEF** (Janome software, Premier+, My Editor `.jef`, pyembroidery):
  layout above, stitch data starts right after the second color table and
  the file ends with `80 10`.
- **JEF+** (`.jef+`, Wings My Editor; `flags` = 1):
  - `stitch_offset` is 22 bytes larger. The extra bytes are
    `00000000 00000000 "JANOME\0\0" 01000000 0000`.
  - `design_extents` and `hoop_fits` hold the same numbers as the `.jef`
    from the same program, with X and Y swapped (top, left, bottom, right).
    The stitch data is identical to `random1-me.jef`, so this is not a
    rotated design.
  - After the end record: `00 00`, then 13 × u4
    (`1, 1, 36, 59598, 0, 764, 0, 0, 100, 0, 0, 0, 0`), then a complete
    second JEF file of 764 bytes (the sixth value): header with
    `stitch_offset` 0xc4, `flags` 1, no `JANOME` block, the same stitch
    data, ending `80 10 00 00`. The spec keeps all of this as raw `trailer`
    bytes.

The spec handles both with one layout: `header_extension` takes whatever
lies between the color tables and `stitch_offset`.

## Units and coordinates

- Unit: 0.1 mm for moves, extents and hoop fits.
- Every record is a move relative to the previous position. The first
  position is the design origin (0, 0).
- X grows to the right, **Y grows up**. Screen coordinates need `-dy`.
  Confirmed by `random1-janome.jef`: its first jumps reach (368, 181), and
  the EmbroidePy dump of the same design lists the first color ending at
  (368.3, −180.8) in screen coordinates. `design_extents.top` matches the
  largest positive Y.

## Hoop codes

| Code | Hoop (mm) | Seen in |
|---|---|---|
| 0 | 110 × 110 | My Editor (`.jef`, `.jef+`), `-ew` |
| 1 | 50 × 50 | — |
| 2 | 140 × 200 | — |
| 3 | 126 × 110 | Janome software (both samples, ~95 × 97 mm and ~36 × 36 mm designs) |
| 4 | 200 × 200 | — |
| 6 | unknown | Premier+ |

Codes 0–4 and sizes are unverified: they come from the pyembroidery writer,
not from Janome. Janome machines name hoops by letter or code (A, B, C, D,
SQ14, SQ20, RE20, …); the mapping is to be checked on the machine.

## Open questions

What each producer writes, observed in the samples:

| | Janome | Premier+ | My Editor `.jef+` |
|---|---|---|---|
| `flags` | `0x14` | `0x14` | `0x01` (`0x0a` in `.jef`) |
| `hoop_code` | 3 | 6 | 0 |
| `design_extents` order | left, top, right, bottom | left, top, right, bottom | top, left, bottom, right |
| `hoop_fits` order | left, top, right, bottom | left, bottom, top, right (?) | top, left, bottom, right |
| First record | jump | stitch | jump 0, 0 |

- `flags`: meaning of the bits; is it a version or a feature mask?
- `thread_types`: always 13; what other values mean.
- `color_indices`: signed or unsigned? Index 0 is said to mean "no color"
  (stop); not in the samples. The palette table is not in this repository
  yet (`_common/janome_threads` if SEW/JPX need it too).
- `hoop_fits[3]`: a custom or larger hoop? Equal to `hoop_fits[2]` in all
  samples.
- Premier+: hoop code 6 and the `hoop_fits` order (only one sample; right
  and bottom are both 469, so the order is a guess).
- `-ew` `.jef` files (not included) write `design_extents` 0, 0, 947, 969
  (origin at the top-left corner) and −1 in all `hoop_fits`; their stitch
  data also starts at the top-left. Producer not identified.
- JEF+: meaning of the 22-byte `JANOME` block and the 52-byte block; does
  a Janome machine or Janome software read `.jef+`; relation to `.jpx`.
- Commands other than `01`, `02`, `10`: the spec reads 2 move bytes after
  any other code.
- Files without an end record: the spec stops at end of file.

## Verify on the Janome machine

For each sample, load it on the machine and note model and firmware, then
compare the design-info screen with the values below. "Records" are counted
from the file; which of them the machine calls "stitches" is one of the
questions.

| Sample | Colors | Size (W × H mm) | Stitches / jumps / color changes / `point_count` | Hoop code |
|---|---|---|---|---|
| `random1-janome.jef` | 10 | 94.7 × 96.9 | 27 / 95 / 9 / 236 | 3 |
| `spiralbox-janome.jef` | 16 | 36.3 × 36.2 | 61 / 16 / 15 / 124 | 3 |
| `random1-premier.jef` | 10 | 94.8 × 96.8 | 38 / 196 / 9 / 449 | 6 |
| `random1-me.jef+` | 10 | 94.7 × 96.9 | 30 / 117 / 9 / 283 | 0 |

Checklist per file:

- [ ] Loads without error (for `.jef+`: does it load at all, or only after renaming to `.jef`?).
- [ ] Stitch count shown — equal to stitches, stitches + jumps, or `point_count`?
- [ ] Width × height shown, versus the size above.
- [ ] Number of colors and the color names, versus `color_indices`.
- [ ] Hoop the machine selects or asks for, versus `hoop_code` (record the
      hoop name to fill in the Hoop codes table).
- [ ] Design orientation on screen (Y up in the file).
- [ ] Optional: stitch once on scrap to check jumps and trims.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Purpose-built samples (square, two
colors, long jump, one file per hoop) are still to be made and checked on
the machine.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the sample files and of the other EmbroidePy JEF / JEF+
  files (`random1.jef`, `random1-me.jef`, `random1-ew.jef`, the other
  `-me.jef+` files): hex dumps of headers, color tables, stitch data and
  trailers.
- EmbroidePy/samples `random1.csv`, `random1.txt`, `spiralbox.csv`,
  `spiralbox.txt` (pyembroidery dumps of the same designs): extents, color
  breaks, Y direction.
- `formats/tajima_dst` samples of the same designs: header extents.
- EmbroidePy/pyembroidery `JefReader.py` and `JefWriter.py` (MIT), read for
  understanding of the command codes, the hoop code list and the hoop fit
  blocks.
