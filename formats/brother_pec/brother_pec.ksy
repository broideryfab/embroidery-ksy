meta:
  id: brother_pec
  title: Brother PEC embroidery format
  file-extension: pec
  license: MIT
  endian: le
doc: |
  Brother stitch format, used standalone by older machines and embedded as
  the last block of every PES file. A standalone file is the magic
  `#PEC0001` followed by one PEC block. The block holds a 512-byte header
  (label, thumbnail size, palette indices into Brother's fixed thread
  palette), a 20-byte stitch header (graphics offset, design size, start
  point), variable-length stitch records (relative moves of 1 or 2 bytes per
  axis, color changes, end) and 1-bit thumbnails: one of the whole design,
  then one per color.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/brother_pec
seq:
  - id: magic
    contents: "#PEC0001"
  - id: pec_block
    type: pec_block
    size-eos: true
    doc: The PEC block, to end of file. PES files embed the same block.
types:
  pec_block:
    doc: |
      One PEC block. Offsets in this type are relative to the start of the
      block (byte 8 of a standalone file, `pec_offset` in a PES file).
    seq:
      - id: header
        type: header
        size: 0x200
        doc: Fixed-size header with label and palette.
      - id: stitch_header
        type: stitch_header
        doc: Graphics offset, design size and start point.
      - id: records
        type: stitch_record
        repeat: until
        repeat-until: _.is_end or _io.eof
        doc: |
          Stitch records up to and including the end record. Parsing also
          stops at the end of the block, for blocks without an end record.
    instances:
      num_records:
        value: records.size
        doc: Number of records, including color change and end records.
      thumbnails:
        pos: 0x200 + stitch_header.graphics_offset
        size-eos: true
        type: thumbnails
        doc: Thumbnails and any data after them, to the end of the block.
  header:
    doc: |
      512 bytes: label, thumbnail size and palette, padded with spaces.
    seq:
      - id: label_key
        contents: "LA:"
      - id: label
        type: str
        size: 16
        encoding: ISO-8859-1
        pad-right: 0x20
        doc: |
          Design name, space-padded. Brother PE-Design truncates it to 8
          characters inside PES files; Premier+ writes a single arbitrary
          character.
      - id: label_cr
        contents: [0x0d]
      - id: unknown_0x14
        size: 11
        doc: Unknown. Spaces (0x20) in every sample.
      - id: unknown_0x1f
        type: u1
        doc: |
          Unknown. 0xff in Brother PE-Design PES v5/v6 and in every
          Premier+ PES file; 0x20 in all other samples.
      - id: unknown_0x20
        type: u1
        doc: Unknown. 0xff in every sample.
      - id: unknown_0x21
        type: u1
        doc: Unknown. 0x00 in every sample.
      - id: thumbnail_byte_width
        type: u1
        doc: Thumbnail row size in bytes (6, i.e. 48 pixels).
      - id: thumbnail_height
        type: u1
        doc: Thumbnail height in pixels (38).
      - id: unknown_0x24
        size: 12
        doc: |
          Unknown. Spaces in every sample except Brother PE-Design PES
          files (all versions), which have `64 20 00 20 00` at offsets
          0x28..0x2c.
      - id: num_colors_minus_one
        type: u1
        doc: Number of colors minus one.
      - id: palette_indices
        type: u1
        repeat: expr
        repeat-expr: num_colors_minus_one + 1
        doc: |
          One index per color block, in stitching order, into Brother's
          fixed 64-entry PEC thread palette (not part of this spec). The
          same index may appear more than once.
      - id: padding
        size-eos: true
        doc: Spaces (0x20) up to 512 bytes.
    instances:
      num_colors:
        value: num_colors_minus_one + 1
        doc: Number of color blocks.
  stitch_header:
    doc: 20 bytes at block offset 0x200, right before the stitch records.
    seq:
      - id: unknown_0x00
        type: u2
        doc: Unknown. 0 in every sample.
      - id: graphics_offset_low
        type: u2
        doc: Low 16 bits of `graphics_offset`.
      - id: graphics_offset_high
        type: u1
        doc: High 8 bits of `graphics_offset`.
      - id: unknown_0x05
        type: u1
        doc: Unknown. 0x31 in every sample.
      - id: unknown_0x06
        type: u2
        doc: Unknown. Bytes ff f0 in every sample.
      - id: width
        type: u2
        doc: Design width in 0.1 mm units.
      - id: height
        type: u2
        doc: Design height in 0.1 mm units.
      - id: unknown_0x0c
        type: u2
        doc: Unknown. 480 in every sample.
      - id: unknown_0x0e
        type: u2
        doc: Unknown. 432 in every sample.
      - id: start_x_raw
        type: u2be
        doc: |
          Big-endian; high nibble 0x9 in every sample, low 12 bits give
          `start_x`.
      - id: start_y_raw
        type: u2be
        doc: Big-endian; Y counterpart of `start_x_raw`.
    instances:
      graphics_offset:
        value: graphics_offset_low | (graphics_offset_high << 16)
        doc: |
          Offset of the thumbnails, relative to the start of this stitch
          header (block offset 0x200). Points right after the end record in
          every sample.
      start_x:
        value: start_x_raw & 0x0fff
        doc: |
          Distance from the left edge of the design to the first position,
          in 0.1 mm units. My Editor and Premier+ v10 center a hoop-sized
          box instead (half of `width`).
      start_y:
        value: start_y_raw & 0x0fff
        doc: Distance from the top edge of the design to the first position.
  stitch_record:
    doc: |
      One record: a move, a color change (fe b0 xx) or the end (ff). A move
      has an X then a Y value. Each value is 1 byte (7-bit signed, -64..63)
      when its high bit is clear, or 2 bytes when it is set: flags in bits
      6..4 of the first byte (0x20 trim, 0x10 jump) and a 12-bit signed
      value (-2048..2047) in the low 4 bits of the first byte and the
      second byte, big-endian.
    seq:
      - id: x_byte0
        type: u1
        doc: First X byte, or 0xfe (color change), or 0xff (end).
      - id: color_change_code
        type: u1
        if: is_color_change
        doc: 0xb0 in every sample.
      - id: color_change_toggle
        type: u1
        if: is_color_change
        doc: |
          Alternates 2, 1, 2, … over the color changes of a file in every
          sample.
      - id: x_byte1
        type: u1
        if: is_x_long
        doc: Second X byte (low 8 bits of the 12-bit value).
      - id: y_byte0
        type: u1
        if: is_move
        doc: First Y byte.
      - id: y_byte1
        type: u1
        if: is_move and (y_byte0 & 0x80) != 0
        doc: Second Y byte (low 8 bits of the 12-bit value).
    instances:
      is_end:
        value: x_byte0 == 0xff
        doc: End of stitch data.
      is_color_change:
        value: x_byte0 == 0xfe
        doc: Change to the next color (next entry of `palette_indices`).
      is_move:
        value: not is_end and not is_color_change
        doc: Record carries a dx/dy move.
      is_x_long:
        value: is_move and (x_byte0 & 0x80) != 0
        doc: X uses the 2-byte form.
      is_y_long:
        value: is_move and (y_byte0 & 0x80) != 0
        doc: Y uses the 2-byte form.
      dx:
        value: >-
          is_move
          ? (is_x_long
            ? (((x_byte0 & 0x08) != 0)
              ? ((((x_byte0 & 0x0f) << 8) | x_byte1) - 0x1000)
              : (((x_byte0 & 0x0f) << 8) | x_byte1))
            : (((x_byte0 & 0x40) != 0) ? x_byte0 - 0x80 : x_byte0))
          : 0
        doc: Relative X move in 0.1 mm units, positive to the right. 0 unless `is_move`.
      dy:
        value: >-
          is_move
          ? (is_y_long
            ? (((y_byte0 & 0x08) != 0)
              ? ((((y_byte0 & 0x0f) << 8) | y_byte1) - 0x1000)
              : (((y_byte0 & 0x0f) << 8) | y_byte1))
            : (((y_byte0 & 0x40) != 0) ? y_byte0 - 0x80 : y_byte0))
          : 0
        doc: |
          Relative Y move in 0.1 mm units, positive down (screen
          coordinates). 0 unless `is_move`.
      is_jump:
        value: >-
          (is_x_long and (x_byte0 & 0x10) != 0)
          or (is_y_long and (y_byte0 & 0x10) != 0)
        doc: Move without stitching. Producers set the flag on both axes.
      is_trim:
        value: >-
          (is_x_long and (x_byte0 & 0x20) != 0)
          or (is_y_long and (y_byte0 & 0x20) != 0)
        doc: Trim. Producers set the flag on both axes.
      is_stitch:
        value: is_move and not is_jump and not is_trim
        doc: Normal stitch.
  thumbnails:
    doc: |
      Monochrome thumbnails, 1 bit per pixel, least significant bit first
      (leftmost pixel), `thumbnail_byte_width` bytes per row. The first
      image shows the whole design, then one per color. Premier+ writes
      only the first image. PES v4–v6 and Premier+ files have more data
      after the images, kept in `trailer`.
    seq:
      - id: images
        size: _parent.header.thumbnail_byte_width * _parent.header.thumbnail_height
        repeat: expr
        repeat-expr: num_images
        doc: Raw images, top row first.
      - id: trailer
        size-eos: true
        doc: |
          Bytes after the images. Empty in standalone files except My
          Editor (one 0x00); in PES v5/v6 it starts with a second copy of
          the color count and palette (unknown).
    instances:
      image_size:
        value: _parent.header.thumbnail_byte_width * _parent.header.thumbnail_height
        doc: Size of one image in bytes (228).
      num_images:
        value: >-
          (_parent.header.num_colors + 1) * image_size <= _io.size
          ? _parent.header.num_colors + 1
          : _io.size / image_size
        doc: |
          Number of images: one per color plus one, or as many as fit when
          the producer wrote fewer (Premier+).
