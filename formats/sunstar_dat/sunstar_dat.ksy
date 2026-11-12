meta:
  id: sunstar_dat
  title: Sunstar DAT embroidery format
  file-extension: dat
  license: MIT
doc: |
  Sunstar DAT stitch file: a 256-byte header followed by 3-byte records with
  a relative move and a control byte. Shares the .dat extension with Barudan
  DAT; detect by content.
  Unverified: written from another reader's code only. No sample file was
  available, so none of this has been run against a real file.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/sunstar_dat
seq:
  - id: header
    size: 256
    doc: |
      Unverified: 256-byte header, not decoded. Bytes 2..3 may hold a stitch
      count (see `stitch_count_candidate`).
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Unverified: stitch records up to and including the first record whose
      control byte is 0x00, or to the end of the file.
instances:
  stitch_count_candidate:
    pos: 2
    type: u2le
    doc: |
      Unverified: 16-bit little-endian value at offset 2, possibly the
      stitch count. Not confirmed.
  num_records:
    value: records.size
    doc: Number of records read, including the end record if present.
types:
  stitch_record:
    doc: |
      Unverified: one 3-byte record. Bytes 0 and 1 are sign-magnitude
      (bit 7 = negative) X and Y values, byte 2 is the control code.
    seq:
      - id: x_raw
        type: u1
        doc: X move, bit 7 = negative, bits 0..6 = magnitude.
      - id: y_raw
        type: u1
        doc: Y move, bit 7 = negative, bits 0..6 = magnitude.
      - id: control
        type: u1
        doc: |
          Control code. Known values: 0x07 stitch, 0x04 jump, 0x80 trim,
          0x87 color change, 0x84 initial info stitch, 0x00 end.
    instances:
      dx:
        value: 'x_raw >= 128 ? -(x_raw & 0x7f) : x_raw'
        doc: Relative X move in units (assumed 0.1 mm), positive to the right.
      dy:
        value: 'y_raw >= 128 ? -(y_raw & 0x7f) : y_raw'
        doc: Relative Y move in units (assumed 0.1 mm), as stored.
      is_stitch:
        value: control == 0x07
        doc: Normal stitch.
      is_jump:
        value: control == 0x04
        doc: Move without stitching.
      is_trim:
        value: control == 0x80
        doc: Thread trim; may carry a move.
      is_color_change:
        value: control == 0x87
        doc: Color change; may carry a move.
      is_initial:
        value: control == 0x84
        doc: "Unverified: initial or info record, treated as a stitch by one reader."
      is_end:
        value: control == 0x00
        doc: End of stitch data.
