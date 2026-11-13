# Melco DEM

| | |
|---|---|
| Spec | [`melco_dem.ksy`](melco_dem.ksy) |
| Extensions | `.dem` |
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
- Whether DEM is related to Tajima DST, as libembroidery's placeholder suggests. Nothing confirms it.
- Whether the file is related to the Brother PEC/PES family or to Melco EXP is not known.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No `.dem`
file was found in EmbroidePy/samples or elsewhere with a license that allows
redistribution, so the spec is unverified against real files and has no
tests. Needs: a real `.dem` produced by the vendor's software or a machine,
with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- libembroidery `melco.c`, `data.c` (Zlib): lists `.dem` as stitch-only; its reader and writer just call the DST ones with a note "defaulting to dst". That is a placeholder, not evidence that DEM is DST, so the spec does not assume it.
- pyembroidery (MIT): no `.dem` reader.
- No files observed.
