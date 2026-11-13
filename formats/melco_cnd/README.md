# Melco CND

| | |
|---|---|
| Spec | [`melco_cnd.ksy`](melco_cnd.ksy) |
| Extensions | `.cnd` |
| Vendor | Melco |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists and no open-source reader decodes this format**, so the spec only exposes the raw file.

## Structure

Unverified and undecoded: the spec exposes the whole file as the raw bytes `body`. Nothing about the header or the stitch encoding is known from permissively licensed sources.

## Versions

None known.

## Units and coordinates

Unknown.

## Open questions

- Everything: header, stitch encoding, units, color information.
- Whether the file is related to the Brother PEC/PES family or to Melco EXP is not known.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.cnd`
file was found in EmbroidePy/samples or elsewhere with a license that allows
redistribution, so the spec is unverified against real files and has no
tests. Needs: a real `.cnd` produced by the vendor's software or a machine,
with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- libembroidery `melco.c`, `data.c` (Zlib): lists `.cnd` as a stitch-only Melco format; the source says "We don't know much about this format" and has stub reader/writer. Nothing else learned.
- pyembroidery (MIT): no `.cnd` reader.
- No files observed.
