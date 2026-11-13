meta:
  id: bits_volts_bro
  title: Bits & Volts BRO embroidery format
  file-extension: bro
  license: MIT
  endian: le
doc: |
  Bits & Volts (Bits and Volts, "BroderBits") format. A 256-byte header
  (magic 55 01, design name, record count, extents, color count) is followed
  by a stream of variable-length records: a 2-byte relative stitch, or an
  escape (0x80) record with a control byte that selects a start position, a
  wide (16-bit) move, a needle change or the end of the stream.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/bits_volts_bro
seq:
  - id: header
    type: header
    size: 0x100
    doc: Fixed-size 256-byte header.
  - id: records
    type: record
    repeat: until
    repeat-until: _.stops_stream or _io.eof
    doc: |
      Records up to and including the end record. Parsing also stops at an
      unknown control byte (as pyembroidery does) and at end of file.
  - id: trailer
    size-eos: true
    doc: |
      Bytes after the end record: 7e 00 00 00 00 in every sample.
      Unverified: may be a final command with a zero move.
types:
  header:
    seq:
      - id: magic
        contents: [0x55, 0x01]
        doc: 55 01 in every sample.
      - id: reserved_0x02
        type: u1
        doc: Always 0.
      - id: design_name
        type: strz
        size: 9
        encoding: ASCII
        doc: |
          Design name, NUL-terminated, truncated to 8 characters (Wilcom
          writes an 8.3 style name, for example "scene-wi" from
          "scene-wilcom").
      - id: record_count
        type: u4
        doc: |
          Number of records after the header, not counting the end record
          (checked against all 9 samples).
      - id: height
        type: u2
        doc: |
          Design height in 0.1 mm units. Unverified: matches the vertical
          extent of random1 and random3; random2 differs by a few units.
      - id: width
        type: u2
        doc: |
          Design width in 0.1 mm units. Unverified, see `height`.
      - id: color_count
        type: u2
        doc: |
          Number of colors: the number of needle change records plus one.
      - id: reserved_0x16
        size: 14
        doc: Zero bytes (0x16 to 0x23).
      - id: unknown_0x24
        type: u2
        doc: Unknown. 0x0020 in every sample.
      - id: unknown_0x26
        type: s2
        doc: |
          Unknown. Looks like a position: in random1-wilcom-a.BRO it is
          (-80, -28), half of the first record's position (-159, -56), but
          other samples do not follow this.
      - id: unknown_0x28
        type: s2
        doc: Unknown. Second half of the pair started at 0x26.
      - id: reserved_0x2a
        size: 214
        doc: Zero bytes up to 0x100.
  record:
    doc: |
      A record starts with two bytes. If the first is not 0x80 they are the
      X and Y deltas of one stitch (signed bytes, 0.1 mm units). If the first
      is 0x80 the second byte (0x01 in all records except the end record,
      where it is 0x02; Unverified) is followed by a control byte, and for
      some controls by two signed 16-bit values.
    seq:
      - id: first_byte
        type: u1
        doc: X delta of a stitch, or 0x80 for an escape record.
      - id: second_byte
        type: u1
        doc: Y delta of a stitch, or the escape sub-code (0x01 or 0x02).
      - id: control
        type: u1
        if: is_escape
        doc: |
          0x00 start position, 0x02 end, 0x03 move with 16-bit delta, 0x7e
          move (same layout as 0x03; not in the samples), 0xe0 end, 0xe1 to
          0xef needle change (needle 1 to 15) followed by a move.
      - id: wide_x
        type: s2
        if: has_wide_move
        doc: X, signed 16-bit, 0.1 mm units.
      - id: wide_y
        type: s2
        if: has_wide_move
        doc: Y, signed 16-bit, 0.1 mm units.
    instances:
      is_escape:
        value: first_byte == 0x80
        doc: Escape record (not a plain stitch).
      has_wide_move:
        value: >-
          is_escape and (control == 0x00 or control == 0x03 or
          control == 0x7e or (control >= 0xe1 and control <= 0xef))
        doc: Record carries two 16-bit values.
      is_end:
        value: is_escape and (control == 0x02 or control == 0xe0)
        doc: End of the stream.
      is_known_control:
        value: >-
          is_escape and (control == 0x00 or control == 0x02 or
          control == 0x03 or control == 0x7e or control == 0xe0 or
          (control >= 0xe1 and control <= 0xef))
        doc: Control byte seen in a reader or sample.
      stops_stream:
        value: is_escape and (is_end or not is_known_control)
        doc: End record or a control byte nobody knows.
      is_stitch:
        value: not is_escape
        doc: Plain relative stitch.
      is_start_position:
        value: is_escape and control == 0x00
        doc: |
          Position of the first point, as a move from the origin. Unverified:
          pyembroidery ignores the two values after it and reads them as
          stitches; in random1-wilcom-a.BRO they equal the first stitch of the
          design (-159, 56 after Y negation) in the pyembroidery dump
          random1.txt.
      is_wide_move:
        value: is_escape and (control == 0x03 or control == 0x7e)
        doc: |
          Relative move with 16-bit deltas. pyembroidery reads these as moves;
          in the samples they hold the long stitches of random1 to random3.
      is_needle_change:
        value: is_escape and control >= 0xe1 and control <= 0xef
        doc: Needle change followed by a 16-bit move.
      needle:
        value: control - 0xe0
        if: is_needle_change
        doc: Needle number (1 to 15).
      dx:
        value: 'first_byte >= 0x80 ? first_byte - 0x100 : first_byte'
        if: is_stitch
        doc: |
          X delta of a stitch, 0.1 mm units. Positive is right.
      dy:
        value: 'second_byte >= 0x80 ? second_byte - 0x100 : second_byte'
        if: is_stitch
        doc: |
          Y delta of a stitch, 0.1 mm units, as stored. Positive is up:
          pyembroidery negates it to get its screen convention. Unverified.
