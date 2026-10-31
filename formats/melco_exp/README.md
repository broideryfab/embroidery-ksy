# Melco EXP

| | |
|---|---|
| Spec | [`melco_exp.ksy`](melco_exp.ksy) |
| Extensions | `.exp` |
| Vendor | Melco / Bernina |
| Priority | Tier 1 — launch |
| Status | 🟡 Partial |

Common commercial format, also used by Bernina machines. Stitch data only;
no header and no thread colors.

## Structure

| Offset | Size | Content |
|---|---|---|
| 0 | to end of file | Records: 2-byte stitch records and 4-byte command records |

There is no header, no record count and no end record. The stream ends at
end of file; the last record in every sample is an ordinary stitch or jump.

### Records

| Bytes | Kind | Spec fields |
|---|---|---|
| `dx dy` (first byte ≠ `0x80`) | Stitch: signed relative move | `byte0`, `byte1` → `dx`, `dy` |
| `80 cc px py` | Command `cc` with parameter pair `px py` (signed) | `byte0`, `byte1`, `param_x`, `param_y` |

A stitch moves at most ±127 units per axis. `0x80` (−128) is never a delta:
it is the escape that starts a command record.

Commands observed in the samples:

| Bytes | Spec | Meaning | Parameter pair |
|---|---|---|---|
| `80 01 00 00` | `color_change` | Color change / stop | `00 00` in every sample |
| `80 02 px py` | `move` | Jump (move without stitching) | X, Y move |
| `80 04 px py` | `jump` | Jump (move without stitching) | X, Y move |
| `80 80 07 00` | `trim` | Thread trim | always `07 00`; not a move |

The spec decodes per record `dx`, `dy` and the flags `is_stitch`,
`is_command`, `is_jump` (`02` or `04`), `is_color_change` and `is_trim`.
For a trim, `dx` and `dy` are 0: in `scene-wilcom.EXP`, counting the `07 00`
of its two trims as moves would make the design 14 units wider than the
same design from other producers and than the EmbroidePy dump; skipping it
matches both. Absolute coordinates and trim inference are left to consuming
applications.

## Versions

No version field. Producers differ only in which commands they write
(observed in all 35 EXP files of EmbroidePy/samples):

| Producer (file suffix) | Jumps | After a jump | Trim | Notes |
|---|---|---|---|---|
| Wilcom (`-wilcom.EXP`) | `80 04` | two `00 00` stitches | `80 80 07 00` | |
| Wilcom Bernina (`-wilcom-bernina.EXP`) | same | same | same | **byte-identical** to `-wilcom.EXP` for all 5 designs |
| Premier+ (`-premier.exp`) | `80 04` | — | — | long moves split into many jumps |
| My Editor (`-me.exp`) | `80 02`; last jump before a color change is `80 04` | — | `80 80 07 00` | |
| "ew" (`-ew.exp`) | `80 02` only | — | — | starts with jumps to the top-left corner |
| "ew" with `+` (`-ew-+.exp`) | same | same | same | **byte-identical** to `-ew.exp`; ships with `.inf` and `.bmp` |
| pyembroidery (no suffix) | `80 04` | — | `80 80 07 00` | writes `80 80 07 00 80 01 00 00` for a stop |

So the "Bernina flavour" is not a different stream encoding: the stitch
data is the same, and the Bernina-specific part is the companion `.inf`
file with thread colors (`BERNINA` brand names visible in the samples'
`.inf` files). That file is a separate format (`color_inf`).

## Units and coordinates

- Unit: 0.1 mm.
- Every record is a move relative to the previous position. The first
  position is the design origin (0, 0).
- X grows to the right, **Y grows up**. Screen coordinates (Y down) need
  `-dy`. Confirmed by `spiralbox-wilcom-bernina.EXP`: its first records move
  (0, 0) → (0, −100) → (100, −100) → (100, 0) → (0, 0) in EXP units, while
  the EmbroidePy dump of the same design lists (0, 0) → (0, 100) →
  (100, 100) → (100, 0) → (0, 0) in screen coordinates. The stitch extents
  of the Wilcom files match the EmbroidePy `.csv` extents with Y flipped
  (e.g. `random1`: X −479…468, Y −469…500).

## Open questions

- `80 02` vs `80 04`: both behave as jumps in the samples. Is one a
  "move" and the other a "jump with trim", or are they equivalent? My Editor
  uses `04` only for the last jump before a color change.
- Color change parameter pair: always `00 00`. Is it ever a move? The spec
  reports it as `dx`/`dy` (0 in the samples).
- Trim parameter `07 00`: meaning of `07` unknown; always the same.
- Other command codes (stop vs color change, end, sequins): none observed.
  An unknown code still parses, with the parameter pair as `dx`/`dy`.
- A stitch delta of −128 cannot be written; no sample needs one.
- End of data: no end record exists in any sample. A truncated last record
  (odd length, or `80` within the last 3 bytes) makes the parser fail.
- The producer behind the `-ew` suffix is not identified.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The current samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)): one per producer variant that differs
in its bytes (Wilcom/Bernina, My Editor, ew). Purpose-built samples (square,
two colors, long jump, trim) are still to be made.

## Sources consulted

_Format facts only — no code copied or translated. List every reference
used (documentation, observed files, other projects read for understanding)._

- Observation of all 35 EXP files in EmbroidePy/samples (hex dumps,
  record-by-record decoding, byte comparison between variants).
- EmbroidePy/samples `spiralbox.csv`, `spiralbox.txt`, `random1.csv`,
  `random2.csv`, `random3.csv`, `scene.csv` (pyembroidery dumps of the same
  designs): stitch positions, extents, Y direction, color break counts.
- EmbroidePy/samples `*-ew-+.inf` (observed only: Bernina thread names).
