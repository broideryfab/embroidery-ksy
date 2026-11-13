# Gunold STC

| | |
|---|---|
| Spec | [`gunold_stc.ksy`](gunold_stc.ksy) |
| Extensions | `.stc` |
| Vendor | Gunold |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format. A 40-byte header followed by 3-byte records.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 40 | Header; a reader's comment suggests text like `DESIGN: xxxxxx STITCHES: xxxx` (not confirmed) |
| 40 | 3 × n | Records: signed X, signed Y, command |

Command: 0 move (jump), 1 stitch, 25 end, any other value is a needle change to needle `command − 2`.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves, Y up. X and Y are plain signed bytes.

## Open questions

- Header contents, including whether it is text and where the design name and stitch count are.
- Valid needle numbers and whether 25 is also a needle value.
- Unit of the moves.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.stc` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.stc` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `StcReader.py` (MIT): header size, record layout, read for understanding.
- No files observed.
