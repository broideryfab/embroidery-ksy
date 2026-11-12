meta:
  id: tajima_tbf
  title: Tajima TBF embroidery format
  file-extension: tbf
  license: MIT
  endian: le
doc: |
  Newer Tajima format with thread colors. A 0x600-byte header (version text,
  `KEY:value` text fields, a needle order table and an RGB thread table) is
  followed by 3-byte records: a signed X move, a signed Y move and a command
  byte (stitch, needle change, jump, trim, stop, end). Moves are in 0.1 mm
  units, Y up. Stitch data starts at offset 0x600.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/tajima_tbf
seq:
  - id: version
    type: str
    size: 8
    encoding: ASCII
    pad-right: 0x20
    doc: |
      Version text, space-padded: "3.00" (Wilcom) or "03.00" (Wings My
      Editor). Unverified: whether other versions exist.
  - id: unknown_0x08
    type: u4
    doc: |
      Unknown. In the Wilcom samples it reads as a little-endian number close
      to 0x5d2a5a8f, 0x5d2a5d04, ... which looks like a Unix timestamp from
      July 2019 (Unverified). My Editor writes the constant 0x0018eb70.
  - id: reserved_0x0c
    size: 116
    doc: Spaces (0x20) up to offset 0x80.
  - id: text_header
    type: text_header
    doc: Text fields from offset 0x80 to 0x20a.
  - id: thread_area
    type: thread_area
    size: 0x3f5
    doc: Thread color table from offset 0x20b to the start of stitch data (0x600).
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.command == command::end or _io.eof
    doc: |
      Stitch records up to and including the end record. Parsing also stops
      at end of file, for files that have no end record.
  - id: trailer
    size-eos: true
    doc: Bytes after the end record. A single 0x1a in every sample; may be empty.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  text_header:
    doc: |
      Fixed-width `KEY:value` fields, each ended by CR (0x0d). Numeric values
      are right-aligned ASCII text with space padding; the position of the
      sign varies by producer ("-   37", "    +0"), so they are kept as text.
    seq:
      - id: label_key
        contents: "LA:"
      - id: label
        type: str
        size: 16
        encoding: ISO-8859-1
        pad-right: 0x20
        doc: |
          Design name, space-padded. Unverified: names longer than 16
          characters are presumably truncated.
      - id: label_cr
        contents: [0x0d]
      - id: stitch_count_key
        contents: "ST:"
      - id: stitch_count
        type: str
        size: 7
        encoding: ASCII
        doc: Record count as decimal text, including the end record.
      - id: stitch_count_cr
        contents: [0x0d]
      - id: color_change_count_key
        contents: "CO:"
      - id: color_change_count
        type: str
        size: 3
        encoding: ASCII
        doc: |
          Color count as decimal text (10 for random1, 3 for scene, 16 for
          spiralbox). Not always the number of needle change records.
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
          0.1 mm units. Wilcom fills it; My Editor writes 0.
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
      - id: type_key
        contents: "TP:"
      - id: type_text
        type: str
        size: 32
        encoding: ASCII
        pad-right: 0x20
        doc: Unknown. "EG/" in every sample, space-padded to 32 characters.
      - id: type_cr
        contents: [0x0d]
      - id: jc_key
        contents: "JC:"
      - id: jc
        type: str
        size: 1
        encoding: ASCII
        doc: Unknown. "3" in every sample.
      - id: jc_cr
        contents: [0x0d]
      - id: needle_order_key
        contents: "DO:"
      - id: needle_order
        size: 256
        doc: |
          Needle numbers (1-based) for the needle change records, in order of
          appearance, zero-padded to 256 bytes. Observed: the n-th needle
          change record (command 0x81) takes the n-th value. Wilcom writes
          one entry per change record (the first color appears twice:
          "01 01 02 ..."); My Editor writes one more entry than there are
          change records.
      - id: needle_order_cr
        contents: [0x0d]
  thread_area:
    doc: |
      `DA:` followed by thread entries of 5 bytes: 0x45 ("E"), red, green,
      blue, 0x20. The list ends at the first byte that is not 0x45; the rest
      of the area is spaces, with 0x0d 0x1a somewhere inside (offset 0x376
      for Wilcom, 0x501 for My Editor). Wilcom writes the used colors only
      (10, 3 and 16 entries in the samples); My Editor writes 99 entries.
    seq:
      - id: key
        contents: "DA:"
      - id: threads
        type: thread_entry
        repeat: until
        repeat-until: _.marker != 0x45 or _io.eof
        doc: |
          Thread colors. The last element is the terminator (its `marker` is
          not 0x45) and is not a thread.
      - id: padding
        size-eos: true
        doc: "Spaces, with a 0x0d 0x1a pair. Unverified: meaning of 0x1a here."
  thread_entry:
    seq:
      - id: marker
        type: u1
        doc: 0x45 ("E") for a thread entry; anything else ends the list.
      - id: red
        type: u1
        if: marker == 0x45
        doc: Red, 0-255.
      - id: green
        type: u1
        if: marker == 0x45
        doc: Green, 0-255.
      - id: blue
        type: u1
        if: marker == 0x45
        doc: Blue, 0-255.
      - id: separator
        type: u1
        if: marker == 0x45
        doc: 0x20 (space) in every sample.
  stitch_record:
    doc: |
      One 3-byte record: a signed move and a command. Only `stitch` and
      `jump` carry a move in the samples; the other commands have 0, 0.
    seq:
      - id: dx
        type: s1
        doc: Relative X move in 0.1 mm units, positive to the right.
      - id: dy
        type: s1
        doc: |
          Relative Y move in 0.1 mm units, positive up (screen coordinates
          need the sign flipped).
      - id: command
        type: u1
        enum: command
        doc: Record type.
enums:
  command:
    0x40:
      id: stop
      doc: "Unverified: stop. Not present in the samples."
    0x80:
      id: stitch
      doc: Stitch with the move (dx, dy).
    0x81:
      id: needle_change
      doc: Change to the next needle from `needle_order`. Move is 0, 0.
    0x86:
      id: trim
      doc: Trim thread. Move is 0, 0.
    0x8f:
      id: end
      doc: End of stitch data. Move is 0, 0.
    0x90:
      id: jump
      doc: Move without stitching.
