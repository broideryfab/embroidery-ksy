# Pulse PXF

| | |
|---|---|
| Spec | [`pulse_pxf.ksy`](pulse_pxf.ksy) |
| Extensions | `.pxf` |
| Vendor | Pulse |
| Priority | Proprietary source format — preview/partial only |
| Status | 🔲 Stub |

Proprietary source format. **Nothing about its layout is known** to this
project: no sample file, no public description, and none of the open-source
embroidery readers consulted handle it. The status therefore stays a stub;
the `.ksy` exposes the whole file as raw bytes and claims no structure.

## Structure

Unknown. Unverified whether the file is a container, compressed or plain.

## Versions

None known.

## Units and coordinates

Unknown.

## Open questions

Everything: magic bytes, header, container type, preview data, stitch data.
The first step, once a file is available, is to check its first bytes for
a signature (for example the compound file signature `D0 CF 11 E0`, which
Wilcom, Bernina and Melco source formats use).

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). Needs a
`.pxf` file saved by Pulse software with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated._

- pyembroidery, pystitch and libembroidery were searched: none mentions PXF
  handling.
- No files observed.
