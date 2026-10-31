meta:
  id: brother_pes
  title: Brother PES embroidery format
  file-extension: pes
  license: MIT
  endian: le
  imports:
    - ../brother_pec/brother_pec
doc: |
  Brother / Baby Lock design format, the most common home-machine format.
  `#PES` and a 4-digit version are followed by the offset of the PEC block
  and a version-dependent header (hoop size, design name, thread table in
  v5/v6). Then come serialized design objects (`CEmbOne`, `CSewSeg`) used
  by PE-Design, and at `pec_offset` a PEC block (see `brother_pec`) with the
  stitches machines read. This spec parses the header of versions 0001,
  0020, 0030, 0040, 0050 and 0060, the start of the object list, and the
  PEC block; the objects themselves and other versions are kept as raw
  bytes.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/brother_pes
seq:
  - id: magic
    contents: "#PES"
  - id: version
    type: str
    size: 4
    encoding: ASCII
    doc: |
      Version as 4 decimal digits: "0001", "0020", "0030", "0040", "0050",
      "0060" (parsed), "0090", "0100" (Premier+, header not parsed).
  - id: pec_offset
    type: u4
    doc: Absolute file offset of the PEC block.
  - id: header
    type:
      switch-on: version
      cases:
        '"0001"': header_v1
        '"0020"': header_v2
        '"0030"': header_v3
        '"0040"': header_v4
        '"0050"': header_v5
        '"0060"': header_v6
    if: is_known_version
    doc: Version-dependent header. Absent for other versions.
  - id: object_list
    type: object_list_head
    if: is_known_version
    doc: Start of the serialized design objects.
  - id: body
    size: pec_offset - _io.pos
    doc: |
      Rest of the PES section up to the PEC block: the design objects after
      the first class name (not specified yet) or, for versions this spec
      does not parse, everything from byte 12 (after `pec_offset`).
instances:
  is_known_version:
    value: >-
      version == "0001" or version == "0020" or version == "0030"
      or version == "0040" or version == "0050" or version == "0060"
    doc: True for the versions whose header this spec parses.
  pec_block:
    pos: pec_offset
    size-eos: true
    type: brother_pec::pec_block
    doc: |
      The PEC block, to end of file. In v4–v6 and Premier+ files the block's
      `thumbnails.trailer` also holds data written after the PEC
      thumbnails.
types:
  header_v1:
    doc: Version 0001 (Brother PE-Design v1, Wilcom, ew, pyembroidery).
    seq:
      - id: hoop_size_code
        type: u2
        doc: |
          Unverified: 0 = 100 × 100 mm, 1 = 130 × 180 mm. Wilcom writes 0
          for the designs it puts in a 100 × 100 hoop in v4 and 1 for
          `scene` (130 × 180 in v4); Brother, ew and pyembroidery write 1.
      - id: unknown_0x0e
        type: u2
        doc: Unknown. 1 in every sample.
  header_v2:
    doc: Version 0020 (Brother PE-Design v2, Premier+ v2).
    seq:
      - id: hoop_width
        type: u2
        doc: Hoop width in mm.
      - id: hoop_height
        type: u2
        doc: Hoop height in mm.
      - id: unknown_0x10
        type: u2
        doc: Unknown. 0 in every sample.
      - id: settings
        type: settings
      - id: unknown_0x20
        type: u2
        doc: Unknown. 0 in every sample.
  header_v3:
    doc: Version 0030 (Brother PE-Design v3). Version 0020 plus two leading fields.
    seq:
      - id: hoop_size_code
        type: u2
        doc: "Unverified: same as in version 0001. 1 in every sample."
      - id: unknown_0x0e
        type: u2
        doc: Unknown. 1 in every sample.
      - id: hoop_width
        type: u2
        doc: Hoop width in mm.
      - id: hoop_height
        type: u2
        doc: Hoop height in mm.
      - id: unknown_0x14
        type: u2
        doc: Unknown. 0 in every sample.
      - id: settings
        type: settings
      - id: unknown_0x24
        type: u2
        doc: Unknown. 0 in every sample.
  header_v4:
    doc: Version 0040 (Brother PE-Design v4, Wilcom, Premier+ v4).
    seq:
      - id: design_info
        type: design_info
      - id: unknown_flag
        type: u2
        doc: Unknown. 1 for Brother, 0 for Wilcom and Premier+.
      - id: hoop_width
        type: u2
        doc: Hoop width in mm.
      - id: hoop_height
        type: u2
        doc: Hoop height in mm.
      - id: unknown_after_hoop
        type: u2
        doc: Unknown. 0 in every sample.
      - id: settings
        type: settings
      - id: reserved
        size: 6
        doc: Zero in every sample.
  header_v5:
    doc: Version 0050 (Brother PE-Design v5, Wilcom). Adds a transform and a thread table.
    seq:
      - id: design_info
        type: design_info
      - id: unknown_flag
        type: u2
        doc: Unknown. 1 for Brother, 0 for Wilcom.
      - id: hoop_width
        type: u2
        doc: Hoop width in mm.
      - id: hoop_height
        type: u2
        doc: Hoop height in mm.
      - id: unknown_after_hoop
        type: u2
        doc: Unknown. 0 in every sample.
      - id: settings
        type: settings
      - id: reserved_1
        size: 3
        doc: Zero in every sample.
      - id: transform
        type: f4
        repeat: expr
        repeat-expr: 6
        doc: |
          Unverified: 2D affine transform, [1, 0, 0, 1, 0, 0] (identity) in
          every sample. The same six floats appear in the `CEmbOne` objects.
      - id: reserved_2
        size: 6
        doc: Zero in every sample.
      - id: num_threads
        type: u2
        doc: Number of entries in `threads`.
      - id: threads
        type: thread
        repeat: expr
        repeat-expr: num_threads
        doc: |
          Thread table. Wilcom, Premier+ and My Editor list one entry per
          color block; Brother lists each thread once (9 entries for the
          10 color blocks of `random1`, whose PEC palette repeats index 10).
  header_v6:
    doc: Version 0060 (Brother PE-Design v6, Wilcom, Premier+ v6, My Editor).
    seq:
      - id: design_info
        type: design_info
      - id: unknown_flag
        type: u2
        doc: Unknown. 1 for Brother and Premier+, 0 for Wilcom and My Editor.
      - id: unknown_after_flag
        type: u2
        doc: Unknown. 0 in every sample.
      - id: hoop_width
        type: u2
        doc: Hoop width in mm.
      - id: hoop_height
        type: u2
        doc: Hoop height in mm.
      - id: unknown_after_hoop
        type: u2
        doc: Unknown. 0 in every sample.
      - id: unknown_sizes
        type: u2
        repeat: expr
        repeat-expr: 5
        doc: Unknown. 200, 200, 100, 100, 100 in every sample.
      - id: settings
        type: settings
      - id: reserved_1
        size: 3
        doc: Zero in every sample.
      - id: transform
        type: f4
        repeat: expr
        repeat-expr: 6
        doc: "Unverified: 2D affine transform, identity in every sample (see version 0050)."
      - id: reserved_2
        size: 6
        doc: Zero in every sample.
      - id: num_threads
        type: u2
        doc: Number of entries in `threads`.
      - id: threads
        type: thread
        repeat: expr
        repeat-expr: num_threads
        doc: Thread table, as in version 0050.
  design_info:
    doc: Start of the header in versions 0040–0060.
    seq:
      - id: unknown_0x0c
        type: u2
        doc: Unknown. 1 in every sample.
      - id: subversion
        type: str
        size: 2
        encoding: ASCII
        doc: |
          Unverified: two ASCII digits, "01" in every sample except Wilcom
          v6 ("02").
      - id: design_name
        type: pstring
        doc: Design name. Only Wilcom fills it (the file name without extension).
      - id: unknown_strings
        type: pstring
        repeat: expr
        repeat-expr: 4
        doc: Unknown. Four more strings, empty in every sample.
  settings:
    doc: |
      Seven u2 values found after the hoop size in versions 0020–0060.
      Meanings unknown; the per-producer values are listed in the README.
    seq:
      - id: unknown_0x00
        type: u2
        doc: Unknown. 7 in every sample.
      - id: unknown_0x02
        type: u2
        doc: Unknown. 19 in every sample.
      - id: unknown_0x04
        type: u2
        doc: Unknown. Brother 1, Premier+ 0, Wilcom 1, My Editor 0.
      - id: unknown_0x06
        type: u2
        doc: Unknown. Brother 1, Premier+ 1, Wilcom 1, My Editor 0.
      - id: unknown_0x08
        type: u2
        doc: Unknown. Brother 1, Premier+ 0, Wilcom 0, My Editor 0.
      - id: unknown_0x0a
        type: u2
        doc: Unknown. Brother 5, Premier+ 25, Wilcom 100, My Editor 100.
      - id: unknown_0x0c
        type: u2
        doc: Unknown. Brother 1, Premier+ 0, Wilcom 1, My Editor 1.
  thread:
    doc: One thread table entry (versions 0050 and 0060).
    seq:
      - id: catalog_number
        type: pstring
        doc: Thread catalog number as text ("817", "039").
      - id: red
        type: u1
        doc: Red component of the thread color.
      - id: green
        type: u1
        doc: Green component of the thread color.
      - id: blue
        type: u1
        doc: Blue component of the thread color.
      - id: unknown_0x03
        type: u1
        doc: Unknown. 0 in every sample.
      - id: thread_type
        type: u4
        doc: |
          Unverified: 10 for catalog threads; 2 for one black entry
          (catalog "101", empty name and brand) in Brother's spiralbox
          files.
      - id: name
        type: pstring
        doc: |
          Thread name. Brother writes the PEC palette index as text ("39"),
          My Editor a color name ("Gray"), Wilcom nothing.
      - id: brand
        type: pstring
        doc: Thread brand or chart ("EMBROIDERY" for Brother, "PES" for Wilcom).
      - id: unknown_string
        type: pstring
        doc: Unknown. Empty in every sample.
  pstring:
    doc: String with a 1-byte length prefix.
    seq:
      - id: len_value
        type: u1
        doc: Length of `value` in bytes.
      - id: value
        type: str
        size: len_value
        encoding: ISO-8859-1
        doc: "Unverified: encoding. Every sample is ASCII."
  object_list_head:
    doc: |
      Start of the serialized design objects that follow the header in
      every parsed version. The tags look like MFC `CArchive` object
      serialization (0xffff = new class, then schema, name length and class
      name); unverified.
    seq:
      - id: unknown_count
        type: u2
        doc: |
          Unverified: Brother PE-Design v1–v5 write the number of color
          blocks (10, 3 and 16 for the random1, scene and spiralbox
          designs); Brother v6 and every other producer write 1.
      - id: new_class_tag
        contents: [0xff, 0xff]
      - id: schema
        type: u2
        doc: "Unverified: class schema number. 0 in every sample."
      - id: len_class_name
        type: u2
        doc: Length of `class_name`.
      - id: class_name
        type: str
        size: len_class_name
        encoding: ASCII
        doc: Class of the first object, "CEmbOne" in every sample.
