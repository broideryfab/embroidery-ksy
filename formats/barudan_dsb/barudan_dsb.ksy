meta:
  id: barudan_dsb
  title: Barudan DSB embroidery format
  file-extension: dsb
  license: MIT
  imports:
    - ../_common/barudan_record
doc: |
  Barudan variant of Tajima DST: the same 512-byte ASCII header, followed
  by the 3-byte Barudan records (control byte with axis signs and command,
  Y magnitude, X magnitude) instead of DST's bit-packed records. Stitch
  data and needle selection; no thread colors.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/barudan_dsb
seq:
  - id: header
    type: header
    size: 512
    doc: Fixed-size text header, same layout as Tajima DST.
  - id: records
    type: barudan_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Stitch records up to and including the end record. Parsing also stops
      at end of file, for files that have no end record.
  - id: trailer
    size-eos: true
    doc: |
      Bytes after the end record: 1a (Wilcom) or 1a 00 00 (My Editor) in
      the samples.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  header:
    doc: |
      Fixed-width `KEY:value` fields, each ended by CR (0x0d), then 0x1a and
      padding to 512 bytes. Numeric values are space-padded ASCII text,
      kept as text because the sign position varies by producer.
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
          Record count as decimal text. Wilcom counts every record
          including the end record. My Editor writes a larger
          number than the records present (298 for 178 records in
          scene-me); Unverified: what it counts.
      - id: stitch_count_cr
        contents: [0x0d]
      - id: color_change_count_key
        contents: "CO:"
      - id: color_change_count
        type: str
        size: 3
        encoding: ASCII
        doc: Color count as decimal text (16 in the samples).
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
        doc: Distance to the smallest X reached, as a positive number.
      - id: extent_x_neg_cr
        contents: [0x0d]
      - id: extent_y_pos_key
        contents: "+Y:"
      - id: extent_y_pos
        type: str
        size: 5
        encoding: ASCII
        doc: Largest Y reached (Y up), in 0.1 mm units.
      - id: extent_y_pos_cr
        contents: [0x0d]
      - id: extent_y_neg_key
        contents: "-Y:"
      - id: extent_y_neg
        type: str
        size: 5
        encoding: ASCII
        doc: Distance to the smallest Y reached, as a positive number.
      - id: extent_y_neg_cr
        contents: [0x0d]
      - id: end_offset_x_key
        contents: "AX:"
      - id: end_offset_x
        type: str
        size: 6
        encoding: ASCII
        doc: |
          X of the last position relative to the start point, signed.
          Wilcom fills it; My Editor writes +0.
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
        doc: "Unverified: X end point of a previous file of a multi-file design. 0 in every sample."
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
