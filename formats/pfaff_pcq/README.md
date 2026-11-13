# Pfaff PCQ

| | |
|---|---|
| Spec | [`pfaff_pcq.ksy`](pfaff_pcq.ksy) |
| Extensions | `.pcq` |
| Vendor | Pfaff |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Pfaff PCQ has the same layout as [PCS](../pfaff_pcs/README.md) and PCD. In the
samples, the PCQ and PCD files written by Wilcom for the same design are
byte for byte identical (`cmp` finds no difference), so nothing in the file
tells the two apart.

## Structure

All values little-endian.

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0 | 1 | `version` | `0x32` in every sample |
| 1 | 1 | `hoop_code` | 3 (large) or 2 (small, 2 samples) |
| 2 | 2 | `num_colors` | Color table entries (16 in every sample) |
| 4 | 4 × count | `colors` | R, G, B, 0 |
| 4 + 4 × count | 2 | `stitch_count` | Stitch and move records, not counting color changes or the final zero record |
| +2 | 9 × n | `records` | Records |
| | 0–8 | `trailer` | Left over bytes (5 zero bytes in the samples) |

### Records

| Offset | Size | Content |
|---|---|---|
| 0 | 4 | X, fixed point: low byte fraction (1/256), upper 24 bits signed integer |
| 4 | 4 | Y, same |
| 8 | 1 | Control: `0x00` stitch, `0x03` color change, `0x04` move |

Positions are **absolute**. The first record is a color change at (0, 0);
each later color change record is at (0, 0) too and carries the color index
(0, 1, 2, ...) in the low byte of X. In all six samples
`stitch_count` + color changes + 1 = number of complete records, the last
one being all zero.

The file has no end record. The six samples end with one all-zero record,
which the spec parses as a stitch at 0, 0, followed by 5 more zero bytes
(`trailer`).

## Versions

No variation observed: `version` is `0x32` in all samples. pyembroidery's
reader comments say hoop code 0 is PCD and 1 is PCQ (MAXI), 2 is PCS with a
small hoop and 3 PCS with a large hoop. The PCQ samples have 3 and 2, so
that mapping is not confirmed (Unverified).

## Units and coordinates

- Unit (Unverified): pyembroidery multiplies positions by 5/3 to get 0.1 mm,
  the same as for PCS.
- Positions are absolute and non-negative in the samples. Y direction is
  Unverified (pyembroidery negates it).
- Fractions are multiples of about 0.2 (0x33, 0x66, ...).

## Open questions

- Why the extension PCQ exists if the bytes equal PCD; whether any software
  writes different hoop codes (0 or 1) or other values.
- Meaning of `version`, and of `hoop_code` values.
- Color table: whether unused entries (zeros) follow a rule; the fourth byte
  is always 0.
- Control values other than 0, 3, 4.
- Y direction and the exact unit size.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)); all are written by Wilcom. Tests check
the header fields and a few records, with values read from the raw bytes
using the layout above. No purpose-built sample exists yet.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the six sample files (hex dumps) and comparison with the
  matching PCD files and the PCS samples of the same designs.
- EmbroidePy/pyembroidery `PcqReader.py` (MIT): field order, control
  bits, the 5/3 ratio, hoop codes.
