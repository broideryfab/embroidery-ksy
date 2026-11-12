# Barudan DSB

| | |
|---|---|
| Spec | [`barudan_dsb.ksy`](barudan_dsb.ksy) |
| Extensions | `.dsb` |
| Vendor | Barudan |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

DST variant: Tajima DST's 512-byte text header with Barudan's 3-byte
records instead of DST's bit-packed ones.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0x000 | 512 | ASCII header, `KEY:value` fields ended by CR, then `1a` and padding |
| 0x200 | 3 × n | Records, the last one is the end record |
| after | 0..3 | Trailer: `1a` (Wilcom) or `1a 00 00` (My Editor) |

### Header

Same fields as [`tajima_dst`](../tajima_dst/README.md): `LA` label (16
chars), `ST` record count, `CO` colors, `+X -X +Y -Y` extents, `AX AY` last
position, `MX MY` previous end, `PD` previous file (`******`). Values are
kept as text. In the samples the header differs from DST only in that
files made by My Editor have `AX/AY` +0 and a `ST` that does not equal the
record count.

### Records

Three bytes each, shared with DSB and DAT through
[`formats/_common/barudan_record.ksy`](../_common/barudan_record.ksy):

| Byte | Content |
|---|---|
| 0 `ctrl` | bit 7: set in every sample record; bit 6: Y move is negative; bit 5: X move is negative; bits 4..0: command |
| 1 | Y magnitude, 0.1 mm |
| 2 | X magnitude, 0.1 mm |

Command codes (bits 4..0 of `ctrl`). "Seen" means present in the samples.

| Code | Spec | Meaning | Seen |
|---|---|---|---|
| 0 | `stitch` | Stitch with the move | yes |
| 1 | `jump` | Move without stitching | yes |
| 2 | `fast_stitch` | Stitch with a speed-up flag | yes (My Editor, `82`/`c2`) |
| 3 | `fast_jump` | Jump with a speed-up flag | no |
| 4 | `slow_stitch` | Stitch with a slow-down flag | yes (My Editor, `84`/`a4`) |
| 5 | `slow_jump` | Jump with a slow-down flag | no |
| 6 | `trim_top` | Top-thread trim | yes (My Editor, `86`) |
| 7 | `trim_bobbin` | Second trim kind | yes (Wilcom, pyembroidery, `e7`) |
| 8 | `stop` | Machine stop | yes (pyembroidery, `e8`) |
| 9..23 | `needle_1`..`needle_15` | Select needle 1..15 | needles 1..8 |
| 24 | `end` | End of design | yes (`f8` Wilcom/pyembroidery, `98` My Editor) |

Codes 2..5 are taken from other readers' description; their exact
meaning (speed change) is Unverified. Codes 6 and 7 are both trims in the
samples; the difference between them is unknown. `dx`/`dy` are the decoded
sign-and-magnitude pair; on codes 8..24 the pair is 00 00 in every sample.
The spec decodes flags `is_stitch`, `is_jump`, `is_trim`, `is_stop`,
`is_needle_change` (with `needle`) and `is_end`. Absolute coordinates and
trim inference are left to consuming applications.

Sign convention (bit 6 set = negative Y, bit 5 set = negative X) is confirmed
by `spiralbox-wilcom.U01`: its first moves are (0, −100), (100, −100),
(100, 0), (0, 0) in Y-up units, the same square as `melco_exp` for the same
design.

## Versions

No version field. Producers seen: Wilcom (`-wilcom.DSB`, label truncated to
8 chars, `ST` = records including the end record, `AX/AY` filled, end
`f8 00 00`, trailer `1a`) and My Editor (`-me.dsb`, `ST` larger than the
records present, `AX/AY` +0, end `98 00 00`, trailer `1a 00 00`). The
record stream of a Wilcom DSB is byte-identical to the U01 of the same
design ([`barudan_u01`](../barudan_u01/README.md)).

## Units and coordinates

Unit 0.1 mm, relative moves, Y up (bit 6 set = negative Y). Header extents
are relative to the start point. Same as U01.

## Open questions

- The meaning of command codes 2..7 (speed flags, trim kinds) and bit 7 of
  `ctrl` is Unverified; see the U01 README.
- A DSB reader in another project recognizes only `f8` as the end and
  `e7`/`e8`/`e9..f7` as trim/stop/needle (high bits fixed); the My Editor
  files use `98` and `86`. Which machines accept which is not verified.
- My Editor `ST`: it is larger than the record count (298 vs 178); what it
  counts is unknown.
- The `MX`, `MY`, `PD` fields: always 0 / `******`.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)); Wilcom and My Editor variants.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 10 DSB files in EmbroidePy/samples (hex dumps,
  header text, record decoding), compared with the U01 files of the same
  designs.
- pyembroidery `DsbReader.py` (MIT): read for understanding.
- The `tajima_dst` spec of this repository (header layout).
