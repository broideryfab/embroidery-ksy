# Brother PES

| | |
|---|---|
| Spec | [`brother_pes.ksy`](brother_pes.ksy) |
| Extensions | `.pes` |
| Vendor | Brother / Baby Lock |
| Priority | Tier 1 — launch |
| Status | 🟡 Partial |

Most common home-machine format. Many versions; contains an embedded PEC block.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 4 | Magic `#PES` |
| 4 | 4 | Version, 4 ASCII digits (`0001` … `0100`) |
| 8 | 4 | `pec_offset`: absolute offset of the PEC block (u4 LE) |
| 12 | variable | Version-dependent header (parsed for 0001–0060) |
| — | variable | Design objects: `CEmbOne`, `CSewSeg`, … (start parsed, rest raw) |
| `pec_offset` | to end | PEC block, parsed with [`brother_pec`](../brother_pec/)'s `pec_block` |

All integers are little-endian. The PES section is what PE-Design edits;
machines read the PEC block, which holds the full stitch list. This spec
leaves the PES design objects (which also carry stitch coordinates) as raw
`body` bytes.

### Header by version

Offsets are absolute. Fields named `unknown_*` and the `settings` values
have no confirmed meaning yet.

**0001**

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 12 | 2 | `hoop_size_code` | Unverified: 0 = 100 × 100 mm, 1 = 130 × 180 mm |
| 14 | 2 | `unknown_0x0e` | 1 |

**0020**

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 12 | 2 | `hoop_width` | Hoop width, mm |
| 14 | 2 | `hoop_height` | Hoop height, mm |
| 16 | 2 | `unknown_0x10` | 0 |
| 18 | 14 | `settings` | Seven u2 values (below) |
| 32 | 2 | `unknown_0x20` | 0 |

**0030**: the two fields of 0001, then the 0020 layout (hoop size at 16).

**0040**

| Size | Spec field | Content |
|---|---|---|
| 2 | `design_info.unknown_0x0c` | 1 |
| 2 | `design_info.subversion` | ASCII `01` (Wilcom v6: `02`) |
| 1 + n | `design_info.design_name` | Length-prefixed string; only Wilcom fills it |
| 4 × (1 + n) | `design_info.unknown_strings` | Four length-prefixed strings, empty in every sample |
| 2 | `unknown_flag` | 1 Brother (and Premier+ v6), 0 Wilcom, Premier+ v4, My Editor |
| 2 + 2 | `hoop_width`, `hoop_height` | mm |
| 2 | `unknown_after_hoop` | 0 |
| 14 | `settings` | Seven u2 values |
| 6 | `reserved` | Zero |

**0050**: as 0040 up to `settings`, then 3 zero bytes, `transform` (six
f4, identity `1 0 0 1 0 0` in every sample), 6 zero bytes, `num_threads`
(u2) and the thread table.

**0060**: as 0050, plus `unknown_after_flag` (u2, 0) after `unknown_flag`
and `unknown_sizes` (five u2: 200, 200, 100, 100, 100) after
`unknown_after_hoop`.

**Settings** (seven u2, versions 0020–0060), per producer:

| Producer | Values |
|---|---|
| Brother PE-Design | 7, 19, 1, 1, 1, 5, 1 |
| Premier+ | 7, 19, 0, 1, 0, 25, 0 |
| Wilcom | 7, 19, 1, 1, 0, 100, 1 |
| My Editor | 7, 19, 0, 0, 0, 100, 1 |

### Thread table (0050, 0060)

Each entry:

| Size | Spec field | Content |
|---|---|---|
| 1 + n | `catalog_number` | Text, e.g. `817` (Brother), `039` (Wilcom) |
| 3 | `red`, `green`, `blue` | Thread color |
| 1 | `unknown_0x03` | 0 |
| 4 | `thread_type` | 10; 2 for one black entry in Brother's spiralbox |
| 1 + n | `name` | Brother: the PEC palette index as text (`39`); My Editor: color name (`Gray`); Wilcom: empty |
| 1 + n | `brand` | `EMBROIDERY` (Brother, Premier+, My Editor), `PES` (Wilcom) |
| 1 + n | `unknown_string` | Empty |

Wilcom, Premier+ and My Editor write one entry per color block. Brother
writes each thread once: `random1` has 10 color blocks but 9 threads, and
its PEC palette uses index 10 twice.

### Design objects

Right after the header, in every parsed version:

| Size | Spec field | Content |
|---|---|---|
| 2 | `object_list.unknown_count` | Brother v1–v5: number of color blocks; Brother v6 and all others: 1 |
| 2 | `object_list.new_class_tag` | `ff ff` |
| 2 | `object_list.schema` | 0 |
| 2 + n | `object_list.class_name` | u2 length + `CEmbOne` |

The tags look like MFC `CArchive` serialization: later objects of a known
class start with `0x8000 | class index` (e.g. `03 80`), and a second class
`CSewSeg` follows. The objects contain a bounding box, the same six-float
transform, and stitch coordinates. The spec keeps everything after the
first class name, up to `pec_offset`, as `body`.

### After the PEC block

PES v4 (128 bytes), v5/v6 and Premier+ files carry more data after the PEC
thumbnails, e.g. a second color count and palette list in v5/v6. It ends
up in `pec_block.thumbnails.trailer` and is not specified.

## Versions

Detected by the 4-digit version at offset 4. Samples in EmbroidePy/samples
by version and producer:

| Version | Producers in the corpus | Spec |
|---|---|---|
| `0001` | Brother v1, Wilcom v1, ew, pyembroidery | Header parsed |
| `0020` | Brother v2, Premier+ v2 | Header parsed |
| `0030` | Brother v3 | Header parsed |
| `0040` | Brother v4, Wilcom v4, Premier+ v4 | Header parsed |
| `0050` | Brother v5, Wilcom v5 | Header and thread table parsed |
| `0060` | Brother v6, Wilcom v6, Premier+ v6, My Editor | Header and thread table parsed |
| `0090` | Premier+ v9 | Raw header, PEC block parsed |
| `0100` | Premier+ v10 | Raw header, PEC block parsed |

The 0040–0060 layouts were checked with a byte-level script against every
sample of those versions in EmbroidePy/samples (all producers), each ending
exactly at the `ff ff` class tag; 0001–0030 likewise. Only the Brother
`random1` files and `random1-premier-v10.pes` are in this repository.

Versions 0090/0100 (Premier+) start like 0060 (`01 00 30 31`, empty
strings) but the fields after the hoop differ (`07 00 c8 00 c8 00 be 00
…`); they are not parsed.

## Units and coordinates

- Hoop size in mm (header). Stitch units and directions are those of the
  PEC block: 0.1 mm, X right, **Y down**.
- The PEC block's first move is relative to its start point; in the
  Brother files the first record is already a stitch (random1: dx 234,
  dy 204, which matches the step between the first two points of the
  EmbroidePy dump, −158.6, 55.8 → 75.5, 259.8).

## Open questions

- `hoop_size_code` (0001/0030): the 0/1 → 100 × 100 / 130 × 180 mapping
  rests on Wilcom files only.
- `settings`, `unknown_flag`, `unknown_sizes`, `subversion`: meanings.
- The four empty strings after the design name: no sample fills them
  (category, author, keywords, comments are candidates). A purpose-made
  `metadata.pes` is needed, also to settle the string encoding.
- `thread_type` 10 vs 2, and `unknown_string` in thread entries.
- `object_list.unknown_count`: why Brother v6 writes 1.
- The design objects (`CEmbOne`, `CSewSeg`, …) and how their stitch data
  relates to the PEC block: not specified.
- Some Premier+ PES files put a single color and no color changes in the
  PEC block (`random1-premier-v2`, `-v4`, `-v10`; the other Premier+ files
  have them); machines reading only the PEC block would sew one color.
- Data after the PEC thumbnails in v4–v6 and Premier+ files.
- Versions 0090 and 0100: header layout.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)): one Brother PE-Design file per version
0001–0060 of the same design, and the Premier+ v10 file for an unparsed
version. Purpose-built samples (square, metadata with non-ASCII text,
custom thread colors) are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 73 `.pes` files in EmbroidePy/samples (hex dumps,
  plus a small decoding script of our own that walked each version's header
  and the thread tables, and decoded the PEC blocks).
- EmbroidePy/samples `random1.txt` (pyembroidery dump of the same design):
  first stitch positions.
- The [`brother_pec`](../brother_pec/) spec and its samples.
- BroideryFab internal plan `brother_pes.md` (version list, working
  hypotheses, checked against the bytes).
