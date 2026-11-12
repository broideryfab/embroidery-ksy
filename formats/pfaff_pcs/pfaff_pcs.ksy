meta:
  id: pfaff_pcs
  title: Pfaff PCS embroidery format
  file-extension: pcs
  license: MIT
  endian: le
doc: |
  Older Pfaff format (also the layout of PCD and PCQ). A 4-byte header
  (version, hoop, color count) is followed by a table of RGB colors, a stitch
  count, and 9-byte records with absolute positions in fixed-point
  coordinates and a control byte (stitch, move, color change).
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pfaff_pcs
seq:
  - id: version
    type: u1
    doc: 0x32 ("2") in every sample. Unverified meaning.
  - id: hoop_code
    type: u1
    doc: |
      Hoop. 3 in most samples (large hoop), 2 in spiralbox-wilcom-b.PCS
      (small hoop, 80 x 80 mm). Unverified.
  - id: num_colors
    type: u2
    doc: |
      Number of entries in the color table: 16 in Wilcom and My Editor files,
      15 in Premier+ files. Not the number of colors used.
  - id: colors
    type: color
    repeat: expr
    repeat-expr: num_colors
    doc: Color table.
  - id: stitch_count
    type: u2
    doc: |
      Number of stitch and move records, color change records not included
      (checked against all samples).
  - id: records
    type: stitch_record
    repeat: expr
    repeat-expr: num_records
    doc: |
      All complete 9-byte records up to the end of the file. There is no end
      marker; Wilcom and My Editor pad the file with zero bytes, so the last
      records may be all zero (parsed as a stitch at 0, 0).
  - id: trailer
    size-eos: true
    doc: Remaining bytes that do not make a complete record (0 to 8).
instances:
  num_records:
    value: (_io.size - (4 + 4 * num_colors + 2)) / 9
    doc: |
      Number of complete 9-byte records between the stitch count and the end
      of the file, padding records included.
types:
  color:
    seq:
      - id: red
        type: u1
      - id: green
        type: u1
      - id: blue
        type: u1
      - id: reserved_0x03
        type: u1
        doc: Always 0 in the samples.
  stitch_record:
    doc: |
      One 9-byte record. X and Y are 32-bit little-endian fixed-point
      numbers: the low byte is a fraction in 1/256, the upper 24 bits are
      the signed integer part. In color change records the low byte of X
      holds the color index and the rest is 0.
    seq:
      - id: x_raw
        type: s4le
        doc: X position, fixed point (integer part << 8 | fraction).
      - id: y_raw
        type: s4le
        doc: Y position, fixed point (integer part << 8 | fraction).
      - id: control
        type: u1
        doc: 0x00 stitch, 0x03 color change, 0x04 move (jump).
    instances:
      x:
        value: x_raw >> 8
        doc: |
          Integer part of the X position. Absolute, not a delta. In
          pyembroidery's conversion one unit is 5/3 of its 0.1 mm unit.
          Unverified.
      x_fraction:
        value: x_raw & 0xff
        doc: |
          Fractional part of X in 1/256. In the samples always a multiple of
          about 0.2 (0x00, 0x33, 0x66, 0x9a, 0xcd).
      y:
        value: y_raw >> 8
        doc: |
          Integer part of the Y position. Absolute. Unverified direction:
          pyembroidery negates it, so it is probably Y up in the file.
      y_fraction:
        value: y_raw & 0xff
        doc: Fractional part of Y in 1/256.
      color_index:
        value: x_raw & 0xff
        doc: |
          Only meaningful when `is_color_change`: index into the color
          table, counting 0, 1, 2, ... for each change (first record is
          index 0).
      is_stitch:
        value: control == 0
        doc: Stitch.
      is_color_change:
        value: (control & 0x01) != 0
        doc: Color change (control 0x03 in all samples).
      is_move:
        value: (control & 0x01) == 0 and (control & 0x04) != 0
        doc: Move without stitching (control 0x04).
