# Ameco NEW

| | |
|---|---|
| Spec | [`ameco_new.ksy`](ameco_new.ksy) |
| Extensions | `.new` |
| Vendor | Ameco |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format. A 2-byte header followed by 3-byte records.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 2 | Probably the stitch count (a reader's comment; byte order unknown) |
| 2 | 3 × n | Records: X magnitude, Y magnitude, control |

Control: bit 6 X negative, bit 5 Y negative; low five bits: 0 stitch, `0x11` end, otherwise bit 1 color change, bit 0 jump (move). Bit 7 is ignored by the reader.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm (pyembroidery applies no scale), relative moves, Y up.

## Open questions

- Header: stitch count, its byte order, and other content.
- Meaning of bit 7 and of other command combinations.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.new` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.new` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `NewReader.py` (MIT): header size, record layout, read for understanding.
- No files observed.
