meta:
  id: brother_phc
  title: Brother PHC embroidery format
  file-extension: phc
  license: MIT
  endian: le
  imports:
    - ../brother_pec/brother_pec
doc: |
  Brother embroidery format that starts with `#PHC` and a version digit,
  with PEC-style thumbnails and PEC stitch records (see brother_pec). The
  color list sits at 0x4f; the stitch data is found through offsets at
  0x2b and 0x30 and two length-prefixed sections. Unverified: no
  redistributable sample was available; everything here follows the skip
  logic of other readers, not observed files, and two readers disagree
  about the last skip (see the README).
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/brother_phc
seq:
  - id: magic
    contents: "#PHC"
  - id: version
    type: str
    size: 4
    encoding: ASCII
    doc: "Unverified: ASCII digits; the last one is the version number."
instances:
  pre_graphics_size:
    pos: 0x2b
    type: u1
    doc: |
      Unverified: size of the header part that follows the copyright text;
      added to `pec_offset`.
  graphics_end_size:
    pos: 0x2c
    type: u4
    doc: "Unverified: called graphics end size and file length by two readers."
  pec_offset:
    pos: 0x30
    type: u2
    doc: "Unverified: base offset of the first section (`section_a_size`)."
  thumbnail_height:
    pos: 0x4a
    type: u1
    doc: Thumbnail height in pixels.
  thumbnail_byte_width:
    pos: 0x4c
    type: u1
    doc: Thumbnail row size in bytes.
  num_color_indices:
    pos: 0x4d
    type: u2
    doc: Number of colors in `color_indices`.
  color_indices:
    pos: 0x4f
    type: u1
    repeat: expr
    repeat-expr: num_color_indices
    doc: |
      Index per color into Brother's fixed PEC thread palette (not part of
      this spec).
  thumbnails_pos:
    value: 0x4f + num_color_indices
    doc: |
      Unverified: offset of the first thumbnail. One reader reads
      `num_color_indices` images of `thumbnail_byte_width * thumbnail_height`
      bytes here (the thumbnails are not decoded by this spec).
  section_a_pos:
    value: pec_offset + pre_graphics_size
    doc: Offset of `section_a_size`.
  section_a_size:
    pos: section_a_pos
    type: u2
    doc: "Unverified: length of a section of unknown content that follows."
  section_b_pos:
    value: section_a_pos + 2 + section_a_size
    doc: Offset of `section_b_size`.
  section_b_size:
    pos: section_b_pos
    type: u4
    doc: "Unverified: length of a section of unknown content that follows."
  section_c_pos:
    value: section_b_pos + 4 + section_b_size + 10
    doc: |
      Unverified: offset of the second color count (10 bytes of unknown
      data lie between the end of section B and it).
  num_colors_2:
    pos: section_c_pos
    type: u1
    doc: "Unverified: second color count."
  stitches_pos:
    value: section_c_pos + 1 + num_colors_2 + 0x1d
    doc: Offset of the first stitch record.
  records:
    pos: stitches_pos
    type: brother_pec::stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Unverified: PEC stitch records up to and including the end record,
      or to end of file. Same records as in brother_pec.
  num_records:
    value: records.size
    doc: Number of records, including color change and end records.
