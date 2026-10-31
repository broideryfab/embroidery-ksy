meta:
  id: melco_exp
  title: Melco EXP embroidery format
  file-extension: exp
  license: MIT
doc: |
  Common commercial format (Melco, also used by Bernina machines). Stitch
  data only; no header and no thread colors. The file is a stream of
  2-byte stitch records, each a signed relative move of up to ±127 units
  (0.1 mm) per axis. A first byte of 0x80 is an escape: the record is then
  4 bytes long and holds a command (color change, jump, trim) and its
  parameter pair. There is no end record; the stream ends at end of file.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/melco_exp
seq:
  - id: records
    type: record
    repeat: eos
    doc: Stitch and command records up to end of file.
instances:
  num_records:
    value: records.size
    doc: Number of records, stitch and command records together.
types:
  record:
    doc: |
      A stitch record (2 bytes: dx, dy) or, when the first byte is 0x80, a
      command record (4 bytes: 0x80, command, parameter x, parameter y).
    seq:
      - id: byte0
        type: u1
        doc: |
          0x80 = escape (command record). Otherwise the X move of a stitch,
          as a signed byte.
      - id: byte1
        type: u1
        doc: |
          Command code in a command record (see `command`). Otherwise the Y
          move of a stitch, as a signed byte.
      - id: param_x
        type: s1
        if: byte0 == 0x80
        doc: |
          First parameter byte of a command record. X move in 0.1 mm units
          for jumps; 0x00 for color changes and 0x07 for trims in the
          samples.
      - id: param_y
        type: s1
        if: byte0 == 0x80
        doc: |
          Second parameter byte of a command record. Y move in 0.1 mm units
          for jumps; 0x00 for color changes and trims in the samples.
    instances:
      is_command:
        value: byte0 == 0x80
        doc: Command record (escape byte 0x80 followed by a command code).
      command:
        value: byte1
        enum: command
        if: is_command
        doc: Command code; only present in command records.
      is_stitch:
        value: not is_command
        doc: Normal stitch.
      is_jump:
        value: is_command and (byte1 == 0x02 or byte1 == 0x04)
        doc: Move without stitching (command 0x02 or 0x04).
      is_color_change:
        value: is_command and byte1 == 0x01
        doc: Color change (stop).
      is_trim:
        value: is_command and byte1 == 0x80
        doc: Thread trim. Its parameter pair (07 00) is not a move.
      dx:
        value: >-
          is_trim ? 0
          : is_command ? param_x
          : byte0 >= 0x80 ? byte0 - 256 : byte0
        doc: |
          Relative X move in 0.1 mm units, positive to the right. For
          command records, the parameter pair; 0 for trims. Unverified: whether
          a color change applies its pair as a move (always 00 00 in the
          samples).
      dy:
        value: >-
          is_trim ? 0
          : is_command ? param_y
          : byte1 >= 0x80 ? byte1 - 256 : byte1
        doc: |
          Relative Y move in 0.1 mm units, positive up (screen coordinates
          need the sign flipped). Same rules as `dx` for command records.
enums:
  command:
    0x01: color_change
    0x02: move
    0x04: jump
    0x80: trim
