meta:
  id: husqvarna_vip
  title: Husqvarna Viking / Pfaff VIP embroidery format
  file-extension: vip
  license: MIT
  endian: le
doc: |
  Older Husqvarna Viking / Pfaff format. Little-endian. The header matches
  HUS up to offset 0x2a, then comes an obfuscated color table (4 bytes per
  color), per-color u4 values and a UTF-16LE name. Stitch data is stored as in
  HUS: three compressed blocks (commands, X, Y), one byte per stitch record,
  using the same compression (see the README). This spec exposes the blocks as
  raw bytes and does not decompress or de-obfuscate anything.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/husqvarna_vip
seq:
  - id: magic
    contents: [0x5d, 0xfc, 0x90, 0x01]
    doc: File signature, u4 0x0190fc5d.
  - id: num_stitches
    type: u4
    doc: Number of stitch records, the length of each decompressed block, including the final `end` record.
  - id: num_colors
    type: u4
    doc: Number of colors.
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
  - id: ofs_attributes
    type: u4
    doc: Absolute file offset of the compressed command ("attribute") block.
  - id: ofs_x
    type: u4
    doc: Absolute file offset of the compressed X block; the command block ends here.
  - id: ofs_y
    type: u4
    doc: Absolute file offset of the compressed Y block; the X block ends here.
  - id: unknown_0x20
    size: 8
    doc: Unknown. Zero in every sample.
  - id: unknown_0x28
    size: 2
    doc: |
      Unknown. `00 00` in Premier+ and Wilcom files; Wings My Editor writes
      the same value as in its HUS file of the same design.
  - id: unknown_color_section_length
    type: u4
    doc: |
      Unverified: equals 8 * `num_colors` + 46 in every sample. It is not the
      distance to `ofs_attributes`.
  - id: encoded_colors
    size: num_colors * 4
    doc: |
      Obfuscated colors, 4 bytes each. Other readers decode byte i as
      `encoded[i] xor key[i] xor encoded[i-1]` with a fixed 400-byte key
      (the key is not reproduced here); the result is red, green, blue and a
      zero byte.
  - id: unknown_color_values
    type: u4
    repeat: expr
    repeat-expr: num_colors
    doc: Unknown, one per color. 8 in Premier+ files, 1 in Wings My Editor and Wilcom files.
  - id: len_name
    type: u4
    doc: Length of `name` in UTF-16 code units, including the terminating NUL.
  - id: name
    size: len_name * 2
    type: str
    encoding: UTF-16LE
    doc: |
      Design name: "Settings:" (Premier+), the file name without extension
      (Wilcom), or empty (Wings My Editor; just a NUL).
instances:
  attributes_compressed:
    pos: ofs_attributes
    size: ofs_x - ofs_attributes
    doc: Compressed command block. Decompresses to `num_stitches` command bytes (see `command`).
  x_compressed:
    pos: ofs_x
    size: ofs_y - ofs_x
    doc: Compressed X block. Decompresses to `num_stitches` signed bytes, 0.1 mm.
  y_compressed:
    pos: ofs_y
    size-eos: true
    doc: Compressed Y block, to the end of the file. Decompresses to `num_stitches` signed bytes, 0.1 mm, Y up.
enums:
  command:
    0x80: stitch
    0x81: jump
    0x84: color_change
    0x88: trim
    0x90: end
