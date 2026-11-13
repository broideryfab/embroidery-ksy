meta:
  id: janome_jpx
  title: Janome JPX embroidery format
  file-extension: jpx
  license: MIT
  endian: le
doc: |
  Janome home-machine format. A fixed 0x3c-byte header gives the offset of
  the stitch data and the color count, then a list of 4-byte color indices.
  Stitch data uses the same 2-byte records as janome_sew and melco_exp: a
  signed X and Y move, or the escape byte 0x80 with a command (color
  change, jump, end) and a 2-byte move. Unverified: no redistributable
  sample was available; the layout follows another reader's description.
  The header fields not named here are unknown.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/janome_jpx
seq:
  - id: stitches_offset
    type: u4
    doc: File offset of the first stitch record.
  - id: unknown_0x04
    size: 0x1c
    doc: Unknown.
  - id: num_color_indices
    type: u4
    doc: Number of entries in `color_indices`.
  - id: unknown_0x24
    size: 0x18
    doc: Unknown.
  - id: color_indices
    type: u4
    repeat: expr
    repeat-expr: num_color_indices
    doc: |
      Janome thread palette index per color (the palette is not part of the
      file). Unverified: another reader treats them as opaque numbers.
instances:
  records:
    pos: stitches_offset
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Stitch records up to and including the end record, or to end of file.
      Unverified: a trailing single byte would make parsing fail.
  num_records:
    value: records.size
    doc: Number of records, including color change and end records.
types:
  stitch_record:
    doc: |
      Either a stitch (2 bytes: signed dx, dy) or a command (0x80, the
      command code, then signed dx, dy; the end command also carries them).
      A stitch whose dx is -128 cannot be told from a command.
    seq:
      - id: byte0
        type: u1
        doc: 0x80 for a command; otherwise dx as a signed byte.
      - id: byte1
        type: u1
        doc: Command code after 0x80; otherwise dy as a signed byte.
      - id: command_dx
        type: s1
        if: is_command
        doc: Relative X move of a command, in 0.1 mm units.
      - id: command_dy
        type: s1
        if: is_command
        doc: Relative Y move of a command, in 0.1 mm units.
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
          is_command ? command_dx : (byte0 >= 0x80 ? byte0 - 0x100 : byte0)
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: >-
          is_command
          ? command_dy
          : (byte1 >= 0x80 ? byte1 - 0x100 : byte1)
        doc: |
          Relative Y move in 0.1 mm units. Unverified: positive up (another
          reader negates it for y-down output).
      is_end:
        value: is_command and byte1 == 0x10
        doc: End of stitch data.
      is_jump:
        value: is_command and byte1 == 0x02
        doc: Move without stitching.
      is_color_change:
        value: is_command and byte1 == 0x01
        doc: Change to the next color.
      is_stitch:
        value: not is_command
        doc: Normal stitch.
enums:
  command:
    0x01: color_change
    0x02: jump
    0x10: end
