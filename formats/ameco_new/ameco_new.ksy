meta:
  id: ameco_new
  title: Ameco NEW embroidery format
  file-extension: new
  license: MIT
doc: |
  Ameco NEW: a 2-byte header followed by 3-byte records (X magnitude, Y
  magnitude, control with sign bits and command). Unverified: no
  redistributable .new sample was available; the layout follows other
  readers' description only.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/ameco_new
seq:
  - id: unknown_0x00
    size: 2
    doc: |
      Unverified: probably the stitch count (a reader's comment says so),
      but its byte order and whether it matches the record count are not
      known. Kept as raw bytes.
  - id: records
    type: record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record, or to end of file.
      Unverified: a trailing partial record would make parsing fail.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  record:
    doc: |
      Unverified: one 3-byte record.
    seq:
      - id: x_magnitude
        type: u1
        doc: Absolute X move, in 0.1 mm units (Unverified). Sign in `control`.
      - id: y_magnitude
        type: u1
        doc: Absolute Y move, in 0.1 mm units (Unverified). Sign in `control`.
      - id: control
        type: u1
        doc: |
          Bit 6: X is negative. Bit 5: Y is negative. Bit 7: unknown.
          Bits 4..0: command (see `command`).
    instances:
      dx:
        value: '(control & 0x40) != 0 ? -x_magnitude : x_magnitude'
        doc: Relative X move, positive to the right.
      dy:
        value: '(control & 0x20) != 0 ? -y_magnitude : y_magnitude'
        doc: Relative Y move, positive up.
      command:
        value: control & 0x1f
        doc: |
          Command bits: 0x00 stitch, 0x11 end; otherwise bit 1 marks a color
          change and bit 0 a jump (move), checked in that order.
      is_end:
        value: command == 0x11
        doc: End of stitch data.
      is_stitch:
        value: command == 0
        doc: Normal stitch.
      is_color_change:
        value: command != 0 and command != 0x11 and (command & 0x02) != 0
        doc: Color change; the move is ignored by other readers.
      is_jump:
        value: command != 0 and command != 0x11 and (command & 0x02) == 0 and (command & 0x01) != 0
        doc: Move without stitching.
