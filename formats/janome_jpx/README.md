# Janome JPX

| | |
|---|---|
| Spec | [`janome_jpx.ksy`](janome_jpx.ksy) |
| Extensions | `.jpx` |
| Vendor | Janome |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from pyembroidery's reader.

## Structure

All integers are little-endian.

| Offset | Size | Content |
|---|---|---|
| 0x00 | 4 | `stitches_offset`: offset of the first stitch record |
| 0x04 | 0x1c | `unknown_0x04` |
| 0x20 | 4 | `num_color_indices` |
| 0x24 | 0x18 | `unknown_0x24` |
| 0x3c | 4 × n | `color_indices`: Janome palette index per color (u4) |
| `stitches_offset` | 2 or 4 per record | Stitch records, up to and including the end record |

### Stitch records

Same scheme as [`janome_sew`](../janome_sew/README.md) and Melco EXP, except that the end record also carries a move.

| Bytes | Meaning |
|---|---|
| `dx dy` | Stitch: signed bytes, 0.1 mm. The first byte must not be 0x80. |
| `80 01 dx dy` | Color change; the move is usually 0, 0. |
| `80 02 dx dy` | Jump (move without stitching) |
| `80 10 dx dy` | End |

Any other command code stops the reader in pyembroidery; the spec decodes it as a command without a name.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves. pyembroidery negates the Y value, so Y is up in the file.

## Open questions

- Contents of the two unknown header blocks (0x04..0x20 and 0x24..0x3c); thumbnails or design size probably live there.
- Whether `stitches_offset` is always right after the color list.
- Whether other command codes exist.
- Whether files without an end record exist.
- Meaning of `color_indices`: pyembroidery treats them as opaque numbers.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.jpx`
file was found in EmbroidePy/samples or elsewhere with a license that allows
redistribution, so the spec is unverified against real files and has no
tests. Needs: a real `.jpx` produced by the vendor's software or a machine,
with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- pyembroidery `JpxReader.py` (MIT): header offsets and record codes, read for understanding.
- libembroidery (Zlib): has no JPX support.
- No files observed.
