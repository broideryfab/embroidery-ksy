meta:
  id: pfaff_max
  title: Pfaff MAX embroidery format
  file-extension: max
  license: MIT
  endian: le
doc: |
  Pfaff MAX: a 0xD5-byte header, a 32-bit stitch count and 8-byte records
  holding absolute X and Y positions as signed 24-bit values, each followed
  by one flag byte. Unverified: no redistributable sample was available; the
  layout follows other readers' description only, and the two readers
  consulted disagree on whether the stitch count exists. The header content
  is not decoded.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pfaff_max
seq:
  - id: header
    size: 0xd5
    doc: |
      Unverified: header bytes, content not decoded. One reader's writer
      emits a fixed block here that holds ASCII text (a thread name such as
      "Madeira Rayon 40" and thread numbers), so it may carry a color table.
  - id: num_records
    type: u4
    doc: |
      Unverified: number of stitch records. One reader reads this field at
      0xd5; another starts the records at 0xd5, with no count.
  - id: records
    type: record
    repeat: expr
    repeat-expr: num_records
    doc: Stitch records, `num_records` of them.
types:
  record:
    doc: |
      Unverified: one 8-byte stitch record. X and Y are absolute positions,
      not deltas.
    seq:
      - id: x_low
        type: u2
        doc: Low 16 bits of the X position (see `x`).
      - id: x_high
        type: s1
        doc: High 8 bits of the X position, signed.
      - id: flags_x
        type: u1
        doc: "Unverified: flag byte after X. Meaning unknown."
      - id: y_low
        type: u2
        doc: Low 16 bits of the Y position (see `y`).
      - id: y_high
        type: s1
        doc: High 8 bits of the Y position, signed.
      - id: flags_y
        type: u1
        doc: "Unverified: flag byte after Y. Meaning unknown."
    instances:
      x:
        value: x_high * 65536 + x_low
        doc: |
          Absolute X, signed 24-bit. Unit unverified: one reader multiplies
          by 1.235 and treats the result as 0.1 mm, another divides by 10 to
          get millimetres.
      y:
        value: y_high * 65536 + y_low
        doc: Absolute Y, signed 24-bit; same unit as X. Axis direction unverified.
