# Eltac EXY

| | |
|---|---|
| Spec | [`eltac_exy.ksy`](eltac_exy.ksy) |
| Extensions | `.exy` |
| Vendor | Eltac |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Stitch-only format. A 256-byte header is followed by records that other readers decode like Tajima DST records.

**No redistributable sample exists for this format**, so the spec is unverified against real files and has no tests. Everything below is taken from how other open-source readers describe the format.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 256 | Header (Unverified: contents unknown, skipped by readers) |
| 256 | 3 × n | Records, as in [Tajima DST](../tajima_dst/README.md); the end record has third byte `0xf3` |

The spec reuses `tajima_dst::stitch_record`. libembroidery decodes the flags slightly differently from its DST reader: bit 7 trim, bit 6 stop, `(b & 0xc3) == 0xc3` both, `0xf3` end. pyembroidery simply reads the records as DST. The spec follows DST; the difference is Unverified.

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm, relative moves, Y up, as in DST.

## Open questions

- What the 256-byte header holds (design name, extents, counts?).
- Whether the command bits are exactly the DST ones.
- Whether a trailer follows the end record.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.exy` file was found in EmbroidePy/samples or elsewhere with a license that allows redistribution. A file made by us would only test our own assumptions, so none was added. Needs: a real `.exy` file produced by the vendor's software or a machine, with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference used (documentation, observed files, other projects read for understanding)._

- pyembroidery `ExyReader.py` (MIT): header size and DST record reuse, read for understanding.
- libembroidery `eltac.c` (Zlib): header size, flag decoding, read for understanding.
- No files observed.
