meta:
  id: barudan_u01
  title: Barudan U01 / U00 embroidery format
  file-extension: [u01, u00]
  license: MIT
  endian: le
  imports:
    - ../_common/barudan_record
doc: |
  Barudan commercial-machine format. Stitch data and needle (color)
  selection; no thread colors. A 128-byte ASCII "0" fill and a 128-byte
  binary header (design extents, record count, last position) are followed
  by 3-byte records: a control byte with the axis signs and a command code,
  then the Y and X magnitudes. The stream ends with an end command (code
  24, 0xf8 or 0x98 in the samples).
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/barudan_u01
seq:
  - id: prefix
    size: 0x80
    doc: |
      128 bytes of ASCII "0" (0x30) in every sample. Unverified: whether
      it carries information on other machines or software.
  - id: header
    type: header
    size: 0x80
    doc: Binary header, padded with zeros to 128 bytes.
  - id: records
    type: barudan_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Stitch records up to and including the end record. Parsing also stops
      at end of file, for files that have no end record.
  - id: trailer
    size-eos: true
    doc: Bytes after the end record; empty in every sample.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  header:
    doc: |
      Little-endian header at offset 0x80. Coordinates have Y up. A header
      that is all zeros (no records) may exist; none was seen.
    seq:
      - id: extent_min_x
        type: s2
        doc: Smallest X reached, in 0.1 mm units, relative to the start point.
      - id: extent_min_y
        type: s2
        doc: Smallest Y reached (Y up), in 0.1 mm units.
      - id: extent_max_x
        type: s2
        doc: Largest X reached, in 0.1 mm units.
      - id: extent_max_y
        type: s2
        doc: Largest Y reached (Y up), in 0.1 mm units.
      - id: unknown_0x88
        type: u4
        doc: Unknown. 0 in every sample.
      - id: record_count
        type: u4
        doc: |
          Number of 3-byte records including the end record in Wilcom and
          My Editor files. pyembroidery-written files (`*.u01` without
          suffix) store one more than the records present.
      - id: last_x
        type: s2
        doc: |
          X of the last position, in 0.1 mm units. Wilcom and pyembroidery
          files equal the DSB `AX`/`AY` of the same design. My Editor
          files hold other values (345, 563 in scene-me) while its DSB
          has AX/AY +0; Unverified: what they mean.
      - id: last_y
        type: s2
        doc: Y counterpart of `last_x` (Y up).
      - id: reserved_0x94
        size-eos: true
        doc: Zero padding to the end of the 128-byte header.
