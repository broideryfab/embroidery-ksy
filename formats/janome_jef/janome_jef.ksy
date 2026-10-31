meta:
  id: janome_jef
  title: Janome JEF embroidery format
  file-extension: jef
  license: MIT
  endian: le
doc: |
  Janome / Elna home-machine format. A little-endian header (stitch data
  offset, save date, color count, hoop, design extents and fit in four
  standard hoops) is followed by a color table of Janome palette indices,
  then 2-byte stitch records: a signed X and Y move of up to ±127 units
  (0.1 mm), or the escape byte 0x80 followed by a command (color change,
  jump, end). Wings My Editor's JEF+ variant (flags 1) has an extra block
  before the stitch data and more data after the end record.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/janome_jef
seq:
  - id: header
    type: header
    doc: Fixed 116-byte header.
  - id: color_indices
    type: s4
    repeat: expr
    repeat-expr: header.color_count
    doc: |
      Janome thread palette index per color, in sewing order. The palette
      itself is not part of the file.
  - id: thread_types
    type: u4
    repeat: expr
    repeat-expr: header.color_count
    doc: |
      Unverified: one value per color, possibly a thread type. 13 for every
      color in every sample.
  - id: header_extension
    size: header.stitch_offset - (0x74 + 8 * header.color_count)
    doc: |
      Bytes between the color tables and the stitch data. Empty in plain
      JEF files. JEF+ (flags 1) has 22 bytes here: u4 0, u4 0, "JANOME"
      padded with 0x00 to 8 bytes, u4 1, u2 0. Meaning unknown.
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
      Bytes after the end record. Empty in plain JEF files. JEF+ has
      2 bytes 00 00, a 52-byte block, then a complete second JEF file
      (see the README).
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  header:
    seq:
      - id: stitch_offset
        type: u4
        doc: |
          Absolute file offset of the first stitch record. 0x74 + 8 *
          color_count in plain JEF files; 22 more in JEF+.
      - id: flags
        type: u4
        doc: |
          Unverified: 0x14 (Janome, Premier+, pyembroidery), 0x0a
          (My Editor .jef), 0x01 (My Editor .jef+). Meaning of the bits
          unknown.
      - id: date_time
        type: str
        size: 14
        encoding: ASCII
        doc: Save date and time as text, YYYYMMDDHHMMSS.
      - id: reserved_0x16
        size: 2
        doc: 00 00 in every sample.
      - id: color_count
        type: u4
        doc: Number of colors (entries in each color table).
      - id: point_count
        type: u4
        doc: |
          Length of the stitch data in 2-byte words, including the 2-byte
          end record (a stitch counts 1, a jump or color change 2).
      - id: hoop_code
        type: u4
        enum: hoop
        doc: Hoop the design was saved for.
      - id: design_extents
        type: extents
        doc: |
          Distances from the design origin (start point) to each edge of
          the design, in 0.1 mm units. Premier+ and JEF+ use other orders
          (see the README).
      - id: hoop_fits
        type: extents
        repeat: expr
        repeat-expr: 4
        doc: |
          Distance from each design edge to the matching hoop edge, in
          0.1 mm units, for four hoops: 110 × 110, 50 × 50, 140 × 200 and
          140 × 200 again (Unverified: the fourth may be a custom hoop).
          All four values are -1 when the design does not fit. Producers
          differ in the order (see the README).
  extents:
    doc: Four distances in 0.1 mm units, in Janome's order.
    seq:
      - id: left
        type: s4
        doc: Left (−X) side.
      - id: top
        type: s4
        doc: Top (+Y) side.
      - id: right
        type: s4
        doc: Right (+X) side.
      - id: bottom
        type: s4
        doc: Bottom (−Y) side.
  stitch_record:
    doc: |
      Either a stitch (2 bytes: signed dx, dy) or a command (0x80, the
      command code, then signed dx, dy for every command except end).
    seq:
      - id: byte0
        type: u1
        doc: 0x80 for a command; otherwise dx as a signed byte.
      - id: byte1
        type: u1
        doc: Command code after 0x80; otherwise dy as a signed byte.
      - id: command_dx
        type: s1
        if: is_command and byte1 != 0x10
        doc: Relative X move of a command, in 0.1 mm units.
      - id: command_dy
        type: s1
        if: is_command and byte1 != 0x10
        doc: Relative Y move of a command, in 0.1 mm units, positive up.
    instances:
      is_command:
        value: byte0 == 0x80
        doc: Escape byte; the record is a command.
      command:
        value: byte1
        enum: command
        if: is_command
        doc: Command code.
      dx:
        value: >-
          is_end ? 0 : (is_command ? command_dx :
          (byte0 >= 0x80 ? byte0 - 0x100 : byte0))
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: >-
          is_end ? 0 : (is_command ? command_dy :
          (byte1 >= 0x80 ? byte1 - 0x100 : byte1))
        doc: |
          Relative Y move in 0.1 mm units, positive up (screen
          coordinates need the sign flipped).
      is_end:
        value: is_command and byte1 == 0x10
        doc: End of stitch data. No move bytes follow.
      is_jump:
        value: is_command and byte1 == 0x02
        doc: Move without stitching.
      is_color_change:
        value: is_command and byte1 == 0x01
        doc: Change to the next color. The move is 0, 0 in the samples.
      is_stitch:
        value: not is_command
        doc: Normal stitch.
enums:
  command:
    0x01: color_change
    0x02: jump
    0x10: end
  hoop:
    0: hoop_110x110
    1: hoop_50x50
    2: hoop_140x200
    3: hoop_126x110
    4: hoop_200x200
