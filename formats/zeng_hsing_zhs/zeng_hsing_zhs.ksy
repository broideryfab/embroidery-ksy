meta:
  id: zeng_hsing_zhs
  title: Zeng Hsing ZHS embroidery format
  file-extension: zhs
  license: MIT
doc: |
  Zeng Hsing ZHS: a 15-byte prefix, two offsets (to the stitch data and to a
  color table), a color table with RGB colors and a text block of thread
  descriptions, and 3-byte stitch records whose X and Y deltas are spread
  over two bytes bit by bit. Unverified: no redistributable .zhs sample was
  available; the layout follows other readers' description only.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/zeng_hsing_zhs
seq:
  - id: unknown_0x00
    size: 15
    doc: |
      Unverified: not interpreted by any reader; contents unknown.
  - id: stitch_start_position
    type: u4le
    doc: Absolute file offset of the first stitch record.
  - id: header_start_position
    type: u4le
    doc: Absolute file offset of the color table.
instances:
  color_table:
    pos: header_start_position
    type: color_table
    doc: Color table and thread text.
  stitches:
    pos: stitch_start_position
    type: stitch_records
    doc: Stitch records.
types:
  color_table:
    seq:
      - id: num_colors
        type: u1
        doc: Number of colors.
      - id: colors
        type: rgb
        repeat: expr
        repeat-expr: num_colors
        doc: Thread colors.
      - id: thread_text_length
        type: u2le
        doc: Length of `thread_text` in bytes.
      - id: thread_text
        type: str
        size: thread_text_length
        encoding: UTF-8
        doc: |
          Unverified: thread descriptions. One reader splits it on "&$" into
          one entry per color (ignoring the text before the first "&$"),
          each entry split on "&#" into chart, description and catalog
          number (the catalog number minus its last two characters).
  rgb:
    seq:
      - id: red
        type: u1
        doc: Red.
      - id: green
        type: u1
        doc: Green.
      - id: blue
        type: u1
        doc: Blue (the color is read as a 24-bit big-endian value).
  stitch_records:
    seq:
      - id: records
        type: record
        repeat: until
        repeat-until: _.is_end or _io.eof
        doc: |
          Records up to and including the end record (control 0x80), or to
          end of file. Unverified: a trailing partial record would make
          parsing fail.
  record:
    doc: |
      Unverified: one 3-byte record. X and Y are each 8-bit signed values
      whose bits alternate between `byte1` and `byte2`.
    seq:
      - id: control
        type: u1
        doc: |
          Command: 0x02 stitch, 0x01 jump (move), 0x04 color change, 0x80
          end, 0x10 checksum record (to be ignored), 0x41 unknown. A reader
          sums the deltas of records with other controls into the next
          stitch, jump or color change.
      - id: byte1
        type: u1
        doc: Bits 0, 2, 4, 6 are bits of X; bits 1, 3, 5, 7 are bits of Y.
      - id: byte2
        type: u1
        doc: Bits 1, 3, 5, 7 are bits of X; bits 0, 2, 4, 6 are bits of Y.
    instances:
      x_raw:
        value: (byte1 & 0x55) | (byte2 & 0xaa)
        doc: X bits interleaved from both bytes, as an unsigned byte.
      y_raw:
        value: (byte2 & 0x55) | (byte1 & 0xaa)
        doc: Y bits interleaved from both bytes, as an unsigned byte.
      x_signed:
        value: 'x_raw >= 128 ? x_raw - 256 : x_raw'
        doc: X as a signed 8-bit value.
      y_signed:
        value: 'y_raw >= 128 ? y_raw - 256 : y_raw'
        doc: Y as a signed 8-bit value.
      dx:
        value: 'x_signed >= 63 ? x_signed + 1 : (x_signed <= -63 ? x_signed - 1 : x_signed)'
        doc: |
          Relative X move after a correction other readers apply: values
          from 63 up and from -63 down are moved one unit away from zero.
          Unit unknown (0.1 mm?). Positive is to the right.
      dy:
        value: 'y_signed >= 63 ? y_signed + 1 : (y_signed <= -63 ? y_signed - 1 : y_signed)'
        doc: |
          Relative Y move, same correction as `dx`. Positive is up
          (Unverified).
      is_checksum:
        value: control == 0x10
        doc: Checksum record; skipped by readers.
      is_stitch:
        value: control == 0x02
        doc: Stitch.
      is_jump:
        value: control == 0x01
        doc: Move without stitching.
      is_color_change:
        value: control == 0x04
        doc: Color change.
      is_end:
        value: control == 0x80
        doc: End of stitch data.
