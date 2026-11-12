# Husqvarna Viking SHV

| | |
|---|---|
| Spec | [`husqvarna_shv.ksy`](husqvarna_shv.ksy) |
| Extensions | `.shv` |
| Vendor | Husqvarna Viking |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Older Viking format with an uncompressed stitch stream and a small
thumbnail. All multi-byte integers are **big-endian**. There is no magic.

## Structure

| Size | Spec field | Meaning |
|---|---|---|
| 86 | `banner` | Text, space padded |
| u1 | `len_name` | |
| len | `name` | ASCII; Wilcom cuts it to 8 characters |
| u1, u1 | `thumbnail_width`, `thumbnail_height` | Pixels |
| 4 | `thumbnail_half_sizes` | Unverified: half of width and height, twice |
| ceil(h/2) × w | `thumbnail` | Two 4-bit pixels per byte (Unverified) |
| u1 | `num_colors` | |
| 6 | `unknown_after_num_colors` | `c4 28 00 30 00 00` (scene-me: `… 00 50 …`) |
| 4 × s2 | `extent_max_x`, `extent_max_y`, `extent_min_x`, `extent_min_y` | Wilcom: HUS extents, 0.1 mm |
| u4 | `unknown_total` | Wilcom: total stitch units |
| 14 × n | `colors` | Color records |
| … | `stitches` | Stitch records to the end of the file |

### Color record (14 bytes)

| Size | Spec field | Meaning |
|---|---|---|
| u4 | `num_records` | Two-byte units of stitch data for this color |
| u1 | `thread_index` | Palette index (palette not included) |
| u1 | `unknown_flag` | 0 (Wilcom) or 2 (Wings My Editor) |
| u4 | `unknown_0x02` | 0 (Wilcom); varying in Wings My Editor files |
| 2 × s2 | `start_x`, `start_y` | Unverified: start position, 0.1 mm, Y down |

`start` matches the EmbroidePy dump of `random1`: the second color of
`random1-wilcom.SHV` starts at (368, -181), `random1.txt` has (368.3, -180.8)
at that point.

### Stitch records

Same scheme as [VP3](../husqvarna_vp3/README.md):

| Bytes | Meaning | Spec |
|---|---|---|
| `dx dy` (s1, s1) | Short stitch, 0.1 mm, `dx` ≠ -128 | `is_stitch` |
| `80 01` s2 s2 | Long move with 16-bit deltas | `is_long_move` |
| `80 02` | Follows every long move | `command` = 2 |
| `80 03` | Unverified: trim | `command` = 3 |

The records have no color-change marker; the color of a record follows from
the colors' `num_records`, which count two-byte units (a long move is 3).
In Wilcom files they sum to the number of two-byte units of `stitches`;
Wings My Editor files do not match (2 more units in random1, 1 fewer in
spiralbox).

## Versions

No version field. All 10 SHV files in EmbroidePy/samples (Wings My Editor and
Wilcom; no Premier+) share this layout; four are committed here.

## Units and coordinates

0.1 mm, Y down (the first long move of `random1-wilcom.SHV` is (-159, 56) as
in its VP3, and the color `start` values match the screen-space dump).

## Open questions

- Wings My Editor writes other values in the four extent fields and in
  `unknown_total`, and a first move that Wilcom does not (the spiralbox: 76,
  -50, then the square). The origin may differ from Wilcom's.
- `unknown_after_num_colors`: constant apart from scene-me's `00 50`.
- Thumbnail pixel format (nibble order, palette) is not decoded; only its
  size is confirmed by the position of the following field.
- `unknown_0x02` and `unknown_flag` in color records.
- The thread palette (`thread_index`) is not included. Unverified.
- `80 03` trim and the use of `80 02` are as in VP3: unverified.
- Wilcom's `name` is cut to 8 characters (DOS style); Wings keeps 9.
- No Premier+ SHV sample exists.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Purpose-built samples are still to be
made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 10 SHV files in EmbroidePy/samples (hex dumps, record
  sizes, stitch sums), four of them committed here.
- EmbroidePy/samples `random1.txt`, `spiralbox.csv`: stitch directions and
  color start positions.
- The HUS and VP3 files of the same designs in the same corpus: extents and
  the long move.
- EmbroidePy/pyembroidery (MIT) `ShvReader`: field order and the
  stitch-count handling (the reader's rule of rewinding two bytes was not
  needed: the stitch stream starts right after the color records in all
  samples).
