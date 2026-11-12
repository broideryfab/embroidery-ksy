meta:
  id: husqvarna_shv
  title: Husqvarna Viking SHV embroidery format
  file-extension: shv
  license: MIT
  endian: be
doc: |
  Older Husqvarna Viking format. Big-endian. No magic: an 86-byte text
  banner, a length-prefixed design name, a 4-bit thumbnail, a table with one
  14-byte record per color, then uncompressed stitch records to the end of
  the file. Stitches are signed byte pairs in 0.1 mm; an 0x80 escape gives
  long moves and commands (the same scheme as VP3).
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/husqvarna_shv
seq:
  - id: banner
    size: 86
    type: str
    encoding: ASCII
    doc: |
      Text padded with spaces. Wings My Editor: "This Design was created with
      the Wings LTD's eXPirience(R) software."; Wilcom: "This is an SHV format
      embroidery file: please view the thumbnail image for more detail".
  - id: len_name
    type: u1
    doc: Length of `name` in bytes.
  - id: name
    size: len_name
    type: str
    encoding: ASCII
    doc: Design name. Wilcom cuts it to 8 characters; Wings My Editor writes the file name stem.
  - id: thumbnail_width
    type: u1
    doc: Thumbnail width in pixels.
  - id: thumbnail_height
    type: u1
    doc: Thumbnail height in pixels.
  - id: thumbnail_half_sizes
    size: 4
    doc: |
      Unverified: four bytes, half of the thumbnail width and height written
      twice (47.5 and 48.5 rounded to `30 31 30 31` for 95 x 97; `2f 30 2f 30`
      for Wilcom's thumbnail).
  - id: thumbnail
    size: ((thumbnail_height + 1) / 2) * thumbnail_width
    doc: |
      Thumbnail pixels, ceil(height / 2) * width bytes. Unverified: two 4-bit
      pixels per byte (the size is confirmed by the position of the next field).
  - id: num_colors
    type: u1
    doc: Number of color records.
  - id: unknown_after_num_colors
    size: 6
    doc: Unknown. `c4 28 00 30 00 00` in all samples except scene-me (`c4 28 00 50 00 00`).
  - id: extent_max_x
    type: s2
    doc: |
      Wilcom: design extent, largest X, 0.1 mm (same as in the HUS file).
      Unverified for Wings My Editor, which writes other values.
  - id: extent_max_y
    type: s2
    doc: "Wilcom: largest Y, 0.1 mm. Unverified for Wings My Editor."
  - id: extent_min_x
    type: s2
    doc: "Wilcom: smallest X, 0.1 mm. Unverified for Wings My Editor."
  - id: extent_min_y
    type: s2
    doc: "Wilcom: smallest Y, 0.1 mm. Unverified for Wings My Editor."
  - id: unknown_total
    type: u4
    doc: |
      Wilcom: the sum of the colors' `num_records`. Wings My Editor writes
      other values (41 for random1, 100 for spiralbox).
  - id: colors
    type: color
    repeat: expr
    repeat-expr: num_colors
  - id: stitches
    type: stitch_record
    repeat: eos
    doc: Stitch records to the end of the file.
types:
  color:
    doc: One 14-byte color record.
    seq:
      - id: num_records
        type: u4
        doc: |
          Number of two-byte units of stitch data belonging to this color; a
          long move (3 units) counts 3. Summed over the colors this equals the
          number of two-byte units in `stitches` in Wilcom files; Wings My
          Editor files do not match (+2 in random1, -1 in spiralbox).
      - id: thread_index
        type: u1
        doc: "Palette index of the thread. Unverified: the palette is not included here."
      - id: unknown_flag
        type: u1
        doc: Unknown. 0 in Wilcom files, 2 in Wings My Editor files.
      - id: unknown_0x02
        type: u4
        doc: Unknown. Zero in Wilcom files; Wings My Editor writes varying values.
      - id: start_x
        type: s2
        doc: |
          Unverified: position where the color starts, 0.1 mm, Y down. The
          first color is (0, 0) in Wilcom files; later values equal the point
          the previous color ended at.
      - id: start_y
        type: s2
        doc: "Unverified: see `start_x`."
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
        doc: X move of a long move, 0.1 mm.
      - id: long_dy
        type: s2
        if: is_long_move
        doc: Y move of a long move, 0.1 mm, Y down.
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
      is_stitch:
        value: not is_command
        doc: Short stitch.
      dx:
        value: 'is_long_move ? long_dx : (is_command ? 0 : x)'
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: 'is_long_move ? long_dy : (is_command ? 0 : y)'
        doc: Relative Y move in 0.1 mm units, positive down.
enums:
  command:
    1: long_move
    2: long_move_end
    3: trim
