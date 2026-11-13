# Sierra EYS

| | |
|---|---|
| Spec | [`sierra_eys.ksy`](sierra_eys.ksy) |
| Extensions | `.eys` |
| Vendor | Sierra |
| Priority | Tier 3 — long tail |
| Status | 🔲 Stub |



## Structure

_TODO: file layout, header fields, record encoding._

## Versions

_TODO: known versions and how to detect them._

## Units and coordinates

_TODO: unit size, axis directions, relative vs. absolute positions._

## Open questions

_TODO: unknown fields and unverified assumptions._

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- libembroidery `sierra.c` (Zlib): the .eys reader and writer are empty stubs ("not been finished"), so no structure can be taken from it. pyembroidery has no EYS reader. No files observed. The spec stays a stub until a sample or documentation is available.
