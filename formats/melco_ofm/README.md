# Melco OFM

| | |
|---|---|
| Spec | [`melco_ofm.ksy`](melco_ofm.ksy) |
| Extensions | `.ofm` |
| Vendor | Melco |
| Priority | Proprietary source format — preview/partial only |
| Status | 🟡 Partial |

Proprietary source format. Only the container is specified, and that is
**Unverified**: no sample file was available, so nothing below was checked
against a real OFM file.

## Structure

Unverified. The OFM reader in libembroidery, which is switched off in the
source ("overridden during development") and was never confirmed to work,
treats the file as follows:

1. The file is a Compound File Binary ("OLE2") container; it opens the
   stream named `EdsIV Object`.
2. In that stream a thread table is at offset 0x1C6: a count of colors,
   then per color a 4-byte color, library id, color number and a name in
   UTF-16, followed by thread library names.
3. After that a class name and serialized objects (MFC-style class tags
   such as 0x809C) carry the stitches: a count, then 5-byte records of a
   flag (0 or 32) and big-endian 16-bit X and Y in 0.1 mm.

Only step 1 is specified here, through the shared type
[`formats/_common/cfb.ksy`](../_common/cfb.ksy): header, first FAT sector and
the first directory sectors; the `EdsIV Object` entry must be found by name
in the exposed directory. Steps 2 and 3 are listed so the knowledge is not
lost, but they come from code that is not known to work and are not
turned into a spec without a file. The stream's location is also not
resolved (see the container's limits in `cfb.ksy`).

## Versions

None known.

## Units and coordinates

Unverified: 0.1 mm per the reader above; the reader flips both axes at the
end.

## Open questions

- Is the file a compound file with an `EdsIV Object` stream?
- Layout of the thread table, class names and stitch blocks.
- Whether stitches are absolute (the reader adds them as absolute points).
- Preview images or other streams, if any.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). Needs an
`.ofm` file saved by Melco software with the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated._

- libembroidery `readOfm` and helpers (Zlib): stream name, thread-table and
  stitch-block description above. Read for understanding; the reader is
  disabled in the source.
- [MS-CFB], Microsoft's public compound file specification.
- No files observed.
