meta:
  id: husqvarna_hus
  title: Husqvarna Viking HUS embroidery format
  file-extension: hus
  license: MIT
  endian: le
doc: |
  Older Husqvarna Viking format. Little-endian. A 42-byte header (magic,
  counts, design extents, three block offsets) is followed by one u2 thread
  palette index per color and three compressed blocks: stitch commands,
  X moves and Y moves, each one byte per stitch record. The blocks use an
  LZ77 + Huffman scheme (see the README); this spec exposes them as raw
  bytes and does not decompress them. Decompressed, each block holds
  `num_stitches` bytes: a command byte (see `command`) and a signed byte
  each for dx and dy in 0.1 mm units.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/husqvarna_hus
seq:
  - id: magic
    contents: [0x5d, 0xfc, 0xc8, 0x00]
    doc: File signature, u4 0x00c8fc5d.
  - id: num_stitches
    type: u4
    doc: |
      Number of stitch records, the length of each decompressed block. Counts
      the final `end` command when the file has one.
  - id: num_thread_indexes
    type: u4
    doc: Number of colors; equals the number of color changes plus one.
  - id: extent_max_x
    type: s2
    doc: Design extent, largest X reached, 0.1 mm.
  - id: extent_max_y
    type: s2
    doc: Design extent, largest Y reached, 0.1 mm, in the Y direction of the stitch data.
  - id: extent_min_x
    type: s2
    doc: Design extent, smallest X reached (zero or negative), 0.1 mm.
  - id: extent_min_y
    type: s2
    doc: Design extent, smallest Y reached (zero or negative), 0.1 mm.
  - id: ofs_commands
    type: u4
    doc: Absolute file offset of the compressed command block.
  - id: ofs_x
    type: u4
    doc: Absolute file offset of the compressed X block; the command block ends here.
  - id: ofs_y
    type: u4
    doc: Absolute file offset of the compressed Y block; the X block ends here.
  - id: unknown_0x20
    size: 8
    doc: Unknown. Zero in every sample. Possibly a text field (read as an 8-byte string by other readers).
  - id: unknown_0x28
    size: 2
    doc: |
      Unknown. `00 00` in Premier+ and Wilcom files; Wings My Editor writes
      `00 e9`, `00 0b` or `00 22`, which differ per design.
  - id: thread_indexes
    type: u2
    repeat: expr
    repeat-expr: num_thread_indexes
    doc: |
      Thread palette index of each color, in stitch order. Indexes 0 to 28
      were seen; the meaning is a fixed Husqvarna palette not included here
      (Unverified: the palette).
instances:
  commands_compressed:
    pos: ofs_commands
    size: ofs_x - ofs_commands
    doc: Compressed command block. Decompresses to `num_stitches` command bytes.
  x_compressed:
    pos: ofs_x
    size: ofs_y - ofs_x
    doc: Compressed X block. Decompresses to `num_stitches` signed bytes, 0.1 mm.
  y_compressed:
    pos: ofs_y
    size-eos: true
    doc: |
      Compressed Y block, to the end of the file. Decompresses to
      `num_stitches` signed bytes, 0.1 mm, Y up (the sign of the screen
      direction is reversed, as in the extents).
enums:
  command:
    0x80: stitch
    0x81: jump
    0x84: color_change
    0x88: trim
    0x90: end
