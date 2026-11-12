# Husqvarna Viking HUS

| | |
|---|---|
| Spec | [`husqvarna_hus.ksy`](husqvarna_hus.ksy) |
| Extensions | `.hus` |
| Vendor | Husqvarna Viking |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Older Viking format. A small header, a thread palette index per color and
three compressed blocks with the stitch commands and the X and Y moves.

## Structure

All multi-byte integers are **little-endian**.

| Offset | Size | Spec field | Meaning |
|---|---|---|---|
| 0x00 | 4 | `magic` | `5d fc c8 00` |
| 0x04 | u4 | `num_stitches` | Stitch records, including the `end` command when present |
| 0x08 | u4 | `num_colors` | Colors (color changes + 1) |
| 0x0c | 4 × s2 | `extent_max_x`, `extent_max_y`, `extent_min_x`, `extent_min_y` | Design extents, 0.1 mm |
| 0x14 | 3 × u4 | `ofs_commands`, `ofs_x`, `ofs_y` | Absolute offsets of the three blocks |
| 0x20 | 8 | `unknown_0x20` | Zero in every sample |
| 0x28 | 2 | `unknown_0x28` | See Open questions |
| 0x2a | 2 × n | `thread_indexes` | u2 palette index per color |

The command block starts at `ofs_commands` (right after the palette in every
sample), the X block at `ofs_x` and the Y block at `ofs_y`, which runs to the
end of the file.

### Decompressed blocks

One byte per stitch record in each block:

| Command byte | Name | Notes |
|---|---|---|
| `0x80` | `stitch` | Move by (dx, dy), stitching |
| `0x81` | `jump` | Move by (dx, dy) without stitching |
| `0x84` | `color_change` | dx, dy are 0 or a small move |
| `0x88` | `trim` | Unverified: trim; dx, dy may be non-zero |
| `0x90` | `end` | Last record in Premier+ and Wilcom files |

dx and dy are signed bytes in 0.1 mm units. The enum `command` documents the
codes; nothing in the spec parses them because the blocks are compressed.

## Compression

The three blocks use the same scheme (verified by decompressing every sample
with an independent implementation: each block yields exactly
`num_stitches` bytes). It is an LZ77 + Huffman scheme read MSB first, in
blocks:

- A block starts with a 16-bit count of tokens. Three Huffman tables follow:
  a code-length table (5-bit symbol count, 3-bit lengths with an
  escape for longer ones), the token table (9-bit count) and the distance
  table (5-bit count). A count of 0 means a single fixed symbol, given in the
  next 5 or 9 bits.
- A token below 256 is a literal byte. A token from 256 up is a back
  reference of length token - 253 (at least 3); its distance comes from the
  distance table (symbol 0 is distance 1, symbol n > 0 is `2^(n-1)` plus
  n - 1 extra bits, plus 1). Token 510 ends the stream.

The spec does not model this: the blocks are raw bytes (`*_compressed`).

## Versions

No version field. All 15 HUS files in EmbroidePy/samples (Premier+, Wings My
Editor, Wilcom) have the same layout; five are committed here.

## Units and coordinates

- Moves and extents: 0.1 mm.
- The sign of Y in the stored bytes is the reverse of screen Y: in
  `spiralbox-wilcom.HUS` the square's moves are stored as (0, -100),
  (100, 0), (0, 100), (-100, 0), and the EmbroidePy dump `spiralbox.csv`
  has (0, 100), (100, 100), ... in screen coordinates. The extents use the
  stored direction: they equal the minimum and maximum of the running sum of
  the stored dx and dy in all 15 sample files checked.

## Open questions

- `unknown_0x28`: `00 00` for Premier+ and Wilcom; Wings My Editor writes
  `00 e9` (random1/2/3), `00 22` (scene), `00 0b` (spiralbox). It looks like
  the end of the 8-byte field before it, or a separate byte.
- The thread palette is a fixed table of Husqvarna colors (indexes 2 to 28 seen
  here). It is not part of the spec. Unverified: which index means which color.
- Wings My Editor files have no `end` command; Premier+ files can end with a
  trim before it.
- Trim (`0x88`) is assumed from its name in other readers; it carries a
  non-zero move in the Premier+ samples.
- Can the three blocks be in another order, or have gaps? Always in order and
  adjacent in the samples (except for the Y block, which reaches to the end).
- The compression is not described as a KSY structure. Only the sizes of the
  compressed blocks are available, via the offsets.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Expected values in `tests/` were checked
against an independent decompression of each file: `num_stitches` equals the
length of every decompressed block and the extents equal the running-sum
range. Purpose-built samples are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 15 HUS files in EmbroidePy/samples (hex dumps, offsets,
  decompressed blocks), five of them committed here.
- EmbroidePy/samples `random1.txt`, `spiralbox.csv` (pyembroidery dumps of
  the source designs): stitch directions.
- EmbroidePy/pyembroidery (MIT) `HusReader`, `EmbCompress`: header field
  order, command codes, compression scheme. Re-implemented separately only
  to check the samples; nothing is copied.
- Embroidermodder/libembroidery (Zlib) `compress.c`: pointer to the
  HUS/VIP description by Jason Weiler (not consulted).
