# Happy TAP

| | |
|---|---|
| Spec | [`happy_tap.ksy`](happy_tap.ksy) |
| Extensions | `.tap` |
| Vendor | Happy |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Happy commercial machines. Stitch data only (no thread colors); the records
use the same bit encoding as [Tajima DST](../tajima_dst/README.md), without
the 512-byte header.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | 0 or 6 | Prefix of six `0x00` bytes (Wilcom samples; absent in My Editor samples) |
| 0 or 6 | 3 × n | Stitch records; the last is the end record `00 00 f3` |
| after | 0 or 3 | Trailer: `00 00 00` (Wilcom samples) |

The prefix is detected by the first six bytes all being zero; a real first
record can never look like that, because its byte 2 always has its two lowest
bits set.

### Stitch records

Each record is 3 bytes with the DST layout: every axis bit adds or subtracts
a power of three (1, 3, 9, 27, 81), so one record moves at most ±121 units
per axis. The bit table, the command bits (`is_stitch`, `is_jump`,
`is_color_change`, `is_sequin`, `is_end`) and the decoded `dx`/`dy` are the
same as in the [Tajima DST README](../tajima_dst/README.md#stitch-records).

Evidence that the layout is DST's: in all four samples the records, once the
prefix is skipped, are byte-for-byte the records of the DST file of the same
design from the same producer (`random1-me.dst`, `random1-wilcom.DST`,
`spiralbox-wilcom.DST`, `scene-wilcom.DST` in EmbroidePy/samples), and
`random1-me.tap` has the same 303 records.

## Versions

No version field known. Two producer variants are seen: Wilcom (prefix and
trailer) and Wings My Editor (neither).

## Units and coordinates

- Unit: 0.1 mm, relative moves, as in DST. The first position is the design
  origin.
- Y direction: the records equal the DST records, so Y grows up. Unverified
  for Happy machines themselves.

## Open questions

- Purpose of the six-byte zero prefix and the three-byte zero trailer in
  Wilcom files. Unverified: whether Happy machines require them.
- Whether other producers write a different prefix or a real header.
  Unverified: the spec only recognizes six zero bytes.
- Sequin mode (`0x43`), "stop" versus color change, and any Happy-specific
  command codes: not in the samples.
- Whether extended coordinates (larger than ±121 per record) or other
  record layouts exist in newer Happy files.
- No Happy documentation was available; everything here is inferred from
  samples and other readers. Not checked on a machine.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Tests assert record counts, the
prefix and trailer, and the first and end records.

## Sources consulted

- Observation of the four sample files (hex dumps) and comparison of their
  records with the matching DST samples from the same repository.
- EmbroidePy/pyembroidery `TapReader.py` and `DstReader.py` (MIT): TAP is
  read with the DST stitch reader and no header.
- Embroidermodder/libembroidery `data.c` (Zlib): format table lists `.tap`
  as "Happy Embroidery Format", stitch only.
