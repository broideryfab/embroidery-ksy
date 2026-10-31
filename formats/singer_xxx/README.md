# Singer XXX

| | |
|---|---|
| Spec | [`singer_xxx.ksy`](singer_xxx.ksy) |
| Extensions | `.xxx` |
| Vendor | Singer |
| Priority | Tier 1 — launch |
| Status | 🟡 Partial |

Common home-machine format. Stitch data plus a small RGB palette.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 256 | Header: little-endian binary fields, mostly zero |
| 256 | variable | Stitch records (2, 4 or 5 bytes each), the last one is the end record |
| end + 4 | 96 | Color section: 2 zero bytes, 22 color slots (`00 RR GG BB`), 2 bytes |
| end + 100 | 0–n | Extra bytes; only Premier+ writes them (1777 bytes, mostly zero) |

### Header

All multi-byte values are little-endian. Every byte not listed is zero in
all 29 EmbroidePy samples.

| Offset | Type | Spec field | Meaning |
|---|---|---|---|
| 0x17 | u4 | `stitch_count` | Record count, without the end record (Wilcom, Premier+) or with it (My Editor) |
| 0x27 | u2 | `color_count` | Number of colors (color changes + 1); Premier+ writes 0 |
| 0x2d | u2 | `width` | Largest minus smallest X reached |
| 0x2f | u2 | `height` | Largest minus smallest Y reached |
| 0x31 | s2 | `end_x` | X of the last record relative to the start (Wilcom, pyembroidery; else 0) |
| 0x33 | s2 | `end_y` | Same for Y, Y up |
| 0x35 | u2 | `start_x` | Distance from the smallest X to the start point (Wilcom, pyembroidery; else 0) |
| 0x37 | u2 | `start_y` | Distance from the smallest Y to the start point (Wilcom, pyembroidery; else 0) |
| 0x7b | u2 + u1 + u1 | `unknown_0x7b`, `_0x7d`, `_0x7e` | Unverified: a date, 2019-07-13 in every Wilcom sample |
| 0xf2 | u2 | `unknown_0xf2` | 0x20 (Wilcom, pyembroidery), 0 (Premier+, My Editor) |
| 0xfc | u4 | `end_offset` | File offset of the end record (Premier+, My Editor); Wilcom writes 0 |

The header values were checked against the decoded records in all 29
samples: `width`, `height` and the Wilcom `end_*` / `start_*` values match
the extents and final position computed from the records. They also match
the Wilcom DST export of the same design (`random1-wilcom.DST`:
`+X 468`, `-X 479`, `+Y 500`, `-Y 469`, `AX -37`, `AY +152`).

### Stitch records

The first byte decides the record length:

| First byte | Length | Layout | Spec instances |
|---|---|---|---|
| `0x7f` | 4 | `7f` command, s1 dx, s1 dy | `is_command` |
| `0x7d` | 5 | `7d`, s2 dx, s2 dy | `is_long`, `is_stitch` |
| `0x7e` | 5 | `7e`, s2 dx, s2 dy | `is_long`, `is_jump` |
| other | 2 | s1 dx, s1 dy | `is_stitch` |

Because `0x7d`..`0x7f` are record types, a 2-byte stitch never has an X
move of +125..+127.

Commands (second byte of a `0x7f` record):

| Command | Meaning | Seen in |
|---|---|---|
| `0x01` | Jump by dx, dy | Wilcom, My Editor |
| `0x03` | Unverified: trim; args `00 00` | Premier+ (once, before the end) |
| `0x08` | Color change; args `00 00` | all producers |
| `0x09`..`0x17` | Color change to needle `command − 8`; args `00 00` | My Editor `-c` (0x09..0x11), Premier+ (0x09, 0x0b, 0x0e) |
| `0x7f` | End; args `02 14` (Wilcom) or `03 14` (Premier+, My Editor `-s`) | |
| `0x18` | End; args `00 00` | My Editor `-c` |

The spec decodes `dx`, `dy` and the command flags per record, plus `needle`
for numbered color changes. The end record's two argument bytes are not a
move, so its `dx` / `dy` are 0.

Producers use the record types differently for the same design:

- **Wilcom**: short stitches, `7f 01` short jumps, and long moves split into
  runs of `0x7e` records of about 125 units each, the last segment being a
  `0x7d` stitch.
- **Premier+**: no `7f 01` jumps; every move longer than a short stitch is
  one `0x7d` (stitch) or `0x7e` (jump) record.
- **My Editor**: only short stitches and `7f 01` jumps.

### Color section

96 bytes right after the end record: 2 zero bytes (`unknown_0x00`), 22
four-byte color slots `00 RR GG BB`, then 2 bytes (`unknown_0x5a`).

| | Wilcom | Premier+ | My Editor `-s` | My Editor `-c` |
|---|---|---|---|---|
| Slots 1..`color_count` | design colors | design colors (unverified) | colors | 0 |
| Other slots | 0 | `f20000` | more colors | 0 |
| Slot 22 | `ffffff` | `ffffff` | `fff8f0` | 0 |
| `unknown_0x5a` | `00 01` | `00 01` | `00 36` | `00 00` |

## Versions

No version field. The EmbroidePy corpus has two sub-variants from Wilcom and
My Editor, suffixed `-c` and `-s`:

- **Wilcom `-c` / `-s`**: byte-identical in all five designs. Only the `-c`
  file is in this repository.
- **My Editor `-c` / `-s`**: same length, same header and same records,
  except
  - color changes: `-c` writes `7f 08+n` (needle n, cycling 2..9, then 1),
    `-s` always writes `7f 08`;
  - end record: `-c` writes `7f 18 00 00`, `-s` writes `7f 7f 03 14`;
  - color section: `-c` leaves it all zero, `-s` fills the palette.

The plain `random1-me.xxx` (no suffix) has the `-c` layout. A plausible
reading is `-c` = needle-coded output for multi-needle machines and `-s` =
single-needle with a palette, but nothing in the files names the variants.

## Units and coordinates

- Unit: 0.1 mm for moves and header extents.
- Every record is a move relative to the previous position. The first
  position is the design origin (0, 0).
- X grows to the right, **Y grows up** (like DST). Screen coordinates (Y
  down) need `-dy`. Confirmed by `spiralbox-wilcom-c.XXX` (not in this
  repository): its first stitches go (0, 0) → (0, −100) → (100, −100) →
  (100, 0) → (0, 0), the same as the DST export of the design, which the
  EmbroidePy dump lists with Y flipped.

## Open questions

- `stitch_count`: My Editor counts one record more than Wilcom and Premier+.
  Which one the Singer machines expect is unknown.
- `-c` / `-s`: what the suffixes mean, and why Wilcom writes the same file
  for both.
- Premier+ mixes `7f 08` with needle-numbered changes (`7f 09`, `7f 0b`,
  `7f 0e`) in one file; why is unknown.
- `7f 03`: trim is a guess (one occurrence, before the end record).
- The end record's arguments (`02 14`, `03 14`, `00 00`), `unknown_0x5a`
  (`00 01`, `00 36`) and `unknown_0xf2` (`0x20`): meaning unknown.
- Header 0x7b..0x7e: date (2019-07-13) is a guess from the values.
- Palette: are the slots after `color_count` ever read by a machine? Does
  the order of slots follow the color changes? Premier+ writes `color_count`
  0, so the number of used slots must come from the color changes.
- Premier+ extra bytes after the color section (1777 bytes, a few non-zero
  values such as `0x0d`, `0x05`, `0x0a`): meaning unknown.
- Moves in a color change record: always `00 00` in the samples.
- pyembroidery's writer has a second header layout with the text `XXX`
  inside the header; no sample with it is in the corpus.
- Files without an end record: the spec stops at end of file and reads no
  color section.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)): one each from Wilcom and Premier+, and
the My Editor `-c` / `-s` pair of one design. Purpose-built samples
(square, two colors, long jump, maximum delta, empty design) are still to
be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 29 XXX files in EmbroidePy/samples (hex dumps of header,
  records and color section; records decoded and extents recomputed).
- `formats/tajima_dst/samples/random1-wilcom.DST` and the DST README:
  header extents and end offset of the same design, Y direction.
- EmbroidePy/samples `random1.txt` (pyembroidery dump): stitch positions of
  the design.
- EmbroidePy/pyembroidery `XxxReader.py`, `XxxWriter.py` (MIT), read for
  understanding of record types, command codes, header offsets and the
  color section.
