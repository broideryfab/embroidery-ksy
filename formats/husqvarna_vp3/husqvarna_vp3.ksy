meta:
  id: husqvarna_vp3
  title: Husqvarna Viking / Pfaff VP3 embroidery format
  file-extension: vp3
  license: MIT
  endian: be
doc: |
  Home-machine format of Husqvarna Viking and Pfaff (VSM Group). Big-endian.
  After the `%vsm%` magic and a producer string, the file is a tree of
  tagged blocks, each a 3-byte tag followed by a u4 body length: the file
  block holds design extents and the design block, the design block holds
  one block per color, and each color block holds its thread (RGB, catalog
  number, description, brand) and a stitch block. Stitches are signed byte
  pairs in 0.1 mm units, with an 0x80 escape for long moves and commands.
  Header positions and extents are in 0.001 mm units.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/husqvarna_vp3
seq:
  - id: magic
    contents: ["%vsm%", 0]
  - id: producer
    type: utf16_string
    doc: |
      Name of the writing software: "Produced by VSM Group AB" (Premier+),
      "Produced by WingsXP software" (My Editor), "Produced by     Software
      Ltd" (Wilcom).
  - id: file
    type: file_block
    doc: The rest of the file.
instances:
  design:
    value: file.body.design.body
    doc: Shortcut to the design block body.
  num_color_blocks:
    value: file.body.design.body.color_blocks.size
    doc: Number of color blocks.
types:
  utf16_string:
    doc: Length-prefixed UTF-16BE string.
    seq:
      - id: len_value
        type: u2
        doc: Length in bytes (twice the number of characters).
      - id: value
        type: str
        size: len_value
        encoding: UTF-16BE
  byte_string:
    doc: Length-prefixed 8-bit string.
    seq:
      - id: len_value
        type: u2
        doc: Length in bytes.
      - id: value
        type: str
        size: len_value
        encoding: ISO-8859-1
        doc: Unverified encoding; every sample is ASCII.
  file_block:
    doc: Outermost block; ends at the end of the file in every sample.
    seq:
      - id: tag
        contents: [0x00, 0x02, 0x00]
      - id: len_body
        type: u4
        doc: Length of `body` in bytes.
      - id: body
        type: file_body
        size: len_body
  file_body:
    seq:
      - id: comment
        type: utf16_string
        doc: |
          Unverified: free text. "Settings:" (Premier+), empty (My Editor,
          Wilcom).
      - id: extent_right
        type: s4
        doc: Largest X of the design, in 0.001 mm units.
      - id: extent_top
        type: s4
        doc: Largest Y of the design (Y up), in 0.001 mm units.
      - id: extent_left
        type: s4
        doc: Smallest X of the design, in 0.001 mm units.
      - id: extent_bottom
        type: s4
        doc: Smallest Y of the design (Y up), in 0.001 mm units.
      - id: unknown_stitch_count
        type: u4
        doc: |
          Unknown. Looks like a stitch or command count, but the producers
          disagree on what they count (see README).
      - id: num_colors
        type: u2
        doc: |
          Number of colors. Equals `design.num_color_blocks` in every
          sample.
      - id: unknown_after_num_colors
        size: 3
        doc: Unknown. 0c 00 01 in every sample.
      - id: design
        type: design_block
  design_block:
    seq:
      - id: tag
        contents: [0x00, 0x03, 0x00]
      - id: len_body
        type: u4
        doc: Length of `body` in bytes.
      - id: body
        type: design_body
        size: len_body
  design_body:
    seq:
      - id: center_x
        type: s4
        doc: |
          X of the design center, in 0.001 mm units. Premier+ and Wilcom
          write the middle of the file block extents; My Editor writes 0.
      - id: center_y
        type: s4
        doc: Y counterpart of `center_x` (Y up).
      - id: unknown_0x08
        size: 3
        doc: Unknown. 00 00 00 in every sample.
      - id: bounds_left
        type: s4
        doc: |
          Smallest X, relative to the center, in 0.001 mm units. Premier+
          and Wilcom write symmetric bounds (bounds_left = -bounds_right).
      - id: bounds_right
        type: s4
        doc: Largest X, relative to the center, in 0.001 mm units.
      - id: bounds_bottom
        type: s4
        doc: Smallest Y (Y up), relative to the center, in 0.001 mm units.
      - id: bounds_top
        type: s4
        doc: Largest Y (Y up), relative to the center, in 0.001 mm units.
      - id: width
        type: s4
        doc: bounds_right - bounds_left, in 0.001 mm units.
      - id: height
        type: s4
        doc: bounds_top - bounds_bottom, in 0.001 mm units.
      - id: settings
        type: utf16_string
        doc: |
          Unverified: free text. "Settings:" (Premier+), empty (My Editor,
          Wilcom).
      - id: unknown_after_settings
        size: 24
        doc: |
          Unknown. Identical in every sample:
          64 64 00 00 10 00 00 00 00 00 00 00 00 00 00 00 10 00 78 78 50 50 01 00.
      - id: producer
        type: utf16_string
        doc: Same text as the producer string at the start of the file.
      - id: num_color_blocks
        type: u2
        doc: Number of color blocks that follow.
      - id: color_blocks
        type: color_block
        repeat: expr
        repeat-expr: num_color_blocks
  color_block:
    seq:
      - id: tag
        contents: [0x00, 0x05, 0x00]
      - id: len_body
        type: u4
        doc: Length of `body` in bytes.
      - id: body
        type: color_body
        size: len_body
  color_body:
    seq:
      - id: start_x
        type: s4
        doc: |
          X where this block starts, relative to `design.center_x`, in 0.001 mm
          units. center + start of the first block is the position before
          the first record in the samples.
      - id: start_y
        type: s4
        doc: Y counterpart of `start_x` (Y up).
      - id: thread
        type: thread
      - id: end_offset_x
        type: s4
        doc: |
          X of the block's last position relative to `start_x`, in 0.001 mm
          units. Equals the sum of the stitch `dx` values times 100, and the
          next block's `start_x` minus this one, in every sample.
      - id: end_offset_y
        type: s4
        doc: |
          Y counterpart of `end_offset_x` (Y up): equals minus the sum of
          the stitch `dy` values times 100.
      - id: stitches
        type: stitch_block
      - id: unknown_last
        type: u1
        doc: Unknown. 0 in every sample.
  thread:
    doc: Thread used for one color block.
    seq:
      - id: num_colors
        type: u1
        doc: "Unverified: number of colors in the thread (1 in every sample)."
      - id: unknown_0x01
        type: u1
        doc: Unknown. 0 in every sample.
      - id: colors
        type: thread_color
        repeat: expr
        repeat-expr: num_colors
      - id: unknown_type
        type: u1
        doc: Unknown. 5 in every sample.
      - id: weight
        type: u1
        doc: "Unverified: thread weight. 40 in every sample."
      - id: catalog_number
        type: byte_string
        doc: Catalog number ("039" from Wilcom; empty from Premier+ and My Editor).
      - id: description
        type: byte_string
        doc: |
          Color name ("Gray" from My Editor), the color as "#rrggbb" text
          (Premier+), or empty (Wilcom).
      - id: brand
        type: byte_string
        doc: Thread brand ("PES" from Wilcom; empty from Premier+ and My Editor).
  thread_color:
    seq:
      - id: red
        type: u1
      - id: green
        type: u1
      - id: blue
        type: u1
      - id: unknown_0x03
        size: 3
        doc: Unknown. 00 00 00 in every sample.
    instances:
      rgb:
        value: (red << 16) | (green << 8) | blue
        doc: Color as 0xRRGGBB.
  stitch_block:
    seq:
      - id: tag
        contents: [0x00, 0x01, 0x00]
      - id: len_body
        type: u4
        doc: Length of `body` in bytes.
      - id: body
        type: stitch_body
        size: len_body
  stitch_body:
    seq:
      - id: unknown_0x00
        size: 3
        doc: Unknown. 0a f6 00 in every sample.
      - id: records
        type: stitch_record
        repeat: eos
  stitch_record:
    doc: |
      Two signed bytes (dx, dy) in 0.1 mm units, Y down. An x byte of 0x80
      marks a command, given by the y byte; command 1 is followed by a long
      move as two s2 values.
    seq:
      - id: x
        type: s1
        doc: X move, or -128 (0x80) for a command.
      - id: y
        type: s1
        doc: Y move, or the command code when `x` is -128.
      - id: long_dx
        type: s2
        if: is_long_move
        doc: X move of a long move, in 0.1 mm units.
      - id: long_dy
        type: s2
        if: is_long_move
        doc: Y move of a long move, in 0.1 mm units, Y down.
    instances:
      is_command:
        value: x == -128
        doc: Record is a command, not a short stitch.
      command:
        value: y
        enum: command
        if: is_command
        doc: Command code.
      is_long_move:
        value: is_command and y == 1
        doc: Long move with 16-bit deltas.
      is_trim:
        value: is_command and y == 3
        doc: "Unverified: trim."
      is_stitch:
        value: not is_command
        doc: Short stitch.
      dx:
        value: 'is_long_move ? long_dx : (is_command ? 0 : x)'
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: 'is_long_move ? long_dy : (is_command ? 0 : y)'
        doc: |
          Relative Y move in 0.1 mm units, positive down (the opposite of
          the header positions).
enums:
  command:
    1: long_move
    2: long_move_end
    3: trim
