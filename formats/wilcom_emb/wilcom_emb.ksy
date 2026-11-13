meta:
  id: wilcom_emb
  title: Wilcom EMB embroidery format
  file-extension: emb
  license: MIT
  endian: le
  imports:
    - ../_common/cfb
doc: |
  Wilcom EMB (partial): a Compound File Binary container (see
  `_common/cfb`) holding a few named streams. This spec reads the
  container and directory, the Wilcom design-information property set (its
  property names are stored in the file itself), the JPEG preview and the
  zlib-compressed `Contents` stream as raw bytes. The stitch and object
  data inside `Contents` and `DesignDocument` is not decoded.

  Only streams of 4096 bytes or more are reachable: smaller ones live in
  the container's mini stream, which is fragmented and needs sector-chain
  following that Kaitai Struct cannot express. In the samples that excludes
  AUX_INFO, SummaryInformation, DESIGN_ICON (a zlib-compressed 100x100 BMP)
  and, depending on the file, Contents and TRUEVIEW_ICON. Their directory
  entries are still read.

  Streams are located by directory index, which was the same in all 15
  sample files (0 root, 1 AUX_INFO, 2 Contents, 3 DesignDocument,
  4 SummaryInformation, 5 WilcomDesignInformationDDD, 6 DESIGN_ICON,
  7 TRUEVIEW_ICON); each entry exposes its name so a reader can check it.
  Unverified: other Wilcom versions may use another order, and streams are
  assumed to occupy consecutive sectors.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/wilcom_emb
seq:
  - id: container
    type: cfb
    doc: Compound file header and directory.
instances:
  entries:
    value: container.directory_sector_0.entries
    doc: Directory entries 0..3 (root, AUX_INFO, Contents, DesignDocument).
  entries_next:
    value: container.directory_sector_1.entries
    if: container.has_directory_sector_1
    doc: |
      Directory entries 4..7 (SummaryInformation,
      WilcomDesignInformationDDD, DESIGN_ICON, TRUEVIEW_ICON).
  contents_entry:
    value: entries[2]
    doc: Directory entry 2, named "Contents".
  design_document_entry:
    value: entries[3]
    doc: Directory entry 3, named "DesignDocument".
  design_information_entry:
    value: entries_next[1]
    doc: "Directory entry 5, named WilcomDesignInformationDDD (prefixed by U+0005)."
  trueview_icon_entry:
    value: entries_next[3]
    doc: Directory entry 7, named "TRUEVIEW_ICON".
  contents:
    io: _root._io
    pos: contents_entry.stream_pos
    size: contents_entry.stream_size
    type: zlib_stream
    if: not contents_entry.is_mini
    doc: |
      The Contents stream after zlib decompression: stitch and object data
      in an unknown layout. Only when it is 4096 bytes or more.
  design_document:
    io: _root._io
    pos: design_document_entry.stream_pos
    size: design_document_entry.stream_size
    if: not design_document_entry.is_mini
    doc: |
      Raw DesignDocument stream. Unverified: not zlib; the bytes look
      random (compressed or enciphered), the layout is unknown.
  design_information:
    io: _root._io
    pos: design_information_entry.stream_pos
    size: design_information_entry.stream_size
    type: property_set
    if: not design_information_entry.is_mini
    doc: |
      Wilcom design information: an OLE property set with its own format
      id, whose dictionary names each property ("number of colours",
      "number of stitches", "design width", ...).
  trueview_icon:
    io: _root._io
    pos: trueview_icon_entry.stream_pos
    size: trueview_icon_entry.stream_size
    type: jpeg_stream
    if: not trueview_icon_entry.is_mini
    doc: "Larger preview image: a JPEG (JFIF) file, when 4096 bytes or more."
types:
  zlib_stream:
    seq:
      - id: uncompressed_size
        type: u4
        doc: Size of the decompressed data in bytes.
      - id: data
        size-eos: true
        process: zlib
        doc: Decompressed data.
    instances:
      num_data_bytes:
        value: data.size
        doc: Length of `data`; equal to `uncompressed_size` in the samples.
  jpeg_stream:
    seq:
      - id: uncompressed_size
        type: u4
        doc: Size of the decompressed JPEG file in bytes.
      - id: jpeg
        type: jpeg_file
        size-eos: true
        process: zlib
        doc: The JPEG file.
  jpeg_file:
    seq:
      - id: soi
        contents: [0xff, 0xd8, 0xff]
        doc: Start of image marker and the first byte of the next marker.
      - id: data
        size-eos: true
        doc: Rest of the JPEG file (segments and entropy-coded data).
  property_set:
    doc: |
      OLE property set stream ([MS-OLEPS]): a header, then one section with
      a table of (property id, offset) and typed values. Offsets are
      relative to the section start. Only the first section is read.
    seq:
      - id: byte_order
        type: u2
        doc: Byte order mark, 0xfffe.
      - id: version
        type: u2
        doc: Property set version (0).
      - id: os_version
        type: u4
        doc: Creating system version (0x00020106 in the samples).
      - id: clsid
        size: 16
        doc: Class id of the creator.
      - id: num_sections
        type: u4
        doc: Number of sections (1 in the samples).
      - id: format_id
        size: 16
        doc: |
          Format id (GUID) of the first section: the standard
          SummaryInformation id, or Wilcom's own for design information.
      - id: section_offset
        type: u4
        doc: Offset of the first section from the start of the stream.
    instances:
      section:
        pos: section_offset
        type: section(section_offset)
        doc: The first section.
  section:
    params:
      - id: section_offset
        type: u4
    seq:
      - id: size
        type: u4
        doc: Section size in bytes.
      - id: num_properties
        type: u4
        doc: Number of properties.
      - id: properties
        type: property_entry(section_offset)
        repeat: expr
        repeat-expr: num_properties
        doc: Property table.
    instances:
      dictionary:
        pos: section_offset + properties.last.offset
        type: dictionary
        if: properties.last.id == 0
        doc: |
          Property name dictionary (property id 0), present when the last
          table entry has id 0 as in the samples. Unverified: the
          dictionary may sit elsewhere in other files.
  property_entry:
    params:
      - id: section_offset
        type: u4
    seq:
      - id: id
        type: u4
        doc: Property id; 0 is the dictionary.
      - id: offset
        type: u4
        doc: Offset of the value from the section start.
    instances:
      value:
        pos: section_offset + offset
        type: typed_value
        if: id != 0
        doc: The property value.
  typed_value:
    seq:
      - id: variant_type
        type: u2
        enum: variant_type
        doc: Value type.
      - id: padding
        size: 2
        doc: Padding.
      - id: value
        type:
          switch-on: variant_type
          cases:
            variant_type::int16: s2
            variant_type::int32: s4
            variant_type::float64: f8
            variant_type::lpstr: lpstr
            variant_type::filetime: u8
            variant_type::blob: blob
        doc: |
          Value; absent for types not listed (including the empty type).
    enums:
      variant_type:
        1: empty
        2: int16
        3: int32
        5: float64
        0x1e: lpstr
        0x40: filetime
        0x41: blob
  lpstr:
    seq:
      - id: len
        type: u4
        doc: Length in bytes including the terminator.
      - id: text
        size: len
        type: strz
        encoding: ASCII
        doc: Text in the property set's code page (1252 in the samples).
  blob:
    seq:
      - id: len_data
        type: u4
        doc: Length of the data in bytes.
      - id: data
        size: len_data
        doc: Raw data.
  dictionary:
    seq:
      - id: num_entries
        type: u4
        doc: Number of names.
      - id: entries
        type: dictionary_entry
        repeat: expr
        repeat-expr: num_entries
        doc: Property names.
  dictionary_entry:
    seq:
      - id: property_id
        type: u4
        doc: Property id the name belongs to.
      - id: len
        type: u4
        doc: Length of the name in bytes including the terminator.
      - id: name
        size: len
        type: strz
        encoding: ASCII
        doc: Property name.
