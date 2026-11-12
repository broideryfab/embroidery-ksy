meta:
  id: janome_sew
  title: Janome SEW embroidery format
  file-extension: sew
  license: MIT
  endian: le
doc: |
  Older Janome / Viking-family home-machine format (stitch data only). A
  little-endian color count and a list of Janome palette indices open the
  file, followed by a fixed-size header area (other per-color tables and a
  1-bit preview, mostly unverified) that always ends at file offset 0x1d78.
  From there come 2-byte stitch records: a signed X and Y move of up to
  ±127 units (0.1 mm), or the escape byte 0x80 followed by a command
  (color change, jump, end) and a 2-byte move. Files from some producers
  have no end record.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/janome_sew
seq:
  - id: num_color_indices
    type: u2
    doc: Number of colors.
  - id: color_indices
    type: u2
    repeat: expr
    repeat-expr: num_color_indices
    doc: |
      Janome thread palette index per color, in sewing order. The palette
      itself is not part of the file. Starts at offset 0x02 (see the README
      for what happens with more than 12 colors).
  - id: header_rest
    size: 0x1d78 - 2 - 2 * num_color_indices
    doc: |
      Rest of the fixed header area, up to the first stitch record at
      offset 0x1d78. Zero-padded color tables and the preview bitmap live
      here; see the instances `unknown_0x1a`, `unknown_0x32` and
      `unknown_0x4a` and the README. Files that use more than 12 colors
      overwrite the start of the second table.
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Stitch records up to and including the end record. Parsing also stops
      at end of file, for files that have no end record.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record if there is one.
  unknown_0x1a:
    io: _root._io
    pos: 0x1a
    type: u2
    repeat: expr
    repeat-expr: 12
    doc: |
      Unverified: second per-color table with 12 fixed slots. 7 in every
      My Editor, Premier+ and spiralbox sample and 8 in the Wilcom samples
      (compare `thread_types` in janome_jef). Overlaps the end of
      `color_indices` when num_color_indices is above 12.
  unknown_0x32:
    io: _root._io
    pos: 0x32
    type: u2
    repeat: expr
    repeat-expr: 12
    doc: |
      Unverified: third per-color table with 12 fixed slots. All 0 in My
      Editor files with few colors; other values (for example 0xd8f0) in
      other files. Meaning unknown.
  unknown_0x4a:
    io: _root._io
    pos: 0x4a
    type: u2
    doc: "Unverified: 0x2006 in every sample."
types:
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
        value: is_command and (byte1 == 0x02 or byte1 == 0x04)
        doc: |
          Move without stitching. Code 0x04 is treated like 0x02 by other
          readers; it does not occur in the samples.
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
    0x04: jump_alt
    0x10: end
