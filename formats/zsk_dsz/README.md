# ZSK DSZ

| | |
|---|---|
| Spec | [`zsk_dsz.ksy`](zsk_dsz.ksy) |
| Extensions | `.dsz` |
| Vendor | ZSK |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

DST variant used by ZSK machines. Stitch data only; no thread colors. The
header is the same as in [Tajima DST](../tajima_dst/README.md); the records
use a different encoding.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 512 | Header: ASCII `KEY:value` fields, each ended by CR (`0x0d`), then `0x1a` and padding |
| 512 | 3 × n | Records, the last one is the end record `00 00 90` |
| 512 + 3n | 0–3 | Trailer written by some producers (`1a` or `1a 00 00`) |

### Header

Identical to the DST header (`LA`, `ST`, `CO`, `+X`, `-X`, `+Y`, `-Y`, `AX`,
`AY`, `MX`, `MY`, `PD`, then `0x1a` and padding). The spec reuses
`tajima_dst::header` through an import; see the DST README for the field
table. Extents are in 0.1 mm units and match the extents computed from the
records in all six samples, which confirms the record layout below.

Differences seen in the samples:

| | Wilcom | My Editor |
|---|---|---|
| `ST` | record count incl. end record | 0, or a value that differs from the record count |
| `CO` | number of needle changes (9, 2, 15) | number of colors (10, 3, 16) |
| `AX`/`AY` | filled (end point) | `    +0` |
| Padding | `1a` then spaces | `1a 00` then spaces |
| Trailer | `1a` | `1a 00 00` |

### Records

Each record is 3 bytes: **Y magnitude, X magnitude, control** (Y comes
first). One record moves at most 255 units per axis.

| Control bit | Meaning |
|---|---|
| 7 | Set in every sample record; meaning unknown |
| 6 | X is negative |
| 5 | Y is negative |
| 4..0 | Command (see below) |

Commands, from `control & 0x9f`:

| Value | Spec instance | Meaning |
|---|---|---|
| `0x80` | `is_stitch` | Stitch |
| `0x81` | `is_jump` | Jump (move without stitching) |
| `0x82` | `is_stop` | Unverified: stop. Not in the samples |
| `0x83`–`0x9a` (not `0x90`) | `is_needle_change` | Needle / color change. Samples: `0x85`, `0x87`, `0x89`, `0x8b`, `0x8d`, `0x8f`, `0x93`; the move is 0 |
| `0x90` | `is_end` | End of stitch data; `00 00 90` |
| `0x9b` | `is_trim` | Trim. Only in `scene-me.dsz` |

The spec decodes `dx`, `dy`, the sign flags and these command flags per
record. Absolute coordinates are left to consuming applications.

## Versions

No version field. Producers differ only in header details (table above).

## Units and coordinates

- Unit: 0.1 mm, for moves and header extents.
- Every record is a move relative to the previous position; the start is
  (0, 0).
- X grows to the right, **Y grows up**: with `dy` as decoded by the spec the
  running minimum and maximum equal the header `+Y` / `-Y` values in all six
  samples (and `AX`/`AY` equal the end point in the Wilcom files).
  `spiralbox-wilcom.DSZ` starts with two records of `dy = -50`, the same
  direction as the DST version of that design. Screen coordinates need `-dy`.

## Open questions

- Control bit 7: always set in the samples; meaning unknown.
- `0x82` (stop): taken from a reader's code, no sample.
- Needle numbering: `needle_index` is `(command - 0x83) / 2` as in one
  reader; Wilcom files cycle `0x87, 0x89, 0x8b, 0x8d, 0x85`, My Editor files
  use `0x87 … 0x8f, 0x93` and repeat `0x93` before some changes. What the
  codes mean on a machine, and what `0x83`, `0x91` and even values do, is
  unknown.
- Two readers disagree on the control byte: one treats bit 0 as trim and
  bits 1..3 as a head number (command bits `0x0e`); the other, used here,
  matches the samples (`0x81` jump, `0x9b` trim). Only the second was tested
  against sample files.
- `ST` in My Editor files: 0, or neither the record count nor the DST value.
- Whether other producers write a different header (the spec fails on a
  different field order, as DST does) or end records with sign bits set
  (the spec checks only the low five bits of control).
- No sample has records with a move above 127, jumps that need splitting, or
  a control byte with bit 7 clear.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All six come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)); `random1-wilcom` has a DST twin in
`tajima_dst`. Purpose-built samples (square, long jump, maximum delta) are
still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the six sample files (hex dumps; extents, end point and
  needle codes checked against the header).
- EmbroidePy/pyembroidery `DszReader.py` (MIT): read for understanding of the
  record byte order, sign bits and command codes.
- Embroidermodder/libembroidery `zsk_usa.c` (Zlib): read for understanding;
  its control byte interpretation differs (see Open questions).
- EmbroidePy/samples `random1.txt` (pyembroidery dump of the same design).
