meta:
  id: toyota_10o
  title: Toyota 10O embroidery format
  file-extension: 10o
  license: MIT
doc: |
  Toyota stitch file with no header. The file is a list of 3-byte records:
  a control byte, a Y magnitude and an X magnitude. The control byte holds
  the sign of both offsets and the record type (stitch, move, start, color
  change, stop, trim, end). Offsets are relative, in 0.1 mm units
  (Unverified).
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/toyota_10o
seq:
  - id: records
    type: record
    repeat: expr
    repeat-expr: num_records
    doc: |
      All complete 3-byte records. The last record is the end record
      (control 0x87) in every sample.
  - id: trailer
    size-eos: true
    doc: Remaining bytes that do not make a complete record (0 in all samples).
instances:
  num_records:
    value: _io.size / 3
    doc: Number of complete 3-byte records in the file.
types:
  record:
    doc: One 3-byte record.
    seq:
      - id: control
        type: u1
        doc: |
          Bit 7 is set in every record of the samples (Unverified meaning).
          Bit 6 makes the Y offset negative, bit 5 the X offset negative.
          The low 5 bits give the type: 0x00 stitch, 0x10 move. Control
          records use exact values: 0x8A start, 0x85 color change, 0x82
          stop, 0x81 trim, 0x87 end.
      - id: y_raw
        type: u1
        doc: Y offset magnitude, 0.1 mm units (Unverified). Sign is in `control`.
      - id: x_raw
        type: u1
        doc: X offset magnitude, 0.1 mm units (Unverified). Sign is in `control`.
    instances:
      dx:
        value: '(control & 0x20) != 0 ? -x_raw : x_raw'
        doc: |
          Signed X offset. Positive is right in pyembroidery's convention
          (Unverified).
      dy:
        value: '(control & 0x40) != 0 ? -y_raw : y_raw'
        doc: |
          Signed Y offset as stored: bit 6 set makes it negative. pyembroidery
          uses the opposite sign (positive Y is down there), so a record
          with bit 6 set moves down in its output. Unverified which way is up.
      is_stitch:
        value: (control & 0x1f) == 0
        doc: Stitch (control 0x80, 0xA0, 0xC0, 0xE0 in the samples).
      is_move:
        value: (control & 0x1f) == 0x10
        doc: Move without stitching (control 0x90, 0xB0, 0xD0, 0xF0).
      is_start:
        value: control == 0x8a
        doc: Start record (offsets 0). Absent in Premier+ files.
      is_color_change:
        value: control == 0x85
        doc: Color change (offsets 0).
      is_stop:
        value: control == 0x82
        doc: Stop. Not in the samples; from pyembroidery.
      is_trim:
        value: control == 0x81
        doc: |
          Trim. Seen in Premier+ and My Editor files, where it carries
          offsets 0x00 0x00 or other values (Unverified).
      is_end:
        value: control == 0x87
        doc: End of design (offsets 0).
