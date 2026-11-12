# Barudan U01 / U00

| | |
|---|---|
| Spec | [`barudan_u01.ksy`](barudan_u01.ksy) |
| Extensions | `.u01`, `.u00` |
| Vendor | Barudan |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Commercial machines. Stitch data and needle selection; no thread colors.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0x00 | 128 | ASCII `0` (0x30) fill |
| 0x80 | 128 | Binary header (little-endian), zero padded |
| 0x100 | 3 × n | Records, the last one is the end record |

### Header (offset 0x80)

| Offset | Type | Spec field | Meaning |
|---|---|---|---|
| 0x80 | s2 | `extent_min_x` | Smallest X, 0.1 mm |
| 0x82 | s2 | `extent_min_y` | Smallest Y (Y up) |
| 0x84 | s2 | `extent_max_x` | Largest X |
| 0x86 | s2 | `extent_max_y` | Largest Y |
| 0x88 | u4 | `unknown_0x88` | Unknown, 0 in every sample |
| 0x8c | u4 | `record_count` | Record count (see Versions) |
| 0x90 | s2, s2 | `last_x`, `last_y` | Last position (see Open questions) |
| 0x94 | 108 | `reserved_0x94` | Zeros |

The extents equal the `+X/-X/+Y/-Y` fields of the DSB of the same design
(`spiralbox-wilcom`: −257, −231, 106, 131; `scene-me`: ±575, ±563).

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

No version field. Producers seen in EmbroidePy/samples:

| Producer | End record | Trim | Header `record_count` | Notes |
|---|---|---|---|---|
| Wilcom (`-wilcom.U01`) | `f8 00 00` | `e7 00 00` | records present, end included | needle `e9` first; sign bits always set on the stitch control bytes (`e0`, `c0`, `a0`) |
| My Editor (`-me.U01`) | `98 00 00` | `86 00 00` | records present | bit 5/6 follow the move; no leading needle change; fast/slow flags used |
| pyembroidery (no suffix) | `f8 00 00` | `e7` | records present + 1 (143 for 142 in `scene.u01`) | writes stop as `e8` |

The Wilcom U01 and DSB of the same design have a **byte-identical record
stream**; only the header differs.

## Units and coordinates

- Unit: 0.1 mm. Each record is a move relative to the previous position;
  the start is the design origin.
- X grows right, **Y grows up** in the file (bit 6 set = negative Y).
- One record moves at most 127 units per axis (the samples reach 127).

## Open questions

- 0x00..0x7f: always ASCII `0`. Purpose unknown.
- `unknown_0x88`: always 0.
- `last_x`/`last_y`: equal to DSB `AX`/`AY` for Wilcom and pyembroidery
  files; My Editor writes other values (345, 563 in `scene-me`).
- Meaning of the speed codes 2..5 and the difference between trim codes 6
  and 7. Code 3 and 5 (fast/slow jump) are not in any sample.
- Needles 9..15 and the exact role of `stop` (8) on real machines: not
  observed or not verified; no device testing was done.
- Bit 7 of `ctrl` is set in every sample; meaning unknown.
- Whether `.u00` differs from `.u01` (e.g. multi-part designs): no `.u00`
  sample.
- Non-zero move pair on codes 8..24: not seen.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)): Wilcom, My Editor and pyembroidery
variants. Purpose-built samples (square, two needles, long jump) are still
to be made; there is no `.u00` sample.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 21 U01 files in EmbroidePy/samples (hex dumps, record
  decoding), compared with the DSB files and the pyembroidery dumps
  (`spiralbox.txt`, `scene.txt`) of the same designs.
- pyembroidery `U01Reader.py` / `U01Writer.py` (MIT): command list and
  header layout, read for understanding; the spec was checked against the
  samples.
- libembroidery `barudan.c` (Zlib): read; covers `.dat` only.
