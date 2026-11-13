meta:
  id: zsk_zxy
  title: ZSK ZXY embroidery format
  file-extension: zxy
  license: MIT
doc: |
  ZSK ZXY: a short header whose second and third bytes give the length of
  further header data, then 3-byte records (control, X magnitude, Y
  magnitude). Unverified: no redistributable .zxy sample was available; the
  layout follows other readers' description only.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/zsk_zxy
seq:
  - id: unknown_0x00
    type: u1
    doc: |
      Unverified: not interpreted by any reader.
  - id: len_unknown_0x03
    type: u2be
    doc: |
      Length in bytes of the header data after this field, i.e. the stitch
      records start at offset 3 + `len_unknown_0x03`. Unverified.
  - id: unknown_0x03
    size: len_unknown_0x03
    doc: |
      Unverified: header data; contents unknown.
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
      - id: control
        type: u1
        doc: |
          Bit 3: X is negative. Bit 2: Y is negative. The remaining bits
          are the command (see `command`).
      - id: x_magnitude
        type: u1
        doc: Absolute X move. Sign in `control`. Unit unknown (0.1 mm?).
      - id: y_magnitude
        type: u1
        doc: |
          Absolute Y move, or the needle number in a needle-change record.
          Sign in `control`.
    instances:
      dx:
        value: '(control & 0x08) != 0 ? -x_magnitude : x_magnitude'
        doc: Relative X move, positive to the right.
      dy:
        value: '(control & 0x04) != 0 ? -y_magnitude : y_magnitude'
        doc: Relative Y move, positive up.
      command:
        value: control & 0xf3
        doc: Control byte without the two sign bits.
      is_stitch:
        value: command == 0
        doc: Normal stitch.
      is_jump:
        value: command != 0 and (command & 0x02) != 0
        doc: Move without stitching (checked before the needle-change bit).
      is_special:
        value: (command & 0x22) == 0x20
        doc: Needle change or end record (bit 5 set, bit 1 clear).
      is_end:
        value: is_special and x_magnitude == 0xff
        doc: End of stitch data.
      is_needle_change:
        value: is_special and x_magnitude != 0xff
        doc: Needle (color) change; `y_magnitude` holds the needle number.
