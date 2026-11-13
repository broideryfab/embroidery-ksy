# ZSK ZXY

| | |
|---|---|
| Spec | [`zsk_zxy.ksy`](zsk_zxy.ksy) |
| Extensions | `.zxy` |
| Vendor | ZSK |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format. A short header with a length field, then 3-byte records.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 1 | Unknown |
| 1 | 2 | Header data length `L` (u16 BE) |
| 3 | L | Header data, contents unknown |
| 3 + L | 3 × n | Records: control, X magnitude, Y magnitude |

Control: bit 3 X negative, bit 2 Y negative; with those two bits cleared, 0 is a stitch, bit 1 is a jump, and bit 5 (without bit 1) is a special record: X magnitude `0xff` ends the data, otherwise it is a needle change and the Y byte is the needle number.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves, Y up.

## Open questions

- The first header byte and the header data.
- Unit of the moves.
- Meaning of other control bits (bits 0, 4, 6, 7).

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.zxy` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.zxy` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `ZxyReader.py` (MIT): header length, record layout, read for understanding.
- No files observed.
