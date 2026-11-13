meta:
  id: brother_phb
  title: Brother PHB embroidery format
  file-extension: phb
  license: MIT
  endian: le
  imports:
    - ../brother_pec/brother_pec
doc: |
  Brother embroidery format that starts with `#PHB` and a version, and
  embeds PEC stitch records (see brother_pec). Other readers locate the
  data by chaining three length fields from fixed offsets: a color list at
  0x71, then three nested sections, then a small color table and the stitch
  records. Unverified: no redistributable sample was available; everything
  here follows the skip logic of other readers, not observed files. The
  middle sections and the header before 0x52 are not understood.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/brother_phb
seq:
  - id: magic
    contents: "#PHB"
  - id: version
    type: str
    size: 4
    encoding: ASCII
    doc: |
      Unverified: ASCII digits, "0003" according to a comment in another
      reader.
instances:
  num_color_indices:
    pos: 0x71
    type: u2
    doc: Number of colors in `color_indices`.
  color_indices:
    pos: 0x73
    type: u1
    repeat: expr
    repeat-expr: num_color_indices
    doc: |
      Index per color into Brother's fixed PEC thread palette (not part of
      this spec). Unverified: the readers wrap indices past the palette end.
  section_a_size:
    pos: 0x54
    type: u4
    doc: |
      Unverified: size field; section A starts at 0x52 + this value. The
      four bytes at 0x52 are unknown.
  section_a_pos:
    value: 0x52 + section_a_size
    doc: Offset of the second length field (`section_b_size`).
  section_b_size:
    pos: section_a_pos
    type: u4
    doc: "Unverified: length of a section of unknown content."
  section_b_pos:
    value: section_a_pos + section_b_size + 2
    doc: Offset of the third length field (`section_c_size`).
  section_c_size:
    pos: section_b_pos
    type: u4
    doc: "Unverified: length of a section of unknown content."
  section_c_pos:
    value: section_b_pos + section_c_size
    doc: |
      Unverified: offset of the block that holds the second color count, 14
      bytes before it.
  num_colors_2:
    pos: section_c_pos + 14
    type: u1
    doc: |
      Unverified: second color count, followed by that many bytes (not
      decoded by other readers), then 20 more unknown bytes.
  stitches_pos:
    value: section_c_pos + 15 + num_colors_2 + 0x15
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
