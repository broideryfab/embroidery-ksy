meta:
  id: zsk_dsz
  title: ZSK DSZ embroidery format
  file-extension: dsz
  license: MIT
  imports:
    - ../tajima_dst/tajima_dst
doc: |
  ZSK variant of Tajima DST. A 512-byte ASCII header with the same layout as
  DST, followed by 3-byte records. Unlike DST, a record holds the move as two
  plain magnitudes (one byte per axis, up to 255 units of 0.1 mm), a control
  byte with the two sign bits, and a command (stitch, jump, needle change,
  trim, end). Some producers write extra bytes after the end record.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/zsk_dsz
seq:
  - id: header
    type: tajima_dst::header
    size: 512
    doc: |
      Fixed-size text header, identical in layout to the Tajima DST header.
      See `tajima_dst` for the field descriptions. `stitch_count` is not
      reliable in files from My Editor (0, or a value that differs from the
      record count).
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record. Parsing also stops at end
      of file, for files that have no end record.
  - id: trailer
    size-eos: true
    doc: |
      Bytes after the end record. 1a (Wilcom) or 1a 00 00 (My Editor) in the
      samples; may be empty.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  stitch_record:
    doc: |
      One 3-byte record. Byte order is Y magnitude, X magnitude, control;
      note that Y comes first. The control byte holds the sign bits and the
      command.
    seq:
      - id: y_magnitude
        type: u1
        doc: Absolute Y move in 0.1 mm units. The sign is in `control`.
      - id: x_magnitude
        type: u1
        doc: Absolute X move in 0.1 mm units. The sign is in `control`.
      - id: control
        type: u1
        doc: |
          Bit 7: set in every record of the samples, meaning unknown.
          Bit 6: X is negative. Bit 5: Y is negative.
          Bits 4..0: command (see `command`).
    instances:
      dx:
        value: 'x_negative ? -x_magnitude : x_magnitude'
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: 'y_negative ? -y_magnitude : y_magnitude'
        doc: |
          Relative Y move in 0.1 mm units, positive up (screen coordinates
          need the sign flipped). The header extents
          match this direction in all samples.
      x_negative:
        value: (control & 0x40) != 0
        doc: X move goes left.
      y_negative:
        value: (control & 0x20) != 0
        doc: Y move goes down.
      command:
        value: control & 0x9f
        doc: |
          Control byte without the sign bits (0x80 | low 5 bits):
          0x80 stitch, 0x81 jump, 0x82 stop (Unverified), 0x83..0x9a needle
          change, 0x90 end, 0x9b trim.
      is_stitch:
        value: command == 0x80
        doc: Normal stitch.
      is_jump:
        value: command == 0x81
        doc: Move without stitching.
      is_stop:
        value: command == 0x82
        doc: "Unverified: stop. Not present in the samples."
      is_trim:
        value: command == 0x9b
        doc: Trim. Present in `scene-me.dsz` only.
      is_end:
        value: (control & 0x1f) == 0x10
        doc: |
          End of stitch data (`00 00 90` in the samples). Checked on the low
          five bits only, because 0x93 is a needle change, not an end.
      is_needle_change:
        value: command >= 0x83 and command <= 0x9a and command != 0x90
        doc: |
          Needle (color) change. Observed codes: 0x85, 0x87, 0x89, 0x8b,
          0x8d, 0x8f, 0x93. The move is 0 in every sample.
      needle_index:
        value: (command - 0x83) / 2
        doc: |
          Unverified: needle number minus one, from the offset of
          `command` above 0x83. Meaningful only when `is_needle_change`.
