meta:
  id: pfaff_spx
  title: Pfaff SPX embroidery format
  file-extension: spx
  license: MIT
  endian: be
doc: |
  Pfaff SPX: a 0x11E-byte header followed by 9-byte records, each with two
  signed 16-bit big-endian deltas. Unverified: no redistributable sample was
  available; the layout follows one other reader's description only, and the
  meaning of the extra bytes in each record is unknown. The header content
  is not decoded.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pfaff_spx
seq:
  - id: header
    size: 0x11e
    doc: "Unverified: header bytes, content not decoded."
  - id: records
    type: record
    repeat: eos
    doc: |
      Unverified: records to the end of the file. A trailing partial record
      makes parsing fail.
types:
  record:
    doc: |
      Unverified: one 9-byte record. The reader consulted skips 2 bytes
      before and 2 bytes after the move.
    seq:
      - id: unknown_0x00
        size: 2
        doc: Unknown. Skipped by the reader consulted.
      - id: dy_raw
        type: s2
        doc: |
          Y delta, signed 16-bit. The reader consulted negates it, so Y is
          up in the file and down in the result (unit unverified).
      - id: dx
        type: s2
        doc: X delta, signed 16-bit (unit unverified).
      - id: adjust_y
        type: s1
        doc: |
          Unverified: signed byte that the reader consulted subtracts from
          the negated Y delta. Possibly a fine Y correction; unknown.
      - id: unknown_0x07
        size: 2
        doc: Unknown. Skipped by the reader consulted.
    instances:
      dy:
        value: -dy_raw - adjust_y
        doc: |
          Unverified: Y delta as the reader consulted computes it, Y down.
