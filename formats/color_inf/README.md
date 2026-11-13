# INF thread colors

| | |
|---|---|
| Spec | [`color_inf.ksy`](color_inf.ksy) |
| Extensions | `.inf` |
| Vendor | Various (Wilcom / Bernina Embroidery Wizard, Wings My Editor) |
| Priority | Thread color companion |
| Status | 🟡 Partial |

Thread color companion file with names. All numbers are big-endian.

## Structure

Header (16 bytes):

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0 | 4 | `version` | 1 in all samples |
| 4 | 4 | `header_size` | 8 in all samples |
| 8 | 4 | `data_size` | file size − 8 in all samples |
| 12 | 4 | `num_colors` | Number of records |

Then `num_colors` variable-length records (`color_record`):

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0 | 2 | `record_length` | Record length including this field |
| 2 | 2 | `index` | 1-based color number |
| 4 | 3 | `red`, `green`, `blue` | Color |
| 7 | 1 | `reserved_0x05` | 0 |
| 8 | 1 | `unknown_0x06` | Low byte of `index` in Embroidery Wizard files, 0 in My Editor files |
| 9 | n | `first_string` | Zero-terminated UTF-8: "BERNINA" (EW) or "Default" (ME) |
| | m | `second_string` | Zero-terminated UTF-8: color name (EW) or " " (ME) |

Record contents are parsed in a sub-stream of `record_length - 2` bytes.

## Versions

Only `version` 1 was seen. Two producers differ in the strings and in
`unknown_0x06`: Embroidery Wizard (`-ew-+.inf`) and My Editor (`-me.inf`).

## Units and coordinates

Not applicable (colors only).

## Open questions

- Meaning of `version`, `header_size` (8) and the byte at record offset 8.
- Role of the two strings: pyembroidery names them description and chart;
  the samples suggest brand/chart and color name. Unverified.
- Text encoding beyond ASCII (pyembroidery decodes UTF-8).
- Colors in the EW files differ slightly from the matching EDR files of the
  same design (for example 131,130,129 against 135,135,135), so the INF
  holds the producer's own thread table. Unverified.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. Samples come from [EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see [`samples/NOTICE`](samples/NOTICE)). Ten files: five from Embroidery Wizard and
five from My Editor, for the designs random1–3, scene and spiralbox. Expected
values in the tests were read from the raw bytes using the layout above; the
`scene-me.inf` colors agree with the My Editor PCS color table of the same
`random1-me.pcs` color table, and the record lengths and `data_size` agree with the file
sizes.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the sample files (hex dumps).
- EmbroidePy/pyembroidery `InfReader.py` (MIT): header fields, record
  length, RGB position, the two strings.
