# Janome SEW

| | |
|---|---|
| Spec | [`janome_sew.ksy`](janome_sew.ksy) |
| Extensions | `.sew` |
| Vendor | Janome (also read by Viking/Husqvarna-style software) |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Older Janome home-machine format, stitch data only. Thread colors are
indices into Janome's palette; the palette itself is not in the file.

## Structure

All integers are little-endian. The stitch data always starts at the fixed
offset 0x1d78; everything before it is a fixed-size header area.

| Offset | Size | Content |
|---|---|---|
| 0x00 | 2 | `num_color_indices` |
| 0x02 | 2 × n | `color_indices`: Janome palette index per color (u2) |
| 0x1a | 2 × 12 | `unknown_0x1a`: second per-color table, 12 fixed slots |
| 0x32 | 2 × 12 | `unknown_0x32`: third per-color table, 12 fixed slots |
| 0x4a | 2 | `unknown_0x4a`: `06 20` in every sample |
| 0x4c | … | Zero bytes, then a 1-bit preview bitmap (see below) |
| 0x1d78 | 2 or 4 per record | Stitch records, up to and including the end record if present |

n = `num_color_indices`. The spec reads `num_color_indices`, `color_indices`, the rest of
the header area as raw `header_rest` (up to 0x1d78) and the stitch records.
The tables at 0x1a / 0x32 / 0x4a are exposed as instances.

### Color tables

Three tables of 12 u2 slots each follow one another from 0x02, 0x1a and
0x32. With at most 12 colors the index table ends before 0x1a and the rest
of its slots are 0. With more than 12 colors the index list keeps running
and overwrites the start of the next table: `spiralb0.sew` (13 colors) has
its 13th index at 0x1a, where the 7 of the second table would be, so the
second table's first slot is lost. Readers that only use `num_color_indices` and
`color_indices` are not affected.

- Second table (`unknown_0x1a`): 7 in My Editor and Premier+ files, 8 in
  the Wilcom samples. Unverified: a thread type, like `thread_types` in
  [janome_jef](../janome_jef/README.md).
- Third table (`unknown_0x32`): 0 in My Editor files with few colors, other
  values in Wilcom and Premier+ files (`0x1c`–`0x3c`, `0xd8f0`). Unverified,
  meaning unknown.

### Preview bitmap

In `random1-me.sew` the bytes from 0x52 form a 1-bit bitmap, 48 pixels (6
bytes) per row, MSB first: a rounded frame about 30 rows high with the
design's shape drawn inside, followed by more frame-like data. Wilcom files
have an all-zero area. Unverified: exact size, number of images and their
meaning. The spec leaves it as raw bytes in `header_rest`.

### Stitch records

| Bytes | Meaning |
|---|---|
| `dx dy` (dx ≠ `0x80`) | Stitch: signed 8-bit moves |
| `80 02 dx dy` | Jump (move without stitching) |
| `80 01 dx dy` | Color change; `dx dy` = `00 00` in every sample |
| `80 10` | End; no move bytes follow |
| `80 04 dx dy` | Treated like a jump by other readers; not in the samples |

Moves are at most ±127 units per record. A stitch with dx = −128 cannot be
written (it would read as the escape byte). The spec decodes `dx`, `dy`,
`command` and the `is_*` flags per record; absolute coordinates, trims and
palette lookup are left to consuming applications.

Cumulative extents computed from the records match the DST extents of the
same designs in EmbroidePy/samples (`random1`: 947 × 969 units wide and
high) for `random1-me.sew` and `random1-wilcom.SEW`.

## Versions

There is no version field. Observed variants:

- **My Editor** (`random1-me`, `spiralb0`): no end record; the file simply
  stops after the last stitch. Few long moves are split into jumps of up to
  127 units.
- **Wilcom** (`random1-wilcom`, `spiralbox-wilcom-b`): ends with `80 10`,
  second table 8, empty preview.
- **Premier+** (`random2-premier`, `spiralbox-premier_1`): ends with `80 10`,
  second table 7, third table non-zero, preview bitmap present.

The spec handles all three with one layout and stops at the end record or
at end of file, whichever comes first.

## Units and coordinates

- Unit: 0.1 mm.
- Every record is a move relative to the previous position; the first
  position is the design origin (0, 0).
- X grows to the right, **Y grows up**. Screen coordinates need `-dy`.
  Checked on `spiralb0.sew`: its first square starts at (252, −50) and its
  first move is `00 9c` = (0, −100); the EmbroidePy dump of the same design
  (`spiralbox.txt`) goes from (0, 0) to (0, +100) in screen coordinates, so
  raw dy of −100 is screen down. This is the same convention as
  [janome_jef](../janome_jef/README.md) and the pyembroidery SEW reader,
  which flips dy.

## Open questions

- Meaning of the second and third color tables and of `06 20` at 0x4a.
- Preview bitmap: size, number of images, whether Janome software or
  machines use it.
- `color_indices`: same palette as JEF (pyembroidery uses its own 79-entry
  SEW palette; values up to 0x4b occur). The palette is not in this
  repository yet.
- More than 12 colors: do producers lay out the tables differently (more
  slots)? Only one sample has 13 colors.
- Is there ever a header or trailer after the end record? No sample has one.
- Command `04` and any other command codes: not in the samples. The spec
  reads two move bytes after any code other than `10`.
- Files without an end record: the spec stops at end of file.
- Whether current Janome machines or software read or write `.sew` at all.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)); of the 15 SEW files there we keep six,
one per producer and feature. Purpose-built samples are still to be made.
Nothing here has been checked on a real machine.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the EmbroidePy/samples `.sew` files (all 15): hex dumps of
  headers, tables, preview area and stitch records; cumulative extents.
- EmbroidePy/samples `random1.csv`, `random1.txt`, `spiralbox.csv`,
  `spiralbox.txt` (pyembroidery dumps of the same designs, DST-derived):
  extents and Y direction.
- EmbroidePy/pyembroidery `SewReader.py` (MIT), read for understanding:
  color count and indices at the start of the file, stitch data at 0x1d78,
  command codes.
- Embroidermodder/libembroidery `readSew` / `writeSew` (Zlib), read for
  understanding: same layout, 0x1d78 padding. No code copied.
