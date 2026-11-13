# Sunstar SST

| | |
|---|---|
| Spec | [`sunstar_sst.ksy`](sunstar_sst.ksy) |
| Extensions | `.sst` |
| Vendor | Sunstar |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

A zero-filled 0xa0-byte header followed by 3-byte stitch records. No
dedicated reader exists in pyembroidery; the layout comes from one
libembroidery reader and was checked against five files.

## Structure

| Offset | Size | Spec field | Meaning |
|---|---|---|---|
| 0x00 | 0xa0 | `reserved_0x00` | Zero in every sample |
| 0xa0 | 3 × n | `records` | Records to the end of the file |

The file size is `0xa0 + 3 × n`, with no trailer.

### Records

| Byte | Spec field | Meaning |
|---|---|---|
| 0 | `dx_abs` | Absolute x move, 0.1 mm |
| 1 | `dy_abs` | Absolute y move, 0.1 mm |
| 2 | `flags` | See below |

`flags` bits (values seen: `00 01 02 04 10 12 40 42 50 52`):

| Bit | Meaning |
|---|---|
| `0x01` | Color change; dx and dy are 0 |
| `0x02` | Jump (move without stitching) |
| `0x04` | End of the design; the last record, `00 00 04` |
| `0x10` | y is positive; y is negative when the bit is clear |
| `0x40` | x is negative; x is positive when the bit is clear |

Bits `0x08`, `0x20` and `0x80` are 0 in every sample. Every file starts with
two jump records `00 00 02`.

## Versions

No version field. All five samples (Wings My Editor) share this layout.

## Units and coordinates

- Moves: 0.1 mm.
- Sign convention verified by comparison with an independent format: the
  running sum of `dx` and `dy` (`dy` = +`dy_abs` when bit 4 is set) of
  `random1-me.sst` ranges over x -473 to 474 and y -485 to 484, which is
  exactly the extent stored in the header of `random1-me.hus` (see
  [`husqvarna_hus`](../husqvarna_hus/README.md)). With the opposite sign on x
  the range would be -474 to 473.
- As in HUS, stored y is the reverse of screen Y.
- Color changes: the number of `0x01` records is the color count minus one
  in every sample (9, 9, 9, 2 and 15 for 10, 10, 10, 3 and 16 colors).

## Open questions

- The header is all zero in every sample. Whether it can hold a name, colors
  or a stitch count in files from other producers is unknown. Nothing in the
  samples gives a thread palette.
- The y sign bit being inverted compared with x is taken from the data, not
  documented anywhere.
- Is the end record's dx/dy always 0 and the data after it absent? True in
  all samples.
- Only Wings My Editor output was seen. Files from Sunstar's own software
  are not available to us.
- Whether a record can combine jump and color change (`0x03`).

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All five samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Tests in `tests/` check the first
record, the end record and the third record of each file; the third
record's values were also checked through the extent comparison above.
Purpose-built samples are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the five SST files in EmbroidePy/samples.
- Embroidermodder/libembroidery (Zlib) `readSst`: header size (0xa0), record
  size and the flag bits. Its sign rule was re-checked against the HUS
  extents; nothing is copied.
- EmbroidePy/pyembroidery and inkstitch/pystitch (MIT): searched; neither
  has an SST reader.
- Husqvarna HUS samples (same designs): extents used for the sign check.
