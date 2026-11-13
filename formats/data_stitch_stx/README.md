# Data Stitch STX

| | |
|---|---|
| Spec | [`data_stitch_stx.ksy`](data_stitch_stx.ksy) |
| Extensions | `.stx` |
| Vendor | Data Stitch |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Header with three block offsets, then the blocks. All values little-endian.

## Structure

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0x00 | 3 | `magic` | `STX` |
| 0x03 | 5 | `version` | `1.00` + NUL |
| 0x08 | 4 | `unknown_0x08` | 48 in every sample |
| 0x0c | 4 | `colors_offset` | 0x16a |
| 0x10 | 4 | `unknown_block_offset` | 0x19a |
| 0x14 | 4 | `stitches_offset` | 0x262 |
| 0x18 | 8 | `reserved_0x18` | Zeros |
| 0x20… | | | Zeros up to the first block |
| `colors_offset` | 3 × 16 | `colors` | R, G, B, each 0 to 63 |
| `unknown_block_offset` | 200 | `unknown_block` | Unknown |
| `stitches_offset` | to end | `records` | EXP-style records |

The number of colors is derived: `(unknown_block_offset - colors_offset) / 3`.
All offsets are identical in the five samples, so any other layout is
untested.

### Color table

Identical in every sample: black, white, red, green, blue, yellow, cyan,
magenta, orange, brown, a beige, dark green, purple, black, two greys; the
values use 6 bits (63 = full). It looks like a fixed palette, not the
design's thread colors. Channel order is the natural reading
(Unverified).

### Unknown block

200 bytes, identical in every sample: big-endian 16-bit values 2, 3, … 15,
then 1, 2, … 15 repeated, ending at 11 (100 entries). Possibly a table of
thread indices per color change. Unverified.

### Records

Same as Melco EXP:

| Bytes | Meaning |
|---|---|
| `dx dy` (first byte ≠ `0x80`) | Stitch, signed bytes |
| `80 01 dx dy` | Color change, deltas 0 in the samples |
| `80 04 dx dy` | Jump (move) |
| `80 80 dx dy` | Trim (in `scene-wilcom.STX`) |
| `80 02 dx dy` | Stitch with an escape record (EXP, not in the samples) |

There is no end record; the data runs to the end of the file. The stitch
data holds the same points as the INB sample of the same design, with each
long move split into several jumps (first jump (-80, -28) in
`random1-wilcom.STX`, as in `random1-wilcom.INB`).

## Versions

Only "1.00" seen. The spec does not branch on it.

## Units and coordinates

0.1 mm, relative deltas, Y up in the file (pyembroidery negates it, as for
EXP). Unverified.

## Open questions

- `unknown_0x08` (48), the 200-byte block, and the zero bytes after 0x18.
- Whether offsets other than the ones in the samples occur (the number of
  colors, a larger table).
- Meaning of the trim deltas in `scene-wilcom.STX`.
- Records beyond the three seen (the EXP controls `0x02` is from
  pyembroidery's EXP reader).

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). No purpose-built sample exists yet.
Expected values in the tests were read from the raw bytes with an
independent decoder.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the five sample files (hex dumps).
- EmbroidePy/pyembroidery `StxReader.py` and `ExpReader.py` (MIT): the three
  offsets and the record layout.
