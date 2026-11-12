# Sunstar DAT

| | |
|---|---|
| Spec | [`sunstar_dat.ksy`](sunstar_dat.ksy) |
| Extensions | `.dat` |
| Vendor | Sunstar |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Shares the `.dat` extension with [Barudan DAT](../barudan_dat/README.md);
detect by content. **No redistributable sample exists**, so this spec is
written from another reader's code only and nothing in it is confirmed
against a real file. Everything is Unverified.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 256 | Header; the spec keeps it as raw bytes |
| 256 | 3 × n | Stitch records until the end of the file or a record with control byte `0x00` |

### Header

Unverified: the stitch data starts at offset `0x100`. The bytes before it are
not decoded. A reader's commented-out code suggests a 16-bit little-endian
stitch count at offset 2; the spec exposes it as `stitch_count_candidate`
for inspection but does not rely on it.

### Stitch records (Unverified)

| Byte | Meaning |
|---|---|
| 0 | X: bit 7 = negative, bits 0–6 = magnitude |
| 1 | Y: bit 7 = negative, bits 0–6 = magnitude (the source reader flips it to screen coordinates, so a positive value here is Y up) |
| 2 | Control: `0x07` stitch, `0x04` jump, `0x80` trim, `0x87` color change, `0x84` initial/info stitch, `0x00` end |

Trim and color change records can also carry a move. One record moves at most
±127 units per axis.

## Versions

None known. Detection against Barudan DAT: the source reader tries the Barudan layout
first (control byte at offset 0 with bit 7 set) and, if that fails, reads the
file as Sunstar from offset `0x100`. The spec does not detect this itself;
consumers should decide by content.

## Units and coordinates

Unverified: unit 0.1 mm, relative moves, Y up (the source reader inverts it
for screen use).

## Open questions

- All header fields (size 0x100 assumed from one reader).
- Unit size, thread color information, hoop size.
- Meaning of control `0x84` and of any other control bytes; the source reader
  stops at an unknown control byte.
- A reliable content test to tell Sunstar DAT from Barudan DAT.
- No sample was available: the spec has not been run against any real file.
  The tests directory is empty on purpose.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). None yet: no
redistributable Sunstar DAT file was found (EmbroidePy/samples has none).
Purpose-built or contributed files are needed.

## Sources consulted

- EmbroidePy/pyembroidery `DatReader.py` (MIT): the Sunstar branch, read for
  understanding of the offset `0x100`, record layout and control codes.
  No code copied.
- Embroidermodder/libembroidery and pystitch: searched, no Sunstar DAT
  documentation.
