meta:
  id: tajima_dst
  title: Tajima DST embroidery format
  file-extension: dst
  license: MIT
doc: |
  Industry-standard commercial stitch format. Stitch data only; no thread
  colors. A 512-byte ASCII header is followed by 3-byte stitch records, each
  holding a relative move of up to ±121 units (0.1 mm) per axis and a
  command (stitch, jump, color change, end). Some producers write extra
  bytes after the end record.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/tajima_dst
seq:
  - id: header
    type: header
    size: 512
    doc: Fixed-size text header.
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
      Bytes after the end record. 1a (Wilcom, Premier+) or 1a 00 00
      (My Editor) in the samples; may be empty.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  header:
    doc: |
      Fixed-width `KEY:value` fields, each ended by CR (0x0d), then 0x1a and
      padding to 512 bytes. Numeric values are right-aligned ASCII text with
      space padding; the position of the sign varies by producer
      ("-   37", "    +0", "     0"), so they are kept as text.
    seq:
      - id: label_key
        contents: "LA:"
      - id: label
        type: str
        size: 16
        encoding: ISO-8859-1
        pad-right: 0x20
        doc: Design name, space-padded. Wilcom truncates it to 8 characters.
      - id: label_cr
        contents: [0x0d]
      - id: stitch_count_key
        contents: "ST:"
      - id: stitch_count
        type: str
        size: 7
        encoding: ASCII
        doc: |
          Record count as decimal text. Wilcom and My Editor count every
          record including the end record; Premier+ writes a smaller value.
      - id: stitch_count_cr
        contents: [0x0d]
      - id: color_change_count_key
        contents: "CO:"
      - id: color_change_count
        type: str
        size: 3
        encoding: ASCII
        doc: |
          Color count as decimal text. Wilcom writes the number of color
          change records; Premier+ and My Editor write one more (the number
          of colors).
      - id: color_change_count_cr
        contents: [0x0d]
      - id: extent_x_pos_key
        contents: "+X:"
      - id: extent_x_pos
        type: str
        size: 5
        encoding: ASCII
        doc: Largest X reached, relative to the start point, in 0.1 mm units.
      - id: extent_x_pos_cr
        contents: [0x0d]
      - id: extent_x_neg_key
        contents: "-X:"
      - id: extent_x_neg
        type: str
        size: 5
        encoding: ASCII
        doc: |
          Distance from the start point to the smallest X reached, as a
          positive number, in 0.1 mm units.
      - id: extent_x_neg_cr
        contents: [0x0d]
      - id: extent_y_pos_key
        contents: "+Y:"
      - id: extent_y_pos
        type: str
        size: 5
        encoding: ASCII
        doc: Largest Y reached (Y up), relative to the start point, in 0.1 mm units.
      - id: extent_y_pos_cr
        contents: [0x0d]
      - id: extent_y_neg_key
        contents: "-Y:"
      - id: extent_y_neg
        type: str
        size: 5
        encoding: ASCII
        doc: |
          Distance from the start point to the smallest Y reached, as a
          positive number, in 0.1 mm units.
      - id: extent_y_neg_cr
        contents: [0x0d]
      - id: end_offset_x_key
        contents: "AX:"
      - id: end_offset_x
        type: str
        size: 6
        encoding: ASCII
        doc: |
          X of the last record relative to the start point, signed, in
          0.1 mm units. Wilcom fills it; Premier+ and My Editor write 0.
      - id: end_offset_x_cr
        contents: [0x0d]
      - id: end_offset_y_key
        contents: "AY:"
      - id: end_offset_y
        type: str
        size: 6
        encoding: ASCII
        doc: Y counterpart of `end_offset_x` (Y up).
      - id: end_offset_y_cr
        contents: [0x0d]
      - id: previous_end_x_key
        contents: "MX:"
      - id: previous_end_x
        type: str
        size: 6
        encoding: ASCII
        doc: |
          Unverified: X end point of the previous file of a multi-file
          design, in 0.1 mm units. 0 in every sample.
      - id: previous_end_x_cr
        contents: [0x0d]
      - id: previous_end_y_key
        contents: "MY:"
      - id: previous_end_y
        type: str
        size: 6
        encoding: ASCII
        doc: "Unverified: Y counterpart of `previous_end_x`. 0 in every sample."
      - id: previous_end_y_cr
        contents: [0x0d]
      - id: previous_file_key
        contents: "PD:"
      - id: previous_file
        type: str
        size: 6
        encoding: ASCII
        doc: |
          Unverified: name of the previous file of a multi-file design.
          "******" (none) in every sample.
      - id: previous_file_cr
        contents: [0x0d]
      - id: terminator
        type: u1
        doc: 0x1a (end of text) in every sample.
      - id: padding
        size-eos: true
        doc: |
          Fills the header to 512 bytes. Spaces (0x20); My Editor writes one
          0x00 first.
  stitch_record:
    doc: |
      One 3-byte stitch record. Each axis bit adds or subtracts a power of
      three (1, 3, 9, 27, 81), so one record moves at most ±121 units per
      axis. Byte 2 also holds the command bits; its two lowest bits are set
      in every record.
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
          0xf3 (both command bits and both y±81 bits set) marks the end.
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
          Relative Y move in 0.1 mm units, positive up (screen
          coordinates need the sign flipped).
      is_end:
        value: (byte2 & 0xf3) == 0xf3
        doc: End of stitch data. Both y±81 bits are set, so dy is 0.
      is_jump:
        value: (byte2 & 0xc0) == 0x80
        doc: Move without stitching.
      is_color_change:
        value: (byte2 & 0xc0) == 0xc0 and not is_end
        doc: Color change (stop). The move is applied as well; 0 in the samples.
      is_sequin:
        value: (byte2 & 0xc0) == 0x40
        doc: |
          Unverified: color change bit without jump bit, used for sequin
          mode by some producers. Not present in the samples.
      is_stitch:
        value: (byte2 & 0xc0) == 0
        doc: Normal stitch.
