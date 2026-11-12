# Tajima TBF

| | |
|---|---|
| Spec | [`tajima_tbf.ksy`](tajima_tbf.ksy) |
| Extensions | `.tbf` |
| Vendor | Tajima |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Newer Tajima format; includes thread colors.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0x000 | 8 | Version text, space-padded (`3.00`, `03.00`) |
| 0x008 | 4 | Unknown (`unknown_0x08`) |
| 0x00c | 116 | Spaces |
| 0x080 | 0x18b | Text fields `LA:` `ST:` `CO:` `+X:` `-X:` `+Y:` `-Y:` `AX:` `AY:` `TP:` `JC:` `DO:`, each value followed by CR (`0x0d`) |
| 0x20b | 0x3f5 | `DA:` thread table, then spaces (with `0d 1a` inside), up to 0x600 |
| 0x600 | 3 × n | Records; the last one is the end record `00 00 8f` |
| after | 0–1 | Trailer: one `1a` in every sample |

### Text fields

Fixed layout in all ten samples. Numeric values are right-aligned decimal
text; the sign position differs by producer (`-   37`, `    +0`), so the spec
keeps them as text.

| Key | Value width | Spec field | Meaning |
|---|---|---|---|
| `LA:` | 16 | `label` | Design name, space-padded |
| `ST:` | 7 | `stitch_count` | Number of records including the end record |
| `CO:` | 3 | `color_change_count` | Colors (see Open questions) |
| `+X:` `-X:` `+Y:` `-Y:` | 5 | `extent_*` | Extents relative to the start, in 0.1 mm |
| `AX:` `AY:` | 6 | `end_offset_*` | Last position relative to the start; Wilcom fills them, My Editor writes 0 |
| `TP:` | 32 | `type_text` | Unknown, `EG/` in all samples |
| `JC:` | 1 | `jc` | Unknown, `3` in all samples |
| `DO:` | 256 | `needle_order` | Needle numbers for the needle change records, zero-padded |

The extents match the extents computed from the records in all ten samples
(checked while writing the tests), and `ST` equals the record count in all
ten.

### Thread table

`DA:` is followed by 5-byte entries `45 rr gg bb 20` (`0x45` = "E"); the list
ends at the first byte that is not `0x45`. Wilcom writes only the used colors
(10, 3, 16 entries); My Editor writes 99 entries. The spec exposes the list
as `thread_area.threads`; its last element is the terminator, not a thread.

### Records

Three bytes: `dx` (signed byte), `dy` (signed byte), command.

| Command | Enum | Meaning |
|---|---|---|
| `0x80` | `stitch` | Stitch with the move |
| `0x81` | `needle_change` | Next needle from `DO:`, move 0, 0 |
| `0x86` | `trim` | Trim, move 0, 0 |
| `0x90` | `jump` | Move without stitching |
| `0x8f` | `end` | End; `00 00 8f` |
| `0x40` | `stop` | Unverified: not in the samples |

Samples contain only `0x80`, `0x81`, `0x86`, `0x90` and `0x8f`. Absolute
positions and trim handling are left to consuming applications.

## Versions

The version text is `3.00` (Wilcom) or `03.00` (Wings My Editor). The two
producers also differ in `AX`/`AY`, thread table length, and the 4 bytes at
0x08. No other versions have been seen; layout differences between versions
are unknown.

## Units and coordinates

- Unit: 0.1 mm (header extents equal the DST extents of the same random1
  design from My Editor).
- Records are relative moves; the start is the origin (0, 0).
- X grows to the right, **Y grows up**, as in DST. In `spiralbox-wilcom` the
  first stitch after the initial jump is `dy = −100` (`0x9c`), the same
  direction as the DST sample of that design.
- A move is at most ±127 per axis (signed byte); longer distances need several
  records.

## Open questions

- `unknown_0x08`: in the Wilcom samples the little-endian value is about
  0x5d2a5a8f…0x5d2a6356, which resembles a July 2019 Unix timestamp; My
  Editor always writes 0x0018eb70. Unverified.
- `CO`: Wilcom matches the number of `0x81` records (10, 3, 16); My Editor
  writes one more (10 for 9 changes, 3 for 2, 16 for 15). `DO:` follows the
  same pattern. Consumers should count the records.
- `TP`, `JC`: purpose unknown.
- Why the first `DO:` entry is repeated in Wilcom files (`01 01 02 …`) and
  whether the 0x81 at the start of the data is a color change or a needle
  select.
- `0x40` (stop) and the meaning of a jump with a zero move after a trim.
- The `0d 1a` pair inside the thread area, at 0x376 (Wilcom) or 0x501 (My
  Editor): meaning and position rule unknown.
- Longer names, non-ASCII names and designs with more than 256 needle changes
  are untested. The thread table is assumed to end at 0x600 (the fixed header
  size).
- Not yet checked against real machines or software beyond the two producers.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The ten samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)): five designs, each made with Wilcom and
with Wings My Editor. Purpose-built samples (square, long jump, maximum delta)
are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of the ten sample files (hex dumps; extents and record counts
  checked against the header).
- EmbroidePy/pyembroidery `TbfReader.py` and `TbfWriter.py` (MIT), read for
  understanding of the header offsets, the thread table and the command
  bytes.
