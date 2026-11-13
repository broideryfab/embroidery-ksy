meta:
  id: pfaff_t01
  title: Pfaff T01 embroidery format
  file-extension: t01
  license: MIT
doc: |
  Pfaff T01: a headerless stream of 3-byte records in the Tajima DST
  encoding (each axis built from signed powers of three, plus a command
  byte), ended by the record 00 00 f3. Stitch data only. Unverified: no
  redistributable sample was available; the layout follows one other
  library's description only, and that library also stores T01 data that
  begins at offset 0 with no header.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pfaff_t01
seq:
  - id: records
    type: record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record, or to end of file.
      Unverified: a trailing partial record makes parsing fail.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  record:
    doc: |
      Unverified: one 3-byte record, the same bit layout as a Tajima DST
      record (see [tajima_dst](../tajima_dst/README.md)).
    seq:
      - id: byte0
        type: u1
        doc: "Bits 7..0: y+1, y-1, y+9, y-9, x-9, x+9, x-1, x+1."
      - id: byte1
        type: u1
        doc: "Bits 7..0: y+3, y-3, y+27, y-27, x-27, x+27, x-3, x+3."
      - id: byte2
        type: u1
        doc: |
          Command byte. Low two bits set in every normal record. 0x83 is a
          trim or jump, 0xc3 a stop, 0xf3 the end. Whether the y/x +-81
          bits (bits 2..5) are used is unverified.
    instances:
      dx:
        value: >-
          ((byte0 & 0x01) - ((byte0 >> 1) & 0x01))
          + 9 * (((byte0 >> 2) & 0x01) - ((byte0 >> 3) & 0x01))
          + 3 * ((byte1 & 0x01) - ((byte1 >> 1) & 0x01))
          + 27 * (((byte1 >> 2) & 0x01) - ((byte1 >> 3) & 0x01))
          + 81 * (((byte2 >> 2) & 0x01) - ((byte2 >> 3) & 0x01))
        doc: Relative X move in 0.1 mm units (the 81 term is unverified).
      dy:
        value: >-
          (((byte0 >> 7) & 0x01) - ((byte0 >> 6) & 0x01))
          + 9 * (((byte0 >> 5) & 0x01) - ((byte0 >> 4) & 0x01))
          + 3 * (((byte1 >> 7) & 0x01) - ((byte1 >> 6) & 0x01))
          + 27 * (((byte1 >> 5) & 0x01) - ((byte1 >> 4) & 0x01))
          + 81 * (((byte2 >> 5) & 0x01) - ((byte2 >> 4) & 0x01))
        doc: Relative Y move in 0.1 mm units, Y up (the 81 term is unverified).
      is_end:
        value: byte2 == 0xf3
        doc: End record.
      is_trim:
        value: (byte2 & 0xc3) == 0x83
        doc: Trim / jump.
      is_stop:
        value: (byte2 & 0xc3) == 0xc3 and not is_end
        doc: Stop / color change.
