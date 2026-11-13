meta:
  id: sunstar_sst
  title: Sunstar SST embroidery format
  file-extension: sst
  license: MIT
doc: |
  Sunstar SST: a 0xa0-byte header (all zero in the samples) followed by
  3-byte stitch records up to the end of the file. The last record has the
  `end` flag. Distances are in 0.1 mm units. The layout comes from five
  Wings My Editor files; the header is not understood beyond being zero.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/sunstar_sst
seq:
  - id: reserved_0x00
    size: 0xa0
    doc: Header. Zero in every sample.
  - id: records
    type: record
    repeat: eos
    doc: Records from offset 0xa0 to the end of the file.
types:
  record:
    doc: One stitch record.
    seq:
      - id: dx_abs
        type: u1
        doc: Absolute x move in 0.1 mm units; the sign is in `flags`.
      - id: dy_abs
        type: u1
        doc: Absolute y move in 0.1 mm units; the sign is in `flags`.
      - id: flags
        type: u1
        doc: |
          Bit 0 (`0x01`) color change, bit 1 (`0x02`) jump, bit 2 (`0x04`)
          end, bit 4 (`0x10`) y is positive, bit 6 (`0x40`) x is negative.
          Bits 3, 5 and 7 are 0 in every sample.
    instances:
      is_color_change:
        value: (flags & 0x01) != 0
        doc: Color change. dx and dy are 0 in the samples.
      is_jump:
        value: (flags & 0x02) != 0
        doc: Move without stitching.
      is_end:
        value: (flags & 0x04) != 0
        doc: End of the design. dx and dy are 0.
      is_negative_x:
        value: (flags & 0x40) != 0
        doc: True when x is negative.
      is_positive_y:
        value: (flags & 0x10) != 0
        doc: |
          True when y is positive; y is negative when the bit is clear (the
          reverse of the sign bit used for x).
      dx:
        value: 'is_negative_x ? -dx_abs : dx_abs'
        doc: Signed x move in 0.1 mm units.
      dy:
        value: 'is_positive_y ? dy_abs : -dy_abs'
        doc: |
          Signed y move in 0.1 mm units, in the stored direction (the reverse
          of screen Y, as in Husqvarna HUS).
