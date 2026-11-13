# Fortron FXY

| | |
|---|---|
| Spec | [`fortron_fxy.ksy`](fortron_fxy.ksy) |
| Extensions | `.fxy` |
| Vendor | Fortron |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format. A 256-byte header is followed by 3-byte records in the same layout as [ZSK DSZ](../zsk_dsz/README.md).

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 256 | Header (Unverified: contents unknown, skipped by readers) |
| 256 | 3 × n | Records: Y magnitude, X magnitude, control |

Control byte: bit 6 X negative, bit 5 Y negative; command from the rest. pyembroidery uses its DSZ decoder: low five bits 0 stitch, 1 jump, `0x82` stop, `0x9b` trim, `0x83`..`0x9a` needle change, any other control ends the data. libembroidery reads the same layout with end `0x91`, bit 0 trim and bit 1 stop. The two readers disagree on the low bits; the spec follows pyembroidery for commands and accepts `0x90`/`0x91` as end.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves, Y up (as DSZ).

## Open questions

- Header contents.
- Command values: the two readers disagree on bits 0 and 1 (jump vs trim/stop).
- How the file ends (`0x90` or `0x91`) and whether a trailer exists.
- libembroidery's header comment in `unsorted.c` also mentions a Smoothie G-code format for .fxy; unrelated to the structure above.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.fxy` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.fxy` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `FxyReader.py` and `DszReader.py` (MIT): header size, record layout, read for understanding.
- libembroidery `unsorted.c` `readFxy` (Zlib): same layout, different command bits, read for understanding.
- No files observed.
