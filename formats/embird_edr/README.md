# Embird EDR thread colors

| | |
|---|---|
| Spec | [`embird_edr.ksy`](embird_edr.ksy) |
| Extensions | `.edr` |
| Vendor | Embird |
| Priority | Thread color companion |
| Status | 🟡 Partial |

Thread color companion file: the colors of a design, no stitches.

## Structure

No header, no signature, no count. The file is a list of 4-byte entries:

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 4 × i | 1 | `red` | Red |
| +1 | 1 | `green` | Green |
| +2 | 1 | `blue` | Blue |
| +3 | 1 | `reserved_0x03` | 0 in all samples |

The number of colors is `file size / 4` (`num_colors` instance). Bytes that
do not fill an entry go to `trailer` (none in the samples).

## Versions

No versions known; the format has no version field.

## Units and coordinates

Not applicable (colors only).

## Open questions

- Whether the fourth byte ever holds anything but 0.
- Order of the colors relative to the design: the samples list them in
  color-change order (the first color of `random1-ew.edr`, 135,135,135, is
  also the first entry of `random1-wilcom.col`).
  Unverified for other producers.
- Whether Embird writes other variants (for example thread names).
- Same layout as [`color_rgb`](../color_rgb/README.md) (`.rgb`).

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. Samples come from [EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see [`samples/NOTICE`](samples/NOTICE)). All five were saved
by Embroidery Wizard next to a design. Expected values in the tests come from
the matching `.col` text files in the same repository
(`scene-wilcom.col`, `spiralbox-wilcom.col`) for scene and spiralbox, and from the raw bytes
for the random designs.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the five sample files (hex dumps).
- EmbroidePy/pyembroidery `EdrReader.py` (MIT): 3 color bytes plus one
  skipped byte per entry.
- EmbroidePy/samples `scene-wilcom.col`, `spiralbox-wilcom.col`: the same
  colors as text.
