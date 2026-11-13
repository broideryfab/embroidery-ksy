meta:
  id: gold_thread_gt
  title: Gold Thread GT embroidery format
  file-extension: gt
  license: MIT
doc: |
  Gold Thread GT: a 512-byte header followed by 3-byte records, the same record
  layout as ZSK DSZ (Y magnitude, X magnitude, control with sign bits and
  command). Unverified: no redistributable .gt sample was available; the
  layout follows other readers' description only. Nothing is known about the
  header contents.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/gold_thread_gt
seq:
  - id: header
    size: 512
    doc: |
      Unverified: 512 bytes that no reader interprets; contents unknown.
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record, or to end of file.
      Unverified: a trailing partial record would make parsing fail.
  - id: trailer
    size-eos: true
    doc: Bytes after the end record; usually empty.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  stitch_record:
    doc: |
      Unverified: one 3-byte record. Byte order is Y magnitude, X magnitude,
      control (Y first). The control byte holds the sign bits and a command.
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
          Bit 6: X is negative. Bit 5: Y is negative. Bits 4..0 and bit 7:
          command (see `command`).
    instances:
      dx:
        value: 'x_negative ? -x_magnitude : x_magnitude'
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: 'y_negative ? -y_magnitude : y_magnitude'
        doc: Relative Y move in 0.1 mm units, positive up.
      x_negative:
        value: (control & 0x40) != 0
        doc: X move goes left.
      y_negative:
        value: (control & 0x20) != 0
        doc: Y move goes down.
      command:
        value: control & 0x9f
        doc: Control byte without the sign bits.
      is_stitch:
        value: (control & 0x1f) == 0x00
        doc: Normal stitch.
      is_jump:
        value: (control & 0x1f) == 0x01
        doc: Move without stitching.
      is_stop:
        value: control == 0x82
        doc: Stop.
      is_trim:
        value: control == 0x9b
        doc: Trim.
      is_needle_change:
        value: control >= 0x83 and control <= 0x9a and (control & 0x1f) != 0x10
        doc: |
          Needle (color) change. The needle number minus one is
          `(control - 0x83) / 2`.
      is_end:
        value: (control & 0x1f) == 0x10 or (control & 0x1f) == 0x11
        doc: |
          End of stitch data. Other readers treat 0x90 (or any unlisted
          control) as the end; one reader names 0x91.
