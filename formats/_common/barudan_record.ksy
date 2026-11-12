meta:
  id: barudan_record
  title: Barudan 3-byte stitch record
  license: MIT
doc: |
  One 3-byte stitch record shared by the Barudan U01/U00, DSB and DAT
  formats: a control byte followed by the Y and X magnitudes. The control
  byte holds the sign of each axis and a command code. Moves are in 0.1 mm
  units, at most 127 per axis.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/barudan_u01
seq:
  - id: ctrl
    type: u1
    doc: |
      Control byte. Bit 7 is set in every record of the samples. Bit 6: the
      Y move is negative (Y up). Bit 5: the X move is negative. Bits 4..0:
      command code (see `command`).
  - id: dy_magnitude
    type: u1
    doc: Absolute Y move in 0.1 mm units; the sign is bit 6 of `ctrl`.
  - id: dx_magnitude
    type: u1
    doc: Absolute X move in 0.1 mm units; the sign is bit 5 of `ctrl`.
instances:
  marker_bit:
    value: (ctrl & 0x80) != 0
    doc: |
      Bit 7 of `ctrl`. Set in every record of the samples, including the
      end record. Unverified: its meaning; a reader that sees it clear may
      be looking at another .dat format.
  command:
    value: ctrl & 0x1f
    enum: command
    doc: Command code, bits 4..0 of `ctrl`.
  dx:
    value: '(ctrl & 0x20) != 0 ? -dx_magnitude : dx_magnitude'
    doc: |
      Signed X move in 0.1 mm units, positive to the right. For stitches
      and jumps this is the move; for other commands it is 0 in every
      sample. Unverified: whether a non-zero pair on those commands is a
      move.
  dy:
    value: '(ctrl & 0x40) != 0 ? -dy_magnitude : dy_magnitude'
    doc: |
      Signed Y move in 0.1 mm units, positive up (screen coordinates need
      the sign flipped). Same rules as `dx`.
  is_stitch:
    value: command == command::stitch or command == command::fast_stitch or command == command::slow_stitch
    doc: Stitch, optionally with a speed change (codes 0, 2, 4).
  is_jump:
    value: command == command::jump or command == command::fast_jump or command == command::slow_jump
    doc: Move without stitching, optionally with a speed change (codes 1, 3, 5).
  is_trim:
    value: command == command::trim_top or command == command::trim_bobbin
    doc: Thread trim (codes 6 and 7).
  is_stop:
    value: command == command::stop
    doc: Machine stop (code 8).
  is_needle_change:
    value: ctrl_command >= 9 and ctrl_command <= 23
    doc: Select needle 1..15 (codes 9..23).
  needle:
    value: ctrl_command - 8
    if: is_needle_change
    doc: Needle number, 1..15.
  is_end:
    value: command == command::end
    doc: End of design (code 24).
  ctrl_command:
    value: ctrl & 0x1f
    doc: Numeric command code, bits 4..0 of `ctrl`.
enums:
  command:
    0: stitch
    1: jump
    2: fast_stitch
    3: fast_jump
    4: slow_stitch
    5: slow_jump
    6: trim_top
    7: trim_bobbin
    8: stop
    9: needle_1
    10: needle_2
    11: needle_3
    12: needle_4
    13: needle_5
    14: needle_6
    15: needle_7
    16: needle_8
    17: needle_9
    18: needle_10
    19: needle_11
    20: needle_12
    21: needle_13
    22: needle_14
    23: needle_15
    24: end
