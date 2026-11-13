# ThredWorks THR

| | |
|---|---|
| Spec | [`thredworks_thr.ksy`](thredworks_thr.ksy) |
| Extensions | `.thr` |
| Vendor | ThredWorks |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format of the Thred program, with absolute positions, a form attribute word per stitch and 16 custom colors. Only libembroidery documents it, so most fields are Unverified.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 3 | Signature (`72 68 74` according to the reader's constant) |
| 3 | 1 | Version (0, 1 or 2) |
| 4 | 4 | Length (Unverified) |
| 8 | 2 | Stitch count |
| 10 | 2 | Hoop size code |
| 12 | 14 | Reserved |
| 26 | 144 | Extension, versions 1 and 2 only: hoop X, hoop Y, granularity (3 × 4), creator name (50), modifier name (50), aux format (1), reserved (31) |
| | 12 × n | Stitches: X (4), Y (4), attributes (4) |
| | 16 | Bitmap name |
| | 4 | Background color (RGB + pad) |
| | 64 | 16 custom colors (RGB + pad) |
| | 16 | Thread sizes as ASCII (from a comment; kept raw) |

Attribute word (from a reader's comment): bits 0..3 color, 4..14 form pointer, 19 not a form stitch, 20 center walk, 21 edge walk, 22 underlay, 23 knot, 24 feather, 25..27 layer, 29..30 stitch type (0 none, 1 fill, 2 border fill, 3 applique), 31 edited.

## Versions

None known.

## Units and coordinates

Positions are absolute, divided by 10 by the reader to get millimeters, so 0.1 mm. Unverified: libembroidery reads the 32-bit coordinates as integers; Thred itself may store floats, in which case the spec's integer type is wrong.

## Open questions

- Whether X and Y are integers or floats.
- The signature bytes: the reader compares a 32-bit constant.
- Meaning of header length and hoop size code.
- Extension field types (integers or floats) and units.
- The thread size block.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.thr` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.thr` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- libembroidery `unsorted.c` `readThr` / `writeThr` (Zlib): header, extension, stitches and trailing blocks, attribute bit comment, read for understanding.
- pyembroidery has no reader for this format.
- No files observed.
