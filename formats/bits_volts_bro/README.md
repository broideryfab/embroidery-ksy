# Bits & Volts BRO

| | |
|---|---|
| Spec | [`bits_volts_bro.ksy`](bits_volts_bro.ksy) |
| Extensions | `.bro` |
| Vendor | Bits & Volts |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Binary format with a fixed 256-byte header and variable-length records.
All values little-endian.

## Structure

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0x00 | 2 | `magic` | `55 01` |
| 0x02 | 1 | `reserved_0x02` | 0 |
| 0x03 | 9 | `design_name` | NUL-terminated, 8 characters at most |
| 0x0c | 4 | `record_count` | Records after the header, end record not counted |
| 0x10 | 2 | `height` | 0.1 mm (Unverified) |
| 0x12 | 2 | `width` | 0.1 mm (Unverified) |
| 0x14 | 2 | `color_count` | Needle changes + 1 |
| 0x16 | 14 | `reserved_0x16` | Zeros |
| 0x24 | 2 | `unknown_0x24` | `0x0020` in every sample |
| 0x26 | 2 + 2 | `unknown_0x26`, `unknown_0x28` | Signed pair, unknown |
| 0x2a | 214 | `reserved_0x2a` | Zeros |
| 0x100 | … | `records` | Records |

### Records

| Bytes | Meaning |
|---|---|
| `dx dy` (first byte ≠ `0x80`) | Stitch, two signed bytes |
| `80 01 00 xx xx yy yy` | Start position: control `0x00`, two signed 16-bit values |
| `80 01 03 xx xx yy yy` | Move or long stitch with 16-bit deltas (control `0x03`; `0x7e` has the same layout) |
| `80 01 e1..ef xx xx yy yy` | Needle change (needle 1 to 15), followed by a 16-bit move |
| `80 02 e0` | End (control `0xe0`; `0x02` also ends in pyembroidery) |

After the end record all samples have `7e 00 00 00 00`, kept as `trailer`.

The framing above gives a record count that matches `record_count` in all
nine samples. Two observations from the samples go beyond pyembroidery:

- Control `0x00` is followed by two 16-bit values. pyembroidery skips the
  control and reads those four bytes as two stitches. The 16-bit reading is
  supported by `random1-wilcom-a.BRO`, where the pair is (-159, -56): the
  first stitch of `random1` in pyembroidery's dump `random1.txt` is at
  (-158.6, 55.8) (Y negated), and by the pair in `spiralbox-wilcom-b.BRO`,
  which equals the header pair at 0x26 there.
- The pair at 0x26 in the header matches the start position only in some
  samples (random1-wilcom-a: half of it). Left unknown.

## Versions

One layout seen: magic `55 01`. Nothing indicates a version field.
`random*-wilcom-a` and `-b` are different exports of the same design with
different stitch data (the `-b` files hold only four records); the reason is
Unverified.

## Units and coordinates

- Units are 0.1 mm: the delta of `random1-wilcom-a.BRO` records adds up to the
  same extent (947 × 969) as the 0.1 mm values in pyembroidery's dump.
- Deltas are relative. Y is stored with Y up; pyembroidery negates it.
  Unverified.

## Open questions

- Meaning of the escape's second byte (`0x01` / `0x02`), and of the end
  record's trailing `7e 00 00 00 00`.
- Header fields at 0x24 to 0x29; `height` and `width` for random2 differ from
  the measured extent by a few units.
- Whether controls `0x03` and `0x7e` are moves or stitches. The samples read
  as stitches, pyembroidery as moves.
- Needle numbers above 8 and control `0x7e` are not in the samples.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)), all produced by Wilcom. No purpose-built
sample exists yet. Expected values in the tests were read from the raw bytes
with an independent decoder, not from the spec.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the nine sample files (hex dumps).
- EmbroidePy/samples `random1.txt`: first stitch positions and extent of the
  same design.
- EmbroidePy/pyembroidery `BroReader.py` (MIT): header offset 0x100, record
  framing, control codes.
