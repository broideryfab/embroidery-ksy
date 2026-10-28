# Tajima DST

| | |
|---|---|
| Spec | [`tajima_dst.ksy`](tajima_dst.ksy) |
| Extensions | `.dst` |
| Vendor | Tajima |
| Priority | Tier 1 — launch |
| Status | 🟡 Partial |

Industry-standard commercial format. Stitch data only; no thread colors.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 512 | Header: ASCII `KEY:value` fields, each ended by CR (`0x0d`), then `0x1a` and padding |
| 512 | 3 × n | Stitch records, the last one is the end record `00 00 f3` |
| 512 + 3n | 0–3 | Trailer written by some producers (`1a` or `1a 00 00`) |

### Header

All four samples use the same fixed layout. Numeric values are right-aligned
decimal text, space-padded. The sign position varies by producer (`-   37`,
`    +0`, `     0`), so the spec keeps every value as text.

| Offset | Key | Value width | Spec field | Meaning |
|---|---|---|---|---|
| 0 | `LA:` | 16 | `label` | Design name, space-padded (Wilcom truncates to 8 characters) |
| 20 | `ST:` | 7 | `stitch_count` | Record count (see Open questions) |
| 31 | `CO:` | 3 | `color_change_count` | Color changes or colors (see Open questions) |
| 38 | `+X:` | 5 | `extent_x_pos` | Largest X reached, relative to the start |
| 47 | `-X:` | 5 | `extent_x_neg` | Smallest X reached, as a positive distance |
| 56 | `+Y:` | 5 | `extent_y_pos` | Largest Y reached (Y up) |
| 65 | `-Y:` | 5 | `extent_y_neg` | Smallest Y reached, as a positive distance |
| 74 | `AX:` | 6 | `end_offset_x` | Last position relative to the start, signed |
| 84 | `AY:` | 6 | `end_offset_y` | Same for Y |
| 94 | `MX:` | 6 | `previous_end_x` | Unverified: end point of the previous file in a multi-file design |
| 104 | `MY:` | 6 | `previous_end_y` | Same for Y |
| 114 | `PD:` | 6 | `previous_file` | Unverified: previous file name; `******` = none |
| 124 | — | 1 | `terminator` | `0x1a` |
| 125 | — | 387 | `padding` | Spaces; My Editor writes one `0x00` first |

The extents in the header match the extents computed from the records in all
four samples, which confirms the record bit layout below.

### Stitch records

Each record is 3 bytes. Each axis bit adds or subtracts a power of three, so
one record moves at most ±121 units per axis (1 + 3 + 9 + 27 + 81).

| Bit | Byte 0 | Byte 1 | Byte 2 |
|---|---|---|---|
| 7 | y +1 | y +3 | jump |
| 6 | y −1 | y −3 | color change |
| 5 | y +9 | y +27 | y +81 |
| 4 | y −9 | y −27 | y −81 |
| 3 | x −9 | x −27 | x −81 |
| 2 | x +9 | x +27 | x +81 |
| 1 | x −1 | x −3 | always 1 |
| 0 | x +1 | x +3 | always 1 |

Commands, from the two high bits of byte 2:

| Byte 2 & `0xc3` | Spec instance | Meaning |
|---|---|---|
| `0x03` | `is_stitch` | Stitch |
| `0x83` | `is_jump` | Jump (move without stitching) |
| `0xc3` | `is_color_change` | Color change / stop |
| `0x43` | `is_sequin` | Unverified: sequin mode (not in the samples) |
| byte 2 & `0xf3` = `0xf3` | `is_end` | End of stitch data; usually `00 00 f3` |

The spec decodes `dx`, `dy` and these flags per record. Absolute
coordinates, trims (often written as a run of jumps) and sequin behavior are
left to consuming applications.

## Versions

No version field. Producers differ only in header details (see the table in
Open questions). Some writers (pyembroidery's extended header) add more
`KEY:value` lines (`AU`, `CP`, `TC`) after `PD`; the spec then reads the
first extra byte as `terminator` and the rest as `padding`, without failing.
No sample with extra lines is in the repository yet.

## Units and coordinates

- Unit: 0.1 mm for moves and header extents.
- Every record is a move relative to the previous position. The first
  position is the design origin (0, 0).
- X grows to the right, **Y grows up**. Screen coordinates (Y down) need
  `-dy`. Confirmed by `spiralbox-wilcom.DST`: its first stitches go
  (0, 0) → (0, −100) → (100, −100) → (100, 0) → (0, 0) in DST units, while
  the EmbroidePy dump of the same design lists (0, 0) → (0, 100) →
  (100, 100) → (100, 0) → (0, 0) in screen coordinates.

## Open questions

What each producer writes, observed in the samples:

| | Wilcom | Premier+ | My Editor |
|---|---|---|---|
| `ST` | records incl. end (219, 111) | 245 for 248 records | records incl. end (303) |
| `CO` | color change records (9, 15) | colors (10 for 9 changes) | colors (10 for 9 changes) |
| `AX`/`AY` | filled | `+    0` / `     0` | `    +0` |
| Trailer | `1a` | `1a` | `1a 00 00` |

- `ST`: what Premier+ counts (245 of 248 records) is unknown.
- `CO`: changes or colors depends on the producer; consumers should count
  color change records instead.
- `MX`, `MY`, `PD`: multi-file meaning not confirmed; all samples write 0
  and `******`.
- Header text encoding: assumed ISO-8859-1 for `label`; no sample has
  non-ASCII characters.
- Is the header ever longer than 512 bytes, or the layout ever different
  (extra fields before `PD`)? The spec fails on a different field order.
- Sequin mode (`0x43`) and "stop" vs color change: which producers write
  them, and how machines treat them.
- Files without an end record: the spec stops at end of file; a file
  length that is not a multiple of 3 after the header will fail.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Purpose-built samples (square, two
colors, long jump, maximum delta, empty design) are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the four sample files (hex dumps of header and records).
- EmbroidePy/samples `random1.csv`, `random1.txt`, `spiralbox.csv`
  (pyembroidery dumps of the same designs): extents, stitch positions, color
  breaks, Y direction.
- EmbroidePy/pyembroidery `DstReader.py` (MIT), read for understanding of
  the bit layout, command masks, sequin mode and extended header keys.
