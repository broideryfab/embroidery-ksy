# Gold Thread GT

| | |
|---|---|
| Spec | [`gold_thread_gt.ksy`](gold_thread_gt.ksy) |
| Extensions | `.gt` |
| Vendor | Gold Thread |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format. A 512-byte header is followed by the same 3-byte records as [Fortron FXY](../fortron_fxy/README.md).

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 512 | Header (Unverified: contents unknown, skipped by readers) |
| 512 | 3 × n | Records: Y magnitude, X magnitude, control |

Records are decoded exactly as in FXY; see that README for the control byte. The only difference known to both readers is the header size (512 here, 256 for FXY).

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves, Y up (as DSZ).

## Open questions

- Header contents.
- Command values: the readers disagree on bits 0 and 1 (jump vs trim/stop), see FXY.
- How the file ends and whether a trailer exists.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.gt` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.gt` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `GtReader.py` and `DszReader.py` (MIT): header size, record layout, read for understanding.
- libembroidery `gold_thread.c` (Zlib): same layout, read for understanding.
- No files observed.
