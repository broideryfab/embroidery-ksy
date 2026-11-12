# Husqvarna Viking / Pfaff VIP

| | |
|---|---|
| Spec | [`husqvarna_vip.ksy`](husqvarna_vip.ksy) |
| Extensions | `.vip` |
| Vendor | Husqvarna Viking / Pfaff |
| Priority | Tier 2 — soon after launch |
| Status | 🟡 Partial |

Older Viking/Pfaff format. The same three compressed stitch blocks as HUS,
preceded by an obfuscated color table and a name.

## Structure

All multi-byte integers are **little-endian**.

| Offset | Size | Spec field | Meaning |
|---|---|---|---|
| 0x00 | 4 | `magic` | `5d fc 90 01` |
| 0x04 | u4 | `num_stitches` | Stitch records, including the final `end` |
| 0x08 | u4 | `num_unknown_color_values` | Colors |
| 0x0c | 4 × s2 | `extent_max_x`, `extent_max_y`, `extent_min_x`, `extent_min_y` | Design extents, 0.1 mm |
| 0x14 | 3 × u4 | `ofs_attributes`, `ofs_x`, `ofs_y` | Absolute offsets of the command ("attribute"), X and Y blocks |
| 0x20 | 8 | `unknown_0x20` | Zero in every sample |
| 0x28 | 2 | `unknown_0x28` | As in HUS |
| 0x2a | u4 | `unknown_color_section_length` | 8 × `num_unknown_color_values` + 46 in every sample |
| 0x2e | 4 × n | `encoded_colors` | Obfuscated RGB colors |
| … | u4 × n | `unknown_color_values` | 8 (Premier+) or 1 (others) |
| … | u4 | `len_name` | Name length in UTF-16 code units, with the NUL |
| … | 2 × len | `name` | UTF-16LE, NUL-terminated |

The command block starts at `ofs_attributes`, right after the name.

### Colors

Each color is 4 bytes: red, green, blue and a zero byte, obfuscated.
Reading other implementations' description, byte i of the table is stored as
`stored[i] = plain[i] xor key[i] xor stored[i-1]` (the previous stored byte,
0 for the first), with a fixed key of 400 bytes. The key is not reproduced in
this repository, so the spec exposes the colors as `encoded_colors`. Decoding
every color of the 15 sample files with that rule gave plausible colors with
a zero fourth byte. 400 bytes allow up to 100 colors.

### Stitch blocks and compression

Same as [HUS](../husqvarna_hus/README.md): three compressed blocks, each
decompressing to `num_stitches` bytes (commands, dx, dy). The VIP command
block has the same codes as HUS (`0x80` stitch, `0x81` jump, `0x84` color
change, `0x88` trim, `0x90` end). Decompressed VIP blocks are close to the
HUS blocks of the same design and producer (identical for Wings My Editor
except for an added `end` record; Wilcom files differ in the last records). The compression is not modeled; see the HUS
README for its description.

## Versions

No version field. All 15 VIP files in EmbroidePy/samples (Premier+, Wings My
Editor, Wilcom) share this layout; five are committed here.

## Units and coordinates

Same as HUS: 0.1 mm, stored Y is the reverse of screen Y, extents use the
stored direction (they equal the running-sum range of the decompressed dx and
dy in all 15 sample files).

## Open questions

What each producer writes:

| | Premier+ | Wings My Editor | Wilcom |
|---|---|---|---|
| `name` | `Settings:` | empty (NUL only) | file name stem (`random1-wilcom`) |
| `unknown_color_values` | 8 | 1 | 1 |
| `unknown_0x28` | `00 00` | as HUS | `00 00` |

- `unknown_color_section_length` is a function of `num_unknown_color_values` only in the
  samples, and is not the section's length.
- The obfuscation key is not included (see Colors). Unverified: whether files
  with more than 100 colors exist.
- `unknown_color_values` per color: 8 vs 1 may be a thread type or count.
- The `name` string may be a settings label, not the design name.
- The thread palette indexes of HUS have no counterpart here: the colors are
  stored as RGB.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. All samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)). Header values in `tests/` were checked
against an independent decompression of each file.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 15 VIP files in EmbroidePy/samples (hex dumps, offsets,
  decompressed blocks, decoded colors), five of them committed here.
- The HUS files of the same designs in the same corpus, to compare the
  decompressed stitch data.
- Embroidermodder/libembroidery (Zlib) `readVip` (header field order, color
  decoding rule, command codes). The decoding key table is not copied.
- EmbroidePy/pyembroidery (MIT) `HusReader`, `EmbCompress`: compression.
