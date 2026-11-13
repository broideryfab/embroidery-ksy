# Toyota 100

| | |
|---|---|
| Spec | [`toyota_100.ksy`](toyota_100.ksy) |
| Extensions | `.100` (samples: `.101`) |
| Vendor | Toyota |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Headerless stitch file made of 4-byte records.

**No `.100` file is available.** The only redistributable samples are two
`.101` files written by Wings My Editor. They share the 4-byte record layout
read by pyembroidery for `.100`, so this spec describes them; whether a
real `.100` file is identical is Unverified.

## Structure

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0 | 1 | `control` | Record type |
| 1 | 1 | `reserved_0x01` | Always 0 |
| 2 | 1 | `x_raw` | X offset, bit 7 sign, low 7 bits magnitude |
| 3 | 1 | `y_raw` | Y offset, same encoding |

The last record has control `0x1F` (end). Both samples then have 2 zero
bytes, which the spec keeps as `trailer` (file size = 4 × records + 2).

Control values seen:

| Control | Meaning |
|---|---|
| `0x83` | Move (offsets are the jump) |
| `0xA1`, `0xC1`, `0xE1` | Stitch. `0xE1` with offsets 0 is common. Meaning of bits 5 and 6 Unverified |
| `0x82`, `0x84` | One `0x82` then one `0x84`, offsets 0, at the end of each color block. Probably stop and color change, Unverified |
| `0x81` | Seen in `random1-me.101` with offsets as in a move. Unverified (trim?) |
| `0x1F` | End |

In `random1-me.101` there are 9 `0x82` and 9 `0x84` records, matching the 9
color changes of the same design in the 10O file.

## Versions

None known.

## Units and coordinates

- Offsets are relative. Unit (Unverified): 0.1 mm, same values as the 10O
  files of the same design (the first stitch of `random1-me.101` is
  (-76, -36), as in `random1-me.10O`).
- `dy` is the stored value; pyembroidery negates it.

## Open questions

- Real `.100` files and how they differ from `.101`.
- pyembroidery treats `0x61` as stitch, other odd values as move and even
  values as color change. The samples have no `0x61`; they use `0xA1`,
  `0xC1`, `0xE1`, and `0x82` / `0x84`, so that reader does not describe
  them well.
- Meaning of control bits 5 and 6 and of `0x81`.
- Byte 1: always 0 here.
- Raw `0x80` (negative zero) is not in the samples.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Expected values in the tests were read
from the raw bytes and compared with the 10O file of the same design.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the sample files (hex dumps), compared with
  `random1-me.10O` and `spiralbox-me.10O`.
- EmbroidePy/pyembroidery `A100Reader.py` (MIT): record size, byte order of
  X and Y, sign-and-magnitude coding.
