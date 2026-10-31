# Husqvarna Viking / Pfaff VP3

| | |
|---|---|
| Spec | [`husqvarna_vp3.ksy`](husqvarna_vp3.ksy) |
| Extensions | `.vp3` |
| Vendor | Husqvarna Viking / Pfaff |
| Priority | Tier 1 — launch |
| Status | 🟡 Partial |

Common home-machine format of VSM Group (Husqvarna Viking, Pfaff). Holds
thread colors with catalog number, name and brand, and stitch data per color.

## Structure

All multi-byte integers are **big-endian**. After a magic and a producer
string, the file is a tree of tagged blocks. Each block starts with a 3-byte
tag `00 nn 00` and a u4 length of the rest of the block.

```
"%vsm%" 00                       magic (6 bytes)
producer                         UTF-16 string
00 02 00  u4 len                 file block (to end of file)
├─ comment                       UTF-16 string
├─ extents, counts, unknowns
└─ 00 03 00  u4 len              design block (to end of file)
   ├─ center, bounds, width, height
   ├─ settings, 24 unknown bytes, producer (again)
   ├─ u2 number of color blocks
   └─ 00 05 00  u4 len           color block, one per color
      ├─ start position
      ├─ thread: colors (RGB), weight, catalog number, description, brand
      ├─ end offset
      ├─ 00 01 00  u4 len        stitch block: 0a f6 00, then stitch records
      └─ 00                      one byte after the stitch block
```

### Strings

Two kinds, both with a u2 byte-length prefix:

- **UTF-16BE** (`utf16_string`): producer, comment, settings. The length
  counts bytes, so it is twice the number of characters.
- **8-bit** (`byte_string`): thread catalog number, description and brand.
  Every sample is ASCII; the spec reads ISO-8859-1.

### File block

Offsets after the `comment` string:

| Size | Spec field | Meaning |
|---|---|---|
| 4 × s4 | `extent_right`, `extent_top`, `extent_left`, `extent_bottom` | Design extents, 0.001 mm, Y up |
| u4 | `unknown_stitch_count` | Looks like a count (see Open questions) |
| u2 | `num_colors` | Equals the number of color blocks in every sample |
| 3 | `unknown_after_num_colors` | `0c 00 01` in every sample |
| … | `design` | Design block |

### Design block

| Size | Spec field | Meaning |
|---|---|---|
| 2 × s4 | `center_x`, `center_y` | Design center, 0.001 mm, Y up |
| 3 | `unknown_0x08` | `00 00 00` in every sample |
| 6 × s4 | `bounds_left`, `bounds_right`, `bounds_bottom`, `bounds_top`, `width`, `height` | Bounds relative to the center, 0.001 mm |
| string | `settings` | UTF-16 |
| 24 | `unknown_after_settings` | Identical in all 19 corpus files (`64 64 00 00 10 00 …00… 10 00 78 78 50 50 01 00`) |
| string | `producer` | Same text as at the start of the file |
| u2 | `num_color_blocks` | Number of color blocks |

Premier+ and Wilcom write `center` = middle of the file block extents and
symmetric bounds. My Editor writes center 0 and the bounds equal to the
extents.

### Color block

| Size | Spec field | Meaning |
|---|---|---|
| 2 × s4 | `start_x`, `start_y` | Start position, 0.001 mm, Y up, relative to the center |
| u1 | `thread.num_colors` | Unverified: colors in the thread; 1 in every sample |
| u1 | `thread.unknown_0x01` | 0 in every sample |
| 6 × n | `thread.colors` | `red`, `green`, `blue`, then `00 00 00` |
| u1 | `thread.unknown_type` | 5 in every sample |
| u1 | `thread.weight` | Unverified: thread weight; 40 in every sample |
| string × 3 | `thread.catalog_number`, `thread.description`, `thread.brand` | 8-bit strings |
| 2 × s4 | `end_offset_x`, `end_offset_y` | Last position relative to the start, 0.001 mm, Y up |
| … | `stitches` | Stitch block `00 01 00` + u4 length; body is `0a f6 00` then records |
| u1 | `unknown_last` | 0 in all 179 color blocks of the corpus |

`end_offset` equals the next block's start minus this block's start, and
equals the sum of the stitch moves (×100, Y negated), in every block written
by Premier+, My Editor and Wilcom. Files written by pyembroidery (not in this
repository) differ by small amounts.

### Stitch records

| Bytes | Meaning | Spec |
|---|---|---|
| `dx dy` (s1, s1) | Short stitch, 0.1 mm, `dx` ≠ −128 | `is_stitch` |
| `80 01` s2 s2 | Long move with 16-bit deltas | `is_long_move`, `long_dx`, `long_dy` |
| `80 02` | Follows every long move | `command` = 2 (`long_move_end`) |
| `80 03` | Unverified: trim | `is_trim` |

`dx` and `dy` instances give the move of every record (0 for commands).
Absolute coordinates and how long moves are sewn (stitch or jump) are left
to consuming applications.

## Versions

No version field. All 19 VP3 files in EmbroidePy/samples (Premier+, My
Editor, Wilcom, pyembroidery) have the same block layout and the same
constant bytes. **VP4** (`.vp4`, 5 Premier+ files in the corpus) is a newer
format and is out of scope for this spec.

## Units and coordinates

- Stitch moves: 0.1 mm. Extents, center, bounds, start and end positions:
  0.001 mm.
- **Header positions are Y up; stitch moves are Y down.** `end_offset_y`
  is minus the sum of the stitch `dy` values ×100 in every block.
- Confirmed against the EmbroidePy dumps (screen coordinates, Y down):
  `spiralbox.csv` starts (0, 0) → (0, 100) → (100, 100) → (100, 0) → (0, 0),
  and the first block of `spiralbox-premier.vp3` holds the moves (0, 100),
  (100, 0), (0, −100), (−100, 0). `random1.txt` starts (−158.6, 55.8),
  (75.5, 259.8), (368.3, −180.8); `random1-wilcom.VP3` holds the long moves
  (−159, 56), (234, 204), (293, −441).
- `center + start` of the first block is the position before the first
  record (Y up).
  In `random2-premier.vp3`: (−1950 − 39050, 3150 + 12150) µm =
  (−41.0, 15.3) mm, and `random2.txt` starts at (−410.1, −153.3) in 0.1 mm,
  Y down.

## Open questions

What each producer writes, observed in the samples:

| | Premier+ | My Editor | Wilcom |
|---|---|---|---|
| Producer | `Produced by VSM Group AB` | `Produced by WingsXP software` | `Produced by     Software Ltd` |
| `comment`, `settings` | `Settings:` | empty | empty |
| Center | middle of the extents | 0 | middle of the extents |
| Thread strings | description `#rrggbb` | description = color name | catalog number + brand `PES` |
| `unknown_stitch_count` | 41 (random2), 112 (spiralbox) | 70 (random1) | 156 (random1) |

- `unknown_stitch_count`: no producer-independent meaning found. My Editor's
  70 = 60 records other than `80 02` + 10; Premier+'s 41 for random2 = 30
  moves + 10 trims + 1; Wilcom writes far more.
- `random2-premier.vp3` has one color block (`#ecaa76`) for a 10-color
  source design, with trims between the color groups. Unknown whether
  Premier+ merged the colors or the export settings did.
- `80 02` after every long move: an end marker, or a separate command?
  Never seen without a preceding `80 01`.
- `80 03`: trim is assumed (Premier+ writes it where the source changes
  color). Other command codes are unknown; the spec reads any `80 nn` as a
  2-byte command, except `80 01`.
- Thread fields: `num_colors` > 1 (multi-color threads), `unknown_0x01`,
  the 3 bytes after each RGB, `unknown_type` (5) and `weight` (40) never
  vary in the corpus.
- `unknown_after_num_colors` (`0c 00 01`), `unknown_0x08`, the 24 bytes
  after `settings`, the `0a f6 00` stitch block prefix and the byte after
  each stitch block never vary in the corpus.
- 8-bit string encoding: assumed ISO-8859-1; no sample has non-ASCII text.
- Can the file block be followed by other data, or a design hold several
  design blocks? Not seen.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Purpose-built samples (`square-10mm`,
`two-colors` with named threads, a Premier+ export with catalog numbers) are
still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 19 VP3 files in EmbroidePy/samples (hex dumps, block
  lengths, string positions, stitch sums), four of them committed here.
- EmbroidePy/samples `random1.txt`, `random2.txt`, `random2.csv`,
  `spiralbox.csv` (pyembroidery dumps of the source designs): first stitch
  positions, Y direction, thread colors.
- `formats/tajima_dst` in this repository: the DST versions of the same
  designs (extents in 0.1 mm), to confirm the 0.001 mm header unit.
- General knowledge of pyembroidery's VP3 reader (EmbroidePy/pyembroidery,
  MIT): string kinds, thread field order and the `80 01` escape. Every
  field in the spec was checked against the sample bytes.
