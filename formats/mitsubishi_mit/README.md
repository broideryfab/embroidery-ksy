# Mitsubishi MIT

| | |
|---|---|
| Spec | [`mitsubishi_mit.ksy`](mitsubishi_mit.ksy) |
| Extensions | `.mit` |
| Vendor | Mitsubishi |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format. No header; a stream of 2-byte records.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 2 × n | Records |

Each record: byte 0 = X (bit 7 sign, bits 6..5 command bits 3..2, bits 4..0 magnitude), byte 1 = Y (same layout, command bits 1..0). Commands as pyembroidery handles them: `0b0111`, `0b0100`, `0b0101` stitch; `0b1100` jump; `0b1000` color change when the previous record was `0b0111`; `0b0000` end marker; any other value a stitch. The reader keeps reading after a `0b0000` record.

## Versions

None known.

## Units and coordinates

Magnitudes are 5 bits (0..31). pyembroidery multiplies them by 2 and treats the result as 0.1 mm; the raw unit is therefore Unverified, and the spec exposes raw values. Relative moves.

## Open questions

- Raw unit (0.1 mm × 2?).
- What the individual command values mean; the reader acts on few of them.
- Whether there is any header or trailer.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.mit` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.mit` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `MitReader.py` (MIT): record layout and commands, read for understanding.
- No files observed.
