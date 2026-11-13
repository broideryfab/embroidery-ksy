# Singer CSD

| | |
|---|---|
| Spec | [`singer_csd.ksy`](singer_csd.ksy) |
| Extensions | `.csd` |
| Vendor | Singer |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

An 8-byte identifier followed by a body that is obfuscated byte by byte. The
spec exposes the identifier and the encrypted body only: the obfuscation is
an offset-indexed mask that Kaitai Struct cannot express. The layout of the
body after decryption is described by the type `decrypted_body` in the spec,
and in this README. No dedicated reader exists in pyembroidery; the decoding
comes from one libembroidery reader and was verified on all six samples.

## Structure

| Offset | Size | Spec field | Meaning |
|---|---|---|---|
| 0x00 | 4 | `magic` | `7c 4b c3 74` in every sample |
| 0x04 | u1 | `unknown_0x04` | Differs per design: `3d 39 35 0d 7e 80` |
| 0x05 | 3 | `identifier_tail` | `c8 53 a4` in every sample |
| 0x08 | rest | `encrypted_body` | Obfuscated body |

### Decryption

Verified with the samples, using the description in libembroidery. Let *p* be
the absolute file offset of a byte (the body starts at *p* = 8). Two tables
come from a linear congruential generator seeded with 12 (`0x0c`): with
`seed = seed × 0x41C64E6D + 0x3039` on a 32-bit value, each output is
`(seed >> 16) & 0xff`; the first 479 outputs form `sub`, the next 501 form
`xor`. The plain byte is

```
plain = ((cipher ^ xor[p % 501]) - sub[p % 479]) & 0xff
```

This applies when the first identifier byte is `0x7c`, as in every sample.
libembroidery has another branch for other identifiers, seeded with the first
identifier byte and with a lookup table that remaps the offset. No sample
uses it, so it is not described here (Unverified).

### Decrypted body

Type `decrypted_body`:

| Offset in body | Size | Field | Meaning |
|---|---|---|---|
| 0 | 16 × 3 | `colors` | RGB thread colors; unused entries are 0, 0, 0 |
| 48 | 2 | `unknown_0x30` | `7f 7f` in every sample |
| 50 | 14 | `color_order` | 0, 1 ... 13 in every sample |
| 64 | 3 × n | `records` | Records to the end of the body |

Record: `flags`, `dy_abs`, `dx_abs` (y before x).

| Bits of `flags` | Meaning |
|---|---|
| `0x80` | Set in every sample record |
| `0x40` | y is negative |
| `0x20` | x is negative |
| `0x1f` | Command |

Commands: `0x00` stitch; `0x10` jump (Unverified: it is the move without a
stitch, taken from its frequency and large moves); `0x05` color change
(dx, dy 0; the count is the color count minus one in every sample); `0x0a`
the first record of every file, with no move (unknown); `0x07` the last
record, the end of the design. The type has been run on decrypted samples
and gives the expected 167 records for `random1-wilcom.CSD`.

## Versions

No version field is known. The six samples share the layout above. The
variation in identifier byte 4 is unexplained.

## Units and coordinates

- Moves: 0.1 mm.
- Verified with an independent source: the running sum of `dx` and `dy` of
  `random1-wilcom.CSD` ranges over x -479 to 468 and y -469 to 500; the
  pyembroidery dump `random1.csv` of the design has extents left -479.1 and
  right 468.3, and top -499.6 and bottom 469.3, so the y sign matches
  screen Y reversed.
- The same designs as in the Elna EMD samples; the EMD `width` and `height`
  agree (947 × 969 for `random1`).

## Open questions

- `unknown_0x04` (byte 4): `3d`, `39`, `35` decrease by 4 as the record count
  of `random1` to `random3` increases by 4 (167, 171, 175, summing to 228),
  but `scene` (`0d`, 151 records) and the spiralbox files do not follow it.
  Unverified: a checksum or per-file value.
- `spiralbox-wilcom-a.CSD` has 12 colors and `-b` has 4: together the 16
  colors of the design. Unverified: the design was split across two files.
- Decryption of files with other identifiers (see above).
- `color_order` (0 to 13): its purpose when it is not the identity, and what
  happens with more than 14 colors, since the file has only 16 slots.
- `unknown_0x30`, `0x0a` command, and whether `0x10` is a jump.
- The identifier may encode a Singer machine or software version.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All six samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Tests in `tests/` assert the identifier
only; the decrypted layout is checked outside the test suite (above).
Purpose-built samples are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the six CSD files in EmbroidePy/samples, and of
  `random1.csv`, `random1.txt` (pyembroidery dumps of the source design).
- Embroidermodder/libembroidery (Zlib) `singer.c` (`readCsd`,
  `BuildDecryptionTable`, `DecodeCsdByte`): header size, the mask scheme and
  its constants, record layout, color count. The algorithm was
  re-implemented separately to check the samples and is not part of this
  repository; its other branch (for other identifiers) was not verified.
- EmbroidePy/pyembroidery and inkstitch/pystitch (MIT): searched; neither
  has a CSD reader.
- Elna EMD samples (same designs): extents for cross-checking.
