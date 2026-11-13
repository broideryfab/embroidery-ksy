# Toyota 10O

| | |
|---|---|
| Spec | [`toyota_10o.ksy`](toyota_10o.ksy) |
| Extensions | `.10o` |
| Vendor | Toyota |
| Priority | Tier 3 — long tail |
| Status | 🟡 Partial |

Headerless stitch file made of 3-byte records.

## Structure

No header. The file is a list of 3-byte records; all samples end with the
end record and have no trailing bytes.

| Offset | Size | Spec field | Content |
|---|---|---|---|
| 0 | 1 | `control` | Type and signs (below) |
| 1 | 1 | `y_raw` | Y magnitude |
| 2 | 1 | `x_raw` | X magnitude |

Control byte: bit 7 is set in every sample record (meaning Unverified);
bit 6 negates Y; bit 5 negates X; the low 5 bits are the type.

| Control | Meaning |
|---|---|
| `0x80`, `0xA0`, `0xC0`, `0xE0` | Stitch (low 5 bits `0x00`) |
| `0x90`, `0xB0`, `0xD0`, `0xF0` | Move (low 5 bits `0x10`) |
| `0x8A` | Start, offsets 0 (absent in Premier+ files) |
| `0x85` | Color change, offsets 0 |
| `0x81` | Trim (seen in Premier+ and My Editor files) |
| `0x82` | Stop (not in the samples; from pyembroidery) |
| `0x87` | End, offsets 0 |

A color change is followed by a move to the start of the next block.

## Versions

None known. Wilcom and My Editor files start with the `0x8A` record; Premier+
files start directly with a move and use `0x81` trim records.

## Units and coordinates

- Offsets are relative. Magnitude is one byte (0–255) per record.
- Unit (Unverified): 0.1 mm. In `spiralbox-wilcom.10O` the first four
  stitches are 100 units long, and the same design is a 100 × 100 square in
  the EmbroidePy dump `spiralbox.csv` (extents 100 × 100).
- `dy` in the spec is the stored value (bit 6 set → negative). pyembroidery's
  Y is the negative of it. Which direction is up in the file is Unverified.

## Open questions

- Meaning of bit 7 of the control byte; whether files exist without it.
- Exact meaning of `0x82` (stop) and `0x81` (trim), and their offsets when not 0.
- Whether other control values exist (pyembroidery stops at any other).
- Whether the unit is 0.1 mm, and the pixel size of long moves: moves longer
  than 255 units are split into several records (observed).
- The `.00O` files next to the samples (558 or 816 bytes, mostly zero with
  space-filled blocks) are not parsed by any reader we know. Not specified
  here; their relation to `.10O` is unknown.

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml). Only files we have the
right to redistribute. The samples come from
[EmbroidePy/samples](https://github.com/EmbroidePy/samples) (MIT, see
[`samples/NOTICE`](samples/NOTICE)); no purpose-built samples yet. Expected
values in the tests were read from the raw bytes using the layout above;
the record count of `random1-wilcom.10O` (9 color changes) agrees with the
EmbroidePy dumps of the same design.

## Sources consulted

_Format facts only — no code copied or translated._

- Observation of the sample files (hex dumps).
- EmbroidePy/samples `spiralbox.csv`, `random1.txt`: dumps of the same
  designs (extents, color changes).
- EmbroidePy/pyembroidery `A10oReader.py` (MIT): control byte bits and
  the special control values.
