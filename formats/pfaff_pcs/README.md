# Pfaff PCS

| | |
|---|---|
| Spec | [`pfaff_pcs.ksy`](pfaff_pcs.ksy) |
| Extensions | `.pcs` |
| Vendor | Pfaff |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Older Pfaff format.

## Structure

All values little-endian.

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0 | 1 | `version` | `0x32` in every sample |
| 1 | 1 | `hoop_code` | 3 (large) or 2 (small, 80 × 80 mm) |
| 2 | 2 | `color_count` | Color table entries (16, or 15 for Premier+) |
| 4 | 4 × count | `colors` | R, G, B, 0 |
| 4 + 4 × count | 2 | `stitch_count` | Stitch and move records, **not** counting color change records |
| +2 | 9 × n | `records` | Records |
| | 0–8 | `trailer` | Left over bytes |

### Records

| Offset | Size | Content |
|---|---|---|
| 0 | 4 | X, fixed point: low byte fraction (1/256), upper 24 bits signed integer |
| 4 | 4 | Y, same |
| 8 | 1 | Control: `0x00` stitch, `0x03` color change, `0x04` move |

Positions are **absolute**. The first record of a file is a color change at
(0, 0); each later color change record is at (0, 0) too and carries the
color index (0, 1, 2, …) in the low byte of X. The record count is
`stitch_count` plus the number of color change records (checked in
`random1-wilcom.PCS` and `random1-premier.pcs`). The file has no end
record: Wilcom and My Editor pad with zero bytes, which the spec parses as
all-zero stitch records.

## Versions

No variation observed: `version` is `0x32` in all samples. PCD and PCQ use
the same layout with other hoop codes (0 and 1 in pyembroidery); they are
separate stubs.

## Units and coordinates

- Unit (Unverified): pyembroidery multiplies positions by 5/3 to get 0.1 mm;
  the design `random1` is about 947 × 969 units of 0.1 mm and spans about
  569 × 581 integer PCS units, which matches.
- Positions are absolute and non-negative in the samples, with the design
  placed in the positive quadrant. Y direction is Unverified (pyembroidery
  negates it).
- Fractions in the samples are multiples of about 0.2, which suggests the
  file's native unit is a fifth of the integer unit.

## Open questions

- Meaning of `version`, `hoop_code` values other than 2 and 3.
- Color table: R, G, B order is from pyembroidery; the fourth byte is 0.
  Whether unused entries (zeros or filler) follow a rule.
- Control values other than 0, 3, 4 (pyembroidery stops at any other).
- Whether `stitch_count` is reliable; all samples agree with the rule above.
- Y direction and the exact unit size.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Purpose-built samples are still to be
made. Expected values in the tests were read from the raw bytes using the
layout above.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the four sample files (hex dumps).
- EmbroidePy/samples `random1.txt`, `random1.csv` (pyembroidery dumps of
  the same design): extents, number of stitches and color changes.
- EmbroidePy/pyembroidery `PcsReader.py` (MIT): field order, control
  bits, the 5/3 size ratio and hoop codes.
