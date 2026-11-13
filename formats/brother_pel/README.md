# Brother PEL

| | |
|---|---|
| Spec | [`brother_pel.ksy`](brother_pel.ksy) |
| Extensions | `.pel` |
| Vendor | Brother |
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

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.pel`
file was found in EmbroidePy/samples or elsewhere with a license that allows
redistribution, so the spec is unverified against real files and has no
tests. Needs: a real `.pel` produced by the vendor's software or a machine,
with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- libembroidery `brother.c`, `data.c` (Zlib): lists `.pel` as a stitch-only Brother format; reader and writer are stubs that print "not implemented". Nothing else learned.
- pyembroidery (MIT): no `.pel` reader.
- No files observed.
