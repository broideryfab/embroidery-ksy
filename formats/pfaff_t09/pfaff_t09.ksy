meta:
  id: pfaff_t09
  title: Pfaff T09 embroidery format
  file-extension: t09
  license: MIT
doc: |
  Pfaff T09: a 12-byte header followed by 3-byte records (two move
  magnitudes and a command byte with the signs), ended by a record whose
  command byte is 0. Stitch data only. Unverified: no redistributable
  sample was available; the layout follows one other reader's description
  only, and that reader's writer disagrees with its reader on the axes.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pfaff_t09
seq:
  - id: header
    size: 12
    doc: "Unverified: 12 bytes, content unknown. Written as zeros by one writer."
  - id: records
    type: record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record (command byte 0), or to end
      of file. Unverified: a trailing partial record makes parsing fail.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  record:
    doc: "Unverified: one 3-byte record."
    seq:
      - id: magnitude_a
        type: u1
        doc: |
          Absolute move on the Y axis in 0.1 mm units, per the reader
          consulted; the sign is bit 5 of `command`.
      - id: magnitude_b
        type: u1
        doc: |
          Absolute move on the X axis in 0.1 mm units; the sign is bit 6 of
          `command`.
      - id: command
        type: u1
        doc: |
          Bit 6: X negative. Bit 5: Y negative. Bit 4: stop (color change).
          0 ends the data. A writer sets the low two bits (0x03) on normal
          stitches; unverified.
    instances:
      is_end:
        value: command == 0
        doc: End record. The record's moves are not applied.
      is_stop:
        value: (command & 0x10) != 0
        doc: Stop / color change.
      dx:
        value: '(command & 0x40) != 0 ? -magnitude_b : magnitude_b'
        doc: Relative X move in 0.1 mm units.
      dy:
        value: '(command & 0x20) != 0 ? -magnitude_a : magnitude_a'
        doc: Relative Y move in 0.1 mm units; axis direction unverified.
