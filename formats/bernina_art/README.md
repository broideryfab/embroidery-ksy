# Bernina ART

| | |
|---|---|
| Spec | [`bernina_art.ksy`](bernina_art.ksy) |
| Extensions | `.art` |
| Vendor | Bernina |
| Priority | Proprietary source format — preview/partial only |
| Status | 🟡 Partial |

Proprietary, compressed, object-based. Only the container is specified, and
that is **Unverified**: no sample file was available, so nothing below was
checked against a real ART file.

## Structure

Unverified. pyembroidery contains an unfinished, commented-out `ArtReader`
(not functional) that describes the file like this:

1. The file is a Compound File Binary ("OLE2") container; it opens the
   stream named `Contents`.
2. In that stream the first 4 bytes are skipped (the reader's comment calls
   them the file size).
3. Every remaining byte is transformed (XOR with 0xD2, then rotated left by
   one bit), and the result is a zlib stream.
4. What the inflated bytes contain is not known; the reader only dumps them.

The spec covers step 1 with the shared type
[`formats/_common/cfb.ksy`](../_common/cfb.ksy): header, first FAT sector and
the first directory sectors. It does not locate the `Contents` stream:
without a file there is no way to tell which directory entry it is, and
the transformation in step 3 cannot be written as one Kaitai `process`
step. libembroidery says only that nothing is known about the format.

## Versions

None known.

## Units and coordinates

Unknown.

## Open questions

- Is the file a compound file at all (the only source is the unfinished
  reader above)?
- Name, size and position of the stream(s); whether `Contents` is the one.
- Everything inside the stream: header, objects, stitches, thread colors.
- Whether the transformation in step 3 is right (read from commented-out code).

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). Needs an
`.art` file saved by Bernina software with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated._

- pyembroidery `ArtReader.py` (MIT), commented-out code: container, stream
  name, 4-byte prefix, byte transformation, zlib. Read for understanding.
- libembroidery `bernina.c` (Zlib): reader and writer are stubs ("We don't
  know much about this format").
- [MS-CFB], Microsoft's public compound file specification.
- No files observed.
