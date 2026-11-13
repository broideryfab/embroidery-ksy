meta:
  id: inbro_inb
  title: Inbro INB embroidery format
  file-extension: inb
  license: MIT
  endian: le
doc: |
  Inbro format. A 0x2000-byte header (design name, record count, size,
  color count, bounding box at 0x14b) is followed by 3-byte records: X and Y
  magnitudes (unsigned bytes) and a control byte with the command in its low
  nibble and the signs of X and Y in its high bits. A record with control
  0x04 ends the stream.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/inbro_inb
seq:
  - id: header
    type: header
    size: 0x2000
    doc: Fixed-size 8192-byte header, mostly zero bytes.
  - id: records
    type: record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record. Parsing also stops at end
      of file, for files without an end record.
  - id: trailer
    size-eos: true
    doc: Bytes after the last complete record (0 to 2). Empty in the samples.
types:
  header:
    seq:
      - id: design_name
        type: strz
        size: 9
        encoding: ASCII
        doc: |
          Design name, NUL-terminated, truncated to 8 characters (Wilcom
          writes an 8.3 style name).
      - id: unknown_0x09
        type: u2
        doc: Unknown. 1 in every sample.
      - id: record_count
        type: u4
        doc: |
          Number of records after the header, not counting the end record
          (checked against all 5 samples).
      - id: width
        type: u2
        doc: Design width in 0.1 mm units (equals left + right extent).
      - id: height
        type: u2
        doc: Design height in 0.1 mm units (equals up + down extent).
      - id: color_count
        type: u2
        doc: |
          Number of colors: color change records plus one (checked against
          all 5 samples).
      - id: unknown_0x15
        type: u2
        doc: |
          Unknown. 109, 113, 117 in random1 to random3, 20 in scene, 16 in
          spiralbox; not the same as any extent.
      - id: reserved_0x17
        type: u2
        doc: Always 0.
      - id: unknown_0x19
        type: u2
        doc: Unknown. 100 in every sample.
      - id: unknown_0x1b
        type: u2
        doc: Unknown. 100 in every sample.
      - id: reserved_0x1d
        size: 0x14b - 0x1d
        doc: Zero bytes up to the bounding box.
      - id: extent_left
        type: u2
        doc: |
          Distance from the start point to the smallest X, in 0.1 mm units
          (positive number).
      - id: extent_right
        type: u2
        doc: Largest X reached, in 0.1 mm units.
      - id: extent_up
        type: u2
        doc: |
          Largest Y reached with Y up (the file's own direction), in 0.1 mm
          units. Unverified: Y direction taken from pyembroidery.
      - id: extent_down
        type: u2
        doc: Distance to the smallest Y (positive number), 0.1 mm units.
      - id: reserved_0x153
        size-eos: true
        doc: Zero bytes up to 0x2000.
  record:
    doc: |
      One 3-byte record. X and Y are sign-magnitude: the bytes hold the
      magnitude, the control byte holds the signs.
    seq:
      - id: x_magnitude
        type: u1
        doc: Absolute X delta, 0.1 mm units.
      - id: y_magnitude
        type: u1
        doc: Absolute Y delta, 0.1 mm units.
      - id: control
        type: u1
        doc: |
          Low nibble: 0 stitch, 1 color change, 2 move. Whole byte 0x04: end.
          Bit 0x40: X negative. Bit 0x20: Y negative (Y up, Unverified).
          In every stitch, move and color change record of the samples
          exactly one of 0x40 and 0x80 is set, and exactly one of 0x20 and
          0x10; 0x80 and 0x10 are probably the positive counterparts
          (Unverified; pyembroidery ignores them). The end record is 0x04.
    instances:
      command:
        value: control & 0x0f
        doc: 0 stitch, 1 color change, 2 move, 4 end.
      is_end:
        value: control == 0x04
        doc: End record.
      is_stitch:
        value: (control & 0x0f) == 0x00
        doc: Stitch.
      is_color_change:
        value: (control & 0x0f) == 0x01
        doc: |
          Color change. The deltas are the move to the first point of the next
          color (all in the samples are non-zero deltas).
      is_move:
        value: (control & 0x0f) == 0x02
        doc: Move without stitching (jump).
      x_negative:
        value: (control & 0x40) != 0
        doc: X delta is negative.
      y_negative:
        value: (control & 0x20) != 0
        doc: Y delta is negative (Y up).
      dx:
        value: 'x_negative ? -x_magnitude : x_magnitude'
        doc: X delta, 0.1 mm units. Positive is right.
      dy:
        value: 'y_negative ? -y_magnitude : y_magnitude'
        doc: |
          Y delta, 0.1 mm units. Positive is up (pyembroidery negates it).
          Unverified.
