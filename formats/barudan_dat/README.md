# Barudan DAT

| | |
|---|---|
| Spec | [`barudan_dat.ksy`](barudan_dat.ksy) |
| Extensions | `.dat` |
| Vendor | Barudan |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Shares the .dat extension with Sunstar DAT; detect by content.

**No redistributable sample exists for this format**, so the spec is
unverified against real files and has no tests. Everything below is taken
from how other open-source readers describe the format.

## Structure

Unverified: no header; the file is a sequence of the 3-byte records of
[`barudan_u01`](../barudan_u01/README.md) (control byte with sign bits and
command, Y magnitude, X magnitude), from offset 0 to the end record
(command 24, or end of file). The records are decoded by the shared type
[`formats/_common/barudan_record.ksy`](../_common/barudan_record.ksy).

### Telling Barudan from Sunstar DAT

| | Barudan DAT | Sunstar DAT |
|---|---|---|
| Header | none (Unverified) | 256 bytes, stitch count in 0x02 (according to other readers) |
| Record | `ctrl dy dx`, bit 7 of `ctrl` set | `x y ctrl`, x/y sign in bit 7 |
| First byte | bit 7 set | any |

A reader that has to choose can try Barudan first and fall back to Sunstar
when the first control byte has bit 7 clear. This is how pyembroidery does
it, and is the only detection rule known; it is Unverified here.

## Versions

None known.

## Units and coordinates

Unverified: same as U01: 0.1 mm, relative moves, Y up when read as the
shared record type.

## Open questions

- Is there a header (one reader skips 0x100 bytes, but that reader
  describes the Sunstar layout)? Unknown without a real file.
- Whether the records are exactly the U01 records and how the end is
  marked.
- Whether Barudan machines write `.dat` at all, or the extension came from
  a converter's naming.
- Detection: a Sunstar file with a first byte ≥ 0x80 could also look
  Barudan-like; no data to decide.

## Samples

None. See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml) (empty). No
Barudan `.dat` file was found in EmbroidePy/samples or elsewhere with a
license that allows redistribution. A file made by us from a different
format would only test our own assumptions, so none was added. Needs: a
real `.dat` produced by Barudan software or a machine, with the right to
redistribute.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- pyembroidery `DatReader.py` (MIT): the Barudan-then-Sunstar decision and
  record layout, read for understanding.
- libembroidery `barudan.c` (Zlib): its `.dat` reader, which has a 0x100
  header and a layout matching Sunstar DAT, not the records above; read
  only. This is the reason the header question is open.
- No files observed.
