# Brother PEN (Skitch / PP1)

| | |
|---|---|
| Spec | [`brother_pen.ksy`](brother_pen.ksy) |
| Extensions | `.pen` |
| Vendor | Brother |
| Priority | Tier 3 — device stream |
| Status | 🟡 Partial |

The stitch stream a Brother Skitch (PP1) receives over Bluetooth Low Energy.
No header, no colors: only needle positions and flags.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 4 × n | Records; the last one has the data-end flag |
| 4n | 0+ | Trailer (empty in a well-formed stream) |

### Record

Two little-endian signed 16-bit words. Each holds a coordinate shifted left
by 3 and a 3-bit flag field in the low bits.

| Word | Upper 13 bits | Low 3 bits |
|---|---|---|
| X (bytes 0–1) | `x`, signed, 0.1 mm | record kind (`x_flag`) |
| Y (bytes 2–3) | `y`, signed, 0.1 mm | bit set (`y_flags`) |

Record kind (low 3 bits of X):

| Value | Name | Meaning |
|---|---|---|
| 0 | none | Normal record |
| 3 | `color_end` | Last record of a color block; the machine waits for a thread change |
| 5 | `data_end` | Last record of the pattern |

Y flag bits:

| Bit | Spec instance | Meaning |
|---|---|---|
| 0 (`0x01`) | `is_feed` | Move without stitching |
| 1 (`0x02`) | `is_cut` | Cut the thread |

A cut is written as a record with both bits (`0x03`). A color end is written
with the cut bit.

## Units and coordinates

- Unit: 0.1 mm.
- Positions are **absolute**, not relative to the previous record (unlike
  DST). The spec exposes `x` and `y` directly.
- Range: 13 signed bits, −4096 to 4095 (about ±409 mm).
- Direction of the Y axis: not checked in this repository.

## What writers put in the stream

Observed from the encoder the sources describe, not from the spec itself:
this is behavior of one writer, and other writers may differ.

- The first record is the start point, followed by eight tie-in stitches
  that alternate ±0.2 mm along the direction of the next stitches.
- A cut (a long jump over 5 mm, or a trim) is written as eight tie-off
  stitches, one `feed | cut` record at the new position, then eight tie-in
  stitches.
- A color change is written as tie-off stitches, a `color_end` record with
  the cut bit, an optional `feed` to the first position of the next color,
  and tie-in stitches.
- The last record has `data_end`.
- Consecutive identical positions are dropped.

Spec scope note: lock stitches are ordinary records; telling them apart is
a job for consuming applications.

## Versions

No version field, no header.

## Open questions

- Do `.pen` files written by Brother software (as opposed to the stream sent
  to the machine) have a header or a different layout?
- Meaning of X flag values other than 0, 3 and 5, and of Y bit 2 (`0x04`).
- Whether a machine accepts a stream without any `data_end`.
- Direction of Y relative to the machine's hoop.
- The sample is synthetic. A stream captured from a real machine or written
  by Brother's software would be a better test.

## Sources consulted

Format facts only; no code was copied or translated.

- ZigZag (Apache-2.0), `src/formats/pen.rs`: record layout, flag values and
  the encoder behavior listed above; it credits Respira's PEN encoder
  (Apache-2.0) and Brother's PesxToPen as its origin.
- ZigZag's hand-computed test sequence in the same file, used to build
  `samples/two-colors.pen`.
