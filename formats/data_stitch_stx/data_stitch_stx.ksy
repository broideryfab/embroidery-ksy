meta:
  id: data_stitch_stx
  title: Data Stitch STX embroidery format
  file-extension: stx
  license: MIT
  endian: le
doc: |
  Data Stitch format. A "STX1.00" header holds the offsets of three blocks:
  a 16-entry color table (6-bit RGB), a block of 200 bytes of unknown
  meaning and the stitch data. The stitch data uses the same records as the
  Melco EXP format: 2-byte relative stitches and 0x80 escape records for
  jump, color change and trim. There is no end record.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/data_stitch_stx
seq:
  - id: magic
    contents: STX
    doc: '"STX".'
  - id: version
    type: strz
    encoding: ASCII
    doc: Version text, "1.00" in every sample.
  - id: unknown_0x08
    type: u4
    doc: |
      Unknown. 48 in every sample, which is the size of the color table in
      bytes (16 colors times 3), so it may be that.
  - id: colors_offset
    type: u4
    doc: Offset of the color table. 0x16a (362) in every sample.
  - id: unknown_block_offset
    type: u4
    doc: |
      Offset of the unknown block (pyembroidery calls it "dunno"). 0x19a
      (410) in every sample.
  - id: stitches_offset
    type: u4
    doc: Offset of the stitch data. 0x262 (610) in every sample.
  - id: reserved_0x18
    size: 8
    doc: Zero bytes. Unverified whether this is more header.
instances:
  num_colors:
    value: (unknown_block_offset - colors_offset) / 3
    doc: Number of color table entries (16 in every sample).
  colors:
    pos: colors_offset
    type: color
    repeat: expr
    repeat-expr: num_colors
    doc: |
      Color table. The same 16 colors in every sample (black, white, red,
      green, blue, yellow, cyan, magenta, orange, brown, ...), so it is
      probably a fixed palette, not the design's threads.
  unknown_block:
    pos: unknown_block_offset
    size: stitches_offset - unknown_block_offset
    doc: |
      Unknown, 200 bytes. Identical in every sample: big-endian 16-bit
      values 2, 3, ..., 15, then 1, 2, ..., 15 repeating, ending at 11.
      Unverified: it may be a per-color-change thread index table.
  records:
    pos: stitches_offset
    type: record
    repeat: eos
    doc: |
      Stitch records up to the end of the file. There is no end marker;
      the stream ends with the file. Same records as EXP.
types:
  color:
    seq:
      - id: red
        type: u1
        doc: Red, 0 to 63 (6 bits). Unverified channel order.
      - id: green
        type: u1
        doc: Green, 0 to 63.
      - id: blue
        type: u1
        doc: Blue, 0 to 63.
  record:
    doc: |
      If the first byte is not 0x80 the two bytes are the X and Y deltas of a
      stitch. Otherwise the second byte is a control and two more bytes are
      the X and Y deltas of the command (the same layout as Melco EXP).
    seq:
      - id: first_byte
        type: u1
        doc: X delta of a stitch, or 0x80 for an escape record.
      - id: second_byte
        type: u1
        doc: |
          Y delta of a stitch, or the control: 0x01 color change, 0x02
          stitch with an escape record, 0x04 jump (move), 0x80 trim. Only
          0x01, 0x04 and 0x80 appear in the samples.
      - id: escape_x
        type: s1
        if: is_escape
        doc: X delta of the escape record, 0.1 mm units.
      - id: escape_y
        type: s1
        if: is_escape
        doc: Y delta of the escape record, 0.1 mm units (Y up).
    instances:
      is_escape:
        value: first_byte == 0x80
        doc: Escape record (4 bytes).
      is_stitch:
        value: first_byte != 0x80
        doc: Plain stitch (2 bytes).
      dx:
        value: 'first_byte >= 0x80 ? first_byte - 0x100 : first_byte'
        if: is_stitch
        doc: X delta, 0.1 mm units. Positive is right.
      dy:
        value: 'second_byte >= 0x80 ? second_byte - 0x100 : second_byte'
        if: is_stitch
        doc: |
          Y delta, 0.1 mm units, as stored. Positive is up (pyembroidery
          negates it). Unverified.
      is_color_change:
        value: is_escape and second_byte == 0x01
        doc: Color change. Both deltas are 0 in the samples.
      is_jump:
        value: is_escape and second_byte == 0x04
        doc: Jump (move without stitching).
      is_trim:
        value: is_escape and second_byte == 0x80
        doc: Trim (control from Melco EXP; pyembroidery).
