# RGB thread colors

| | |
|---|---|
| Spec | [`color_rgb.ksy`](color_rgb.ksy) |
| Extensions | `.rgb` |
| Vendor | Various |
| Priority | Thread color companion |
| Status | 🟡 Partial |

Thread color companion file. Not related to Silicon Graphics `.rgb` images.

## Structure

No header, no count: a list of 4-byte entries `red`, `green`, `blue`,
`padding`. The number of colors is `file size / 4` (`num_colors`).
Trailing bytes that do not fill an entry go to `trailer`. This is the same
layout as [`embird_edr`](../embird_edr/README.md).

## Versions

No versions known.

## Units and coordinates

Not applicable (colors only).

## Open questions

- **Everything here is Unverified.** No real-world `.rgb` sample was found
  in the references, so the layout rests on one reader's description.
- The meaning of the fourth byte (read as a 4-byte color in the reader
  consulted; value written back is not documented).
- Which software produces `.rgb` files. Embroidermodder writes one next to
  other formats as an external color file.
- Embroidermodder's `.edr` reader delegates to its `.rgb` reader (comment: "appears identical"),
  and pyembroidery's `EdrReader` agrees with that layout.
- The `.col` files in EmbroidePy/samples are a different, text-based format
  (a count, then `catalog,r,g,b` lines) and are **not** covered here.

## Samples

No redistributable real-world sample exists. [`samples/scene-colors.rgb`](samples/scene-colors.rgb)
is a hand-made 12-byte file (a byte copy of the colors of
`embird_edr`'s `scene-ew.DST.edr`, MIT, ours) that only exercises the
assumed layout; it proves nothing about real files. See
[`samples/MANIFEST.yaml`](samples/MANIFEST.yaml).

## Sources consulted

_Format facts only — no code copied or translated._

- Embroidermodder/libembroidery (Zlib) `readRgb`/`writeRgb`: read for
  understanding; describes RGB as a color-only file with 4 bytes per color.
- EmbroidePy/pyembroidery `EdrReader.py` (MIT): same layout for `.edr`.
