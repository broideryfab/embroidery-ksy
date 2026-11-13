meta:
  id: eltac_exy
  title: Eltac EXY embroidery format
  file-extension: exy
  license: MIT
  imports:
    - ../tajima_dst/tajima_dst
doc: |
  Eltac EXY: a 256-byte header followed by Tajima-style 3-byte records (each
  axis encoded as balanced powers of three, command bits in the third byte).
  Unverified: no redistributable .exy sample was available; the layout
  follows other readers' description only. Nothing is known about the
  header contents, and the command bits may differ slightly from Tajima DST
  (see README).
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/eltac_exy
seq:
  - id: header
    size: 256
    doc: |
      Unverified: 256 bytes that no reader interprets; contents unknown.
  - id: records
    type: tajima_dst::stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record (third byte 0xf3), or to
      end of file. The DST record type is reused; its `is_*` flags follow
      DST semantics. Unverified: a trailing partial record would make
      parsing fail.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
