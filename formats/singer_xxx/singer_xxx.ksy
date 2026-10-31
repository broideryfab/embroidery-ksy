meta:
  id: singer_xxx
  title: Singer XXX embroidery format
  file-extension: xxx
  license: MIT
  endian: le
doc: |
  Singer home-machine stitch format. A 256-byte binary header (stitch count,
  color count, extents) is followed by a variable-length stitch stream:
  2-byte relative stitches of up to ±124 units (0.1 mm) per axis, 4-byte
  commands introduced by 0x7f (jump, color change, trim, end), and 5-byte
  long moves introduced by 0x7d (stitch) or 0x7e (jump). After the end
  record comes a 96-byte section with a 22-slot RGB palette. Some producers
  write more bytes after it.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/singer_xxx
seq:
  - id: header
    type: header
    size: 0x100
    doc: Fixed-size binary header.
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Stitch records up to and including the end record. Parsing also stops
      at end of file, for files that have no end record.
  - id: color_section
    type: color_section
    if: not _io.eof
    doc: Palette section after the end record. All zero in the "-c" variant.
  - id: extra
    size-eos: true
    doc: |
      Bytes after the color section. Empty in the Wilcom and My Editor
      samples; Premier+ writes 1777 more bytes, mostly zero.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  header:
    doc: |
      Little-endian binary fields at fixed offsets; everything else is zero
      in every sample.
    seq:
      - id: unknown_0x00
        size: 0x17
        doc: Unknown. Zero in every sample.
      - id: stitch_count
        type: u4
        doc: |
          Record count. Wilcom and Premier+ count every record except the
          end record; My Editor counts the end record too.
      - id: unknown_0x1b
        size: 0x0c
        doc: Unknown. Zero in every sample.
      - id: color_count
        type: u2
        doc: |
          Number of colors (color change records + 1). Premier+ writes 0.
      - id: unknown_0x29
        size: 4
        doc: |
          Unknown. Zero in every sample; may be the high half of a 32-bit
          `color_count`.
      - id: width
        type: u2
        doc: Design width (largest minus smallest X reached), in 0.1 mm units.
      - id: height
        type: u2
        doc: Design height (largest minus smallest Y reached), in 0.1 mm units.
      - id: end_x
        type: s2
        doc: |
          X of the last record relative to the start point, in 0.1 mm units.
          Wilcom fills it; Premier+ and My Editor write 0.
      - id: end_y
        type: s2
        doc: Y counterpart of `end_x` (Y up).
      - id: start_x
        type: u2
        doc: |
          Distance from the smallest X reached to the start point, in
          0.1 mm units. Wilcom fills it; Premier+ and My Editor write 0.
      - id: start_y
        type: u2
        doc: |
          Distance from the smallest Y reached (Y up) to the start point, in
          0.1 mm units. Wilcom fills it; Premier+ and My Editor write 0.
      - id: unknown_0x39
        size: 0x42
        doc: Unknown. Zero in every sample.
      - id: unknown_0x7b
        type: u2
        doc: |
          Unverified: year of a date (2019 in the Wilcom samples, 0
          elsewhere).
      - id: unknown_0x7d
        type: u1
        doc: "Unverified: month of a date (7 in the Wilcom samples, 0 elsewhere)."
      - id: unknown_0x7e
        type: u1
        doc: "Unverified: day of a date (13 in the Wilcom samples, 0 elsewhere)."
      - id: unknown_0x7f
        size: 0x73
        doc: Unknown. Zero in every sample.
      - id: unknown_0xf2
        type: u2
        doc: Unknown. 0x20 in the Wilcom samples, 0 in Premier+ and My Editor.
      - id: unknown_0xf4
        size: 8
        doc: Unknown. Zero in every sample.
      - id: end_offset
        type: u4
        doc: |
          File offset of the end record. Premier+ and My Editor fill it;
          Wilcom writes 0.
  stitch_record:
    doc: |
      One stitch record, 2, 4 or 5 bytes long depending on the first byte:
      0x7f starts a 4-byte command, 0x7d / 0x7e a 5-byte long move, any
      other value a 2-byte stitch.
    seq:
      - id: byte0
        type: u1
        doc: |
          Record type, or the signed X move of a 2-byte stitch. Stitch moves
          therefore never use 0x7d..0x7f (125..127).
      - id: stitch_dy
        type: s1
        if: not is_command and not is_long
        doc: Y move of a 2-byte stitch, in 0.1 mm units.
      - id: command
        type: u1
        if: is_command
        doc: |
          Command code: 0x01 jump, 0x03 trim (unverified), 0x08 color
          change, 0x09..0x17 color change to needle `command - 8`, 0x7f or
          0x18 end.
      - id: command_dx
        type: s1
        if: is_command
        doc: |
          X move of a jump, in 0.1 mm units. 0 for color changes and trims
          in the samples; 0x02 / 0x03 for a 7f 7f end record.
      - id: command_dy
        type: s1
        if: is_command
        doc: |
          Y move of a jump, in 0.1 mm units. 0x14 for a 7f 7f end record.
      - id: long_dx
        type: s2
        if: is_long
        doc: X move of a long record, in 0.1 mm units.
      - id: long_dy
        type: s2
        if: is_long
        doc: Y move of a long record, in 0.1 mm units.
    instances:
      is_command:
        value: byte0 == 0x7f
        doc: 4-byte command record.
      is_long:
        value: byte0 == 0x7d or byte0 == 0x7e
        doc: 5-byte long move record.
      dx:
        value: >-
          is_long ? long_dx
          : (is_command ? (is_end ? 0 : command_dx)
          : (byte0 >= 0x80 ? byte0 - 0x100 : byte0))
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: >-
          is_long ? long_dy
          : (is_command ? (is_end ? 0 : command_dy)
          : stitch_dy)
        doc: |
          Relative Y move in 0.1 mm units, positive up (screen coordinates
          need the sign flipped).
      is_end:
        value: is_command and (command == 0x7f or command == 0x18)
        doc: |
          End of stitch data. 7f 7f 02 14 (Wilcom), 7f 7f 03 14 (Premier+,
          My Editor "-s") or 7f 18 00 00 (My Editor "-c"); the last two
          bytes are not a move.
      is_jump:
        value: (is_command and command == 0x01) or byte0 == 0x7e
        doc: |
          Move without stitching: a 7f 01 command or a 0x7e long move.
      is_stitch:
        value: not is_command and byte0 != 0x7e
        doc: Normal stitch, 2-byte or 0x7d long.
      is_color_change:
        value: is_command and command >= 0x08 and command <= 0x17
        doc: Color change (stop). 0x09..0x17 also name a needle.
      is_trim:
        value: is_command and command == 0x03
        doc: |
          Unverified: trim. One 7f 03 00 00 before the end record in the
          Premier+ sample.
      needle:
        value: >-
          is_command and command >= 0x09 and command <= 0x17
          ? command - 0x08 : 0
        doc: |
          Needle selected by a color change, 1-based; 0 when the record
          gives none (7f 08 or not a color change). My Editor "-c" files
          cycle through needles 2..9, then 1.
  color_section:
    doc: |
      Fixed 96-byte section after the end record: 2 zero bytes, 22 color
      slots, 2 more bytes.
    seq:
      - id: unknown_0x00
        size: 2
        doc: Unknown. Zero in every sample.
      - id: colors
        type: color
        repeat: expr
        repeat-expr: 22
        doc: |
          Color slots. Unverified: the first `header.color_count` hold the
          design colors in stitch order (Wilcom fills exactly that many).
          Wilcom leaves the rest 0 and puts white in the last slot; Premier+
          fills with f20000 and white; My Editor "-s" fills all 22 with
          colors; My Editor "-c" leaves all zero.
      - id: unknown_0x5a
        size: 2
        doc: |
          Unknown. 00 01 (Wilcom, Premier+), 00 36 (My Editor "-s"),
          00 00 (My Editor "-c").
  color:
    doc: One 4-byte palette slot, 00 RR GG BB.
    seq:
      - id: unknown_0x00
        type: u1
        doc: Unknown. Zero in every sample.
      - id: red
        type: u1
        doc: Red, 0..255.
      - id: green
        type: u1
        doc: Green, 0..255.
      - id: blue
        type: u1
        doc: Blue, 0..255.
