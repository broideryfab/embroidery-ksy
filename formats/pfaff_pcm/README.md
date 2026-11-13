# Pfaff PCM

| | |
|---|---|
| Spec | [`pfaff_pcm.ksy`](pfaff_pcm.ksy) |
| Extensions | `.pcm` |
| Vendor | Pfaff |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Older Pfaff format. Same record layout as [PCS](../pfaff_pcs/README.md), but
all values are **big-endian** and colors are indices into a fixed palette.

## Structure

All values big-endian.

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0 | 1 | `version` | `0x32` in every sample |
| 1 | 1 | `hoop_code` | 3 (most samples) or 2 (`spiralbox-wilcom.PCM`) |
| 2 | 2 | `num_colors` | Color table entries (16 in every sample) |
| 4 | 2 × count | `colors` | Palette index 0–15 per entry |
| 4 + 2 × count | 2 | `stitch_count` | See below |
| +2 | 9 × n | `records` | Records |
| | 0–8 | `trailer` | Left over bytes |

### Records

| Offset | Size | Content |
|---|---|---|
| 0 | 4 | X, fixed point: upper 24 bits signed integer, low byte fraction (1/256) |
| 4 | 4 | Y, same |
| 8 | 1 | Control: `0x00` stitch, `0x03` color change, `0x04` move |

This is the PCS record with each 32-bit value stored big-endian. Positions
are **absolute**. The first record is a color change; every color change
record is at (0, 0) with the **palette index** of the new color in the low
byte of X. Wilcom files list the colors of the design in order of use in
the color table, so the n-th change repeats `colors[n]`. My Editor files
store the identity table 0..15 and the change records pick from it.

The color table holds only indices. pyembroidery maps them to a fixed
16-color palette (black, navy, blue, teal, cyan, purple, magenta, maroon,
red, green, lime, olive, yellow, gray, silver, white). The palette is not in
the file (Unverified).

My Editor writes many records with control `0x04` followed by one with `0x00` at
the same position. Wilcom does this too, to a lesser degree (one per jump).

## Versions

No variation observed: `version` is `0x32` in all samples.

## Units and coordinates

- Unit (Unverified): pyembroidery multiplies positions by 5/3 to get 0.1 mm,
  as for PCS.
- Positions are absolute and non-negative in the samples. Y direction is
  Unverified (pyembroidery negates it).
- Fractions are multiples of about 0.2 in My Editor files and arbitrary in
  Wilcom files; in color change records the low byte is the palette index.

## End of file

There is no end record. My Editor files end with one all-zero record and 4
more zero bytes (`trailer`). Wilcom files end exactly after the last record.

## Open questions

- `stitch_count`: in My Editor files it is the number of 9-byte records
  minus 5. In Wilcom files it is unrelated to the record count (156 for 79
  records in `random2-wilcom.PCM`). The reader in pyembroidery ignores it.
- Meaning of `version` and of `hoop_code` values other than 2 and 3.
- The palette order and whether any Pfaff software uses another one.
- Control values other than 0, 3, 4.
- Y direction and the exact unit size.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)): five from Wings My Editor and four from
Wilcom. No purpose-built sample exists yet. Tests check header fields and a
few records, with values read from the raw bytes using the layout above; no
independent reader output was available for these files.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the nine sample files (hex dumps).
- EmbroidePy/pyembroidery `PcmReader.py` (MIT): field order, endianness,
  control bits, the 5/3 ratio and the 16-color palette.
- The existing [PCS spec](../pfaff_pcs/README.md) in this repository.
