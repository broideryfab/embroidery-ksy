meta:
  id: brother_pen
  title: Brother PEN stitch stream (Skitch / PP1)
  file-extension: pen
  license: MIT
  endian: le
doc: |
  Stitch stream that a Brother Skitch (PP1) receives over Bluetooth. It has
  no header: the stream is a sequence of 4-byte records, each an absolute
  needle position in 0.1 mm units and a few flag bits, ending with a record
  that carries the data-end flag. Colors, thread names and hoop size are not
  part of the stream.

  Unverified: whether `.pen` files on disk, as Brother's own software
  writes them, have the same layout or add a header. The layout here is the
  one sent to the machine.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/brother_pen
seq:
  - id: records
    type: record
    repeat: until
    repeat-until: _.is_data_end or _io.eof
    doc: |
      Records up to and including the one with the data-end flag. Parsing
      also stops at end of file, for streams that have no data-end record.
  - id: trailer
    size-eos: true
    doc: Bytes after the data-end record. Empty in a well-formed stream.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the data-end record.
enums:
  x_flag:
    0: none
    3: color_end
    5: data_end
types:
  record:
    doc: |
      One needle position. Both 16-bit words keep the coordinate in the
      upper 13 bits (signed, two's complement) and a flag value in the low
      3 bits.
    seq:
      - id: x_word
        type: s2
        doc: X coordinate shifted left by 3, with the X flag in the low 3 bits.
      - id: y_word
        type: s2
        doc: Y coordinate shifted left by 3, with the Y flag bits in the low 3 bits.
    instances:
      x:
        value: x_word / 8
        doc: |
          X position in 0.1 mm units, absolute (not relative to the previous
          record). Signed.
      y:
        value: y_word / 8
        doc: Y position in 0.1 mm units, absolute. Signed (floor division, so negative values stay exact).
      x_flag_value:
        value: x_word & 7
        doc: Low 3 bits of the X word; see `x_flag` for the known values.
      x_flag:
        value: x_flag_value
        enum: x_flag
        doc: |
          Record kind from the X word: 0 plain, 3 last record of a color
          block (the machine waits for a thread change), 5 last record of
          the pattern. Other values are not known.
      y_flags:
        value: y_word & 7
        doc: Low 3 bits of the Y word, a bit set; see `is_feed` and `is_cut`.
      is_feed:
        value: (y_word & 1) != 0
        doc: Bit 0 of the Y word. Move without stitching.
      is_cut:
        value: (y_word & 2) != 0
        doc: Bit 1 of the Y word. Cut the thread.
      is_color_end:
        value: x_flag_value == 3
        doc: Last record of a color block.
      is_data_end:
        value: x_flag_value == 5
        doc: Last record of the pattern.
