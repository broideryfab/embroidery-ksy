meta:
  id: happy_tap
  title: Happy TAP embroidery format
  file-extension: tap
  license: MIT
doc: |
  Happy TAP stitch file. No header and no thread colors: a flat list of
  3-byte records using the same bit encoding as Tajima DST (relative move of
  up to ±121 units of 0.1 mm per axis plus a command), ending with an end
  record. Wilcom writes 6 zero bytes before the first record and 3 zero
  bytes after the end record; Wings My Editor writes neither.
  Unverified: the encoding is inferred from sample files and from other
  readers; no Happy documentation was available.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/happy_tap
seq:
  - id: prefix
    size: 6
    if: has_prefix
    doc: |
      Six 0x00 bytes written by Wilcom before the first record. Unverified:
      purpose (possibly two empty records or a reserved header).
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Stitch records up to and including the end record. Parsing also stops
      at end of file, for files that have no end record.
  - id: trailer
    size-eos: true
    doc: |
      Bytes after the end record: 00 00 00 in the Wilcom samples, empty in
      the My Editor samples.
instances:
  prefix_probe:
    pos: 0
    size: 6
    doc: The first six bytes, used to detect the Wilcom prefix.
  has_prefix:
    value: prefix_probe == [0, 0, 0, 0, 0, 0]
    doc: |
      True when the file starts with six zero bytes. A real first record
      never has byte 2 equal to 0x00 (its two lowest bits are always set),
      so this does not collide with stitch data.
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  stitch_record:
    doc: |
      One 3-byte stitch record, identical to the Tajima DST record. Each
      axis bit adds or subtracts a power of three (1, 3, 9, 27, 81). Byte 2
      also holds the command bits; its two lowest bits are set in every
      record.
    seq:
      - id: byte0
        type: u1
        doc: |
          Bits 7..0: y+1, y-1, y+9, y-9, x-9, x+9, x-1, x+1.
      - id: byte1
        type: u1
        doc: |
          Bits 7..0: y+3, y-3, y+27, y-27, x-27, x+27, x-3, x+3.
      - id: byte2
        type: u1
        doc: |
          Bits 7..0: jump, color change, y+81, y-81, x-81, x+81, 1, 1.
          0xf3 marks the end.
    instances:
      dx:
        value: >-
          ((byte0 & 0x01) - ((byte0 >> 1) & 0x01))
          + 9 * (((byte0 >> 2) & 0x01) - ((byte0 >> 3) & 0x01))
          + 3 * ((byte1 & 0x01) - ((byte1 >> 1) & 0x01))
          + 27 * (((byte1 >> 2) & 0x01) - ((byte1 >> 3) & 0x01))
          + 81 * (((byte2 >> 2) & 0x01) - ((byte2 >> 3) & 0x01))
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: >-
          (((byte0 >> 7) & 0x01) - ((byte0 >> 6) & 0x01))
          + 9 * (((byte0 >> 5) & 0x01) - ((byte0 >> 4) & 0x01))
          + 3 * (((byte1 >> 7) & 0x01) - ((byte1 >> 6) & 0x01))
          + 27 * (((byte1 >> 5) & 0x01) - ((byte1 >> 4) & 0x01))
          + 81 * (((byte2 >> 5) & 0x01) - ((byte2 >> 4) & 0x01))
        doc: |
          Relative Y move in 0.1 mm units, positive up (as in DST, whose
          records are identical in the samples).
      is_end:
        value: (byte2 & 0xf3) == 0xf3
        doc: End of stitch data. Usually 00 00 f3.
      is_jump:
        value: (byte2 & 0xc0) == 0x80
        doc: Move without stitching.
      is_color_change:
        value: (byte2 & 0xc0) == 0xc0 and not is_end
        doc: Color change (stop).
      is_sequin:
        value: (byte2 & 0xc0) == 0x40
        doc: |
          Unverified: sequin mode as in DST. Not present in the samples.
      is_stitch:
        value: (byte2 & 0xc0) == 0
        doc: Normal stitch.
