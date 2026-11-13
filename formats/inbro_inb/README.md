# Inbro INB

| | |
|---|---|
| Spec | [`inbro_inb.ksy`](inbro_inb.ksy) |
| Extensions | `.inb` |
| Vendor | Inbro |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

A 0x2000-byte header followed by 3-byte records. All values little-endian.

## Structure

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0x00 | 9 | `design_name` | NUL-terminated, 8 characters at most |
| 0x09 | 2 | `unknown_0x09` | 1 in every sample |
| 0x0b | 4 | `record_count` | Records, end record not counted |
| 0x0f | 2 | `width` | 0.1 mm |
| 0x11 | 2 | `height` | 0.1 mm |
| 0x13 | 2 | `color_count` | Color changes + 1 |
| 0x15 | 2 | `unknown_0x15` | Unknown |
| 0x17 | 2 | `reserved_0x17` | 0 |
| 0x19, 0x1b | 2 + 2 | `unknown_0x19`, `unknown_0x1b` | 100, 100 |
| 0x14b | 4 × 2 | `extent_left/right/up/down` | Bounding box relative to the start, 0.1 mm |
| 0x2000 | 3 × n | `records` | Records |

### Records

| Byte | Content |
|---|---|
| 0 | X magnitude |
| 1 | Y magnitude |
| 2 | Control: low nibble `0` stitch, `1` color change, `2` move; the byte `0x04` ends. Bit `0x40` X negative; bit `0x20` Y negative |

In every non-end record of the samples one of `0x40`/`0x80` and one of
`0x10`/`0x20` is set (control values `0x50 0x52 0x60 0x62 0x90 0x91 0x92 0xa0
0xa2`), so `0x80` and `0x10` are probably the positive signs. Long moves are
split into several records of at most 255 units (the first two records of
`random1-wilcom.INB` are moves of (-80, -28) and (-79, -28), together the
first point (-159, -56) of the BRO sample and of pyembroidery's dump).

## Versions

None observed; all five samples are Wilcom exports with the same header
constants.

## Units and coordinates

- 0.1 mm, relative deltas. Adding the deltas gives bounding boxes equal to
  the header's extents in all five samples (left, right, then Y up and
  Y down), and `width` = left + right, `height` = up + down.
- Y direction: pyembroidery negates the sign it derives from `0x20`, so the
  file is probably Y up. Unverified.

## Open questions

- `unknown_0x09`, `unknown_0x15` (109, 113, 117, 20, 16), `unknown_0x19` and
  `unknown_0x1b`.
- Meaning of bits `0x80` and `0x10`.
- Control values with other low nibbles (pyembroidery stops at them).
- Whether files without an end record exist.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). No purpose-built sample exists yet.
Expected values in the tests were read from the raw bytes with an
independent decoder.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the five sample files (hex dumps).
- EmbroidePy/samples `random1.txt`: extents and first stitch of the design.
- EmbroidePy/pyembroidery `InbReader.py` (MIT): stream start 0x2000, record
  layout and sign bits.
