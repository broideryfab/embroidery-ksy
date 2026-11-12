# Pfaff KSM

| | |
|---|---|
| Spec | [`pfaff_ksm.ksy`](pfaff_ksm.ksy) |
| Extensions | `.ksm` |
| Vendor | Pfaff |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Older Pfaff format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 512 | Header, no known content (Wilcom: 256 × `0x20` then 256 × `0x00`; My Editor: all `0x00`) |
| 512 | 3 × n | Records, the last one has command `0x08` |
| 512 + 3n | 0+ | Trailer, empty in every sample |

### Records

| Byte | Spec field | Content |
|---|---|---|
| 0 | `dy_magnitude` | Absolute Y move |
| 1 | `dx_magnitude` | Absolute X move |
| 2 | `control` | bit 7 always 1; bit 6 X negative; bit 5 Y negative; bits 4..0 command |

The spec decodes `dx`, `dy`, `command_code`, `is_stitch` and `is_end`.

Command codes seen in the samples (low 5 bits of `control`):

| Code | Seen as |
|---|---|
| `0x00` | Stitch |
| `0x07` | First record of every file (`87 00 00`-style, move 0, 0) |
| `0x0b`–`0x10`, `0x1d`, `0x1e` | One per color change, in this order for colors 1–8, then `0x0b`, `0x0c` again for colors 9 and 10 (Unverified: needle numbers) |
| `0x17`, `0x18`, `0x19` | Written around the moves at the start of each color and between stitch runs (Unverified: meaning) |
| `0x1b` | Second to last record (Wilcom), before the end |
| `0x08` | End |
| `0x09`, `0x0a` | My Editor only (Unverified) |

## Versions

No version field. Wilcom and Wings My Editor differ in header filling and
in how they write moves between colors (see Open questions).

## Units and coordinates

- Unit: 0.1 mm (Unverified: derived from the other format readers; the
  spiralbox design has a 100-unit square side and the file stores 100).
- Each record is a move relative to the previous position; sign bits give
  direction. X grows to the right, **Y grows up**: `spiralbox-wilcom.KSM`
  starts with `dy = -100`, `dx = +100`, `dy = +100`, `dx = -100`, and the
  EmbroidePy dump of the same design (`spiralbox.txt`, screen coordinates,
  Y down) starts (0, 0) → (0, 100) → (100, 100) → (100, 0) → (0, 0).
- Maximum magnitude per axis is 127 in the samples (7 bits).

## Open questions

- The header: all samples are blank. Is there ever a name or hoop?
- Bit 7 of `control` is set in every record. Meaning unknown.
- The movement of records with command codes (`0x0b`.., `0x17`..): the
  Wilcom samples carry real moves in some of them; the My Editor file
  `spiralbox-me.ksm` decodes to a different path with the Wilcom rules
  (the first move after a color change differs), so My Editor may store
  moves differently. Not resolved.
- Needle/color codes beyond color 10; stop code `0x05` and trim codes
  (`0x07`, `0x13`, `0x1d` in pyembroidery) are not confirmed by samples.
- libembroidery's writer and its reader disagree on the format; only the
  3-byte layout agrees with the samples.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Purpose-built samples are still to be
made. Expected values in the tests were read from the raw bytes using the
layout above (not from the spec's output) and cross-checked against the
EmbroidePy dump of the same design.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the four sample files (hex dumps).
- EmbroidePy/samples `spiralbox.txt`, `random1.txt` (pyembroidery dumps
  of the same designs): move directions.
- EmbroidePy/pyembroidery `KsmReader.py` (MIT): 512-byte header skip,
  sign bits, command code ranges.
- Embroidermodder/libembroidery `pfaff.c` (Zlib): header size and sign
  bits.
