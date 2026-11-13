# Pfaff T01

| | |
|---|---|
| Spec | [`pfaff_t01.ksy`](pfaff_t01.ksy) |
| Extensions | `.t01` |
| Vendor | Pfaff |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

**No redistributable sample exists for this format**, so the spec is
unverified against real files and has no tests. Everything below is taken
from how one other open-source library describes the format.

## Structure

Unverified: no header; 3-byte records from offset 0 to the end record
`00 00 f3`, or to end of file. The record has the same bit layout as a
[Tajima DST](../tajima_dst/README.md) record: the first two bytes hold
signed powers of three for each axis, the third a command.

| `byte2` | Meaning |
|---|---|
| `0x03` (masked with `0xC3`) | stitch |
| `0x83` | trim / jump |
| `0xC3` | stop (color change) |
| `0xF3` | end |

The library's decoder is a copy of its DST routine. Whether the ±81 bits in
`byte2` are used is not known; the spec decodes them as DST does.

## Versions

None known.

## Units and coordinates

Unverified: relative moves in 0.1 mm, at most ±121 per axis (the library's
writer rejects larger values), Y up as in DST.

## Open questions

- Is the file really headerless, and is there a trailer? The library's
  reader makes no seek, but it also calls its own decoder with swapped
  arguments, so it has not been run on real files.
- Whether T01 is exactly the DST record or a variant.
- Detection against other `.t01` files (Tajima uses the same extension in
  some tools, and a `.t01` may be a Barudan U01 with a different name).

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No
`.t01` file was found in EmbroidePy/samples or elsewhere with a license that
allows redistribution. Needs: a real `.t01` produced by Pfaff software, with
the right to redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- libembroidery `readT01`, `decode_t01_record` and `decode_tajima_ternary`
  (Zlib): record layout and command codes, read for understanding.
- pyembroidery: no T01 reader (checked).
- [Tajima DST](../tajima_dst/README.md) in this repository, for the shared
  bit layout.
- No files observed.
