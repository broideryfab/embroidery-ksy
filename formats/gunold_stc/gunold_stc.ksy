meta:
  id: gunold_stc
  title: Gunold STC embroidery format
  file-extension: stc
  license: MIT
doc: |
  Gunold STC: a 40-byte header followed by 3-byte records (signed X, signed
  Y, command). Unverified: no redistributable .stc sample was available; the
  layout follows other readers' description only.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/gunold_stc
seq:
  - id: header
    size: 40
    doc: |
      Unverified: 40 bytes that no reader interprets. A reader's comment
      suggests text of the form "DESIGN: xxxxxx STITCHES: xxxx", not
      confirmed; kept as raw bytes.
  - id: records
    type: record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record (command 25), or to end of
      file. Unverified: a trailing partial record would make parsing fail.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  record:
    doc: |
      Unverified: one 3-byte record.
    seq:
      - id: dx
        type: s1
        doc: Relative X move, positive to the right. Unit unknown (0.1 mm?).
      - id: dy
        type: s1
        doc: Relative Y move, positive up. Unit unknown (0.1 mm?).
      - id: command
        type: u1
        doc: |
          0 move (jump), 1 stitch, 25 end, any other value a needle change
          to needle `command - 2`.
    instances:
      is_jump:
        value: command == 0
        doc: Move without stitching.
      is_stitch:
        value: command == 1
        doc: Normal stitch.
      is_end:
        value: command == 25
        doc: End of stitch data.
      is_needle_change:
        value: command >= 2 and command != 25
        doc: Needle (color) change.
      needle_index:
        value: command - 2
        doc: Needle number for a needle change, from 0.
