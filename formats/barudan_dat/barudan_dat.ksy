meta:
  id: barudan_dat
  title: Barudan DAT embroidery format
  file-extension: dat
  license: MIT
  imports:
    - ../_common/barudan_record
doc: |
  Barudan DAT: a headerless stream of 3-byte Barudan records (control byte
  with axis signs and command, Y magnitude, X magnitude), the same records
  as in U01 and DSB. Unverified: no redistributable Barudan .dat sample was
  available; the layout follows other readers' description only. The .dat
  extension is shared with Sunstar DAT, which has a 256-byte header and
  different records; a Barudan file is recognized by bit 7 being set in the
  first control byte.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/barudan_dat
seq:
  - id: records
    type: barudan_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record (code 24), or to end of
      file. Unverified: a trailing partial record would make parsing fail.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
