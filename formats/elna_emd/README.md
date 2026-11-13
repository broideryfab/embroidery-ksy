# Elna EMD

| | |
|---|---|
| Spec | [`elna_emd.ksy`](elna_emd.ksy) |
| Extensions | `.emd` |
| Vendor | Elna |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

A 0x30-byte header that starts with `JEMD0`, then 2-byte stitch records to
the end of the file. Only five files (all Wilcom) were available; the header
is only partly understood.

## Structure

All multi-byte integers are **little-endian**.

| Offset | Size | Spec field | Meaning |
|---|---|---|---|
| 0x00 | 5 | `magic` | `JEMD0` |
| 0x05 | u1 | `unknown_0x05` | 0 in every sample |
| 0x06 | u2 | `unknown_0x06` | 101 (`0x65`) in every sample |
| 0x08 | u2 | `unknown_0x08` | 10 in every sample |
| 0x0a | u2 | `width` | Design width, 0.1 mm |
| 0x0c | u2 | `height` | Design height, 0.1 mm |
| 0x0e | u2 | `num_colors` | Colors (color changes + 1) |
| 0x10 | u2 | `unknown_0x10` | See Open questions |
| 0x12 | 10 | `reserved_0x12` | Zero |
| 0x1c | s2 | `unknown_0x1c` | -24 (`e8 ff`) in every sample |
| 0x1e | 18 | `reserved_0x1e` | Zero |
| 0x30 | 2 × n | `records` | Records to the end of the file |

### Records

Two bytes each:

| Bytes | Meaning |
|---|---|
| `dx dy` (first byte not `0x80`) | Stitch, signed bytes in 0.1 mm units |
| `80 2a` | Color change |
| `80 80 dx dy` | Move without stitching; two more bytes follow |
| `80 7d` | Unknown; the first record in every sample |
| `80 90` | Unverified: trim; once, shortly before the end |
| `80 ad` | Unverified: trim; in no sample (taken from other readers) |
| `80 fd` | End of the design; the last record |

The spec reads `dx` and `dy` as `s1`; a control record is `dx == -128`, with
the control code in `dy & 0xff`. A genuine stitch with dx = -128 therefore
cannot be stored. An unknown control code has no length rule: readers differ
(one stops, one skips the record), and no sample has one.

## Versions

No version field is known. The five samples have the same header values
except for width, height, colors and `unknown_0x10`.

## Units and coordinates

- Moves, `width` and `height`: 0.1 mm (the divisor other readers use).
- Verified with independent data: in every sample the running sum of the
  record values, started at (0, 0), ranges over 0 to `width` in x and 0 to
  `height` in y. The same designs as Singer CSD files (decrypted with the
  algorithm in [`singer_csd`](../singer_csd/README.md)) have x ranges and y
  ranges of the same size, for example 947 × 969 for `random1`.
- Y direction: stored y is the reverse of screen Y (the other readers negate
  it).
- The last stitch record is always `00 00`, just before `80 fd`.

## Open questions

- `unknown_0x10`: 156, 160, 164, 147 and 125 in the samples; it is close to
  the number of stitch and move records in the file but not equal to it
  (155, 155, 159, 156 and 117). Unverified: a stitch count, possibly of the
  source design before long moves are split.
- `unknown_0x06` (101) and `unknown_0x08` (10) never change; they may be a
  version and a hoop or machine code.
- `unknown_0x1c` (-24) is the same in every sample.
- Is the color table elsewhere? No file has colors; the design carries only
  the number of colors.
- The meaning of `80 7d` and the distinction between `80 90` and `80 ad`.
- Only Wilcom-written files were seen; other producers may use other header
  values.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All five samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Expected `width` and `height` in
`tests/` come from the extents of the same designs in the Singer CSD
samples, decrypted separately; the rest are values read from the files.
Purpose-built samples are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the five EMD files in EmbroidePy/samples (hex dumps,
  decoded records, running sums), and of the same designs in the Singer CSD
  samples.
- EmbroidePy/pyembroidery (MIT) `EmdReader`: header start offset (0x30),
  record encoding and control codes.
- Embroidermodder/libembroidery (Zlib) `readEmd`: header field offsets
  (width, height, colors) and the 0.1 mm scale; its header reading is
  partly inconsistent with the samples and was not followed.
