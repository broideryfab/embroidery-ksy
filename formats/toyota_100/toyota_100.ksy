meta:
  id: toyota_100
  title: Toyota 100 embroidery format
  file-extension: 100
  license: MIT
doc: |
  Toyota stitch file with no header, in the 100 family (the samples have
  the extension .101). The file is a list of 4-byte records: a control byte,
  a zero byte, and X and Y offsets in sign-and-magnitude form. A final
  record with control 0x1F ends the design and is followed by 2 zero bytes
  in all samples.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/toyota_100
seq:
  - id: records
    type: record
    repeat: expr
    repeat-expr: num_records
    doc: All complete 4-byte records, the end record (0x1F) included.
  - id: trailer
    size-eos: true
    doc: Remaining bytes that do not make a complete record (2 in all samples).
instances:
  num_records:
    value: _io.size / 4
    doc: Number of complete 4-byte records in the file.
types:
  record:
    doc: One 4-byte record.
    seq:
      - id: control
        type: u1
        doc: |
          Record type. Seen: 0x83 move, 0xA1 / 0xC1 / 0xE1 stitch, 0x82 and
          0x84 (one pair at the end of every color block, Unverified
          meaning), 0x81 (Unverified), 0x1F end. pyembroidery treats 0x61 as
          stitch, any other odd value as move and any even value as color
          change; that does not agree with these samples, where bit 7 is set
          and bits 5 and 6 vary.
      - id: reserved_0x01
        type: u1
        doc: Always 0 in the samples.
      - id: x_raw
        type: u1
        doc: X offset, sign-and-magnitude (bit 7 is the sign).
      - id: y_raw
        type: u1
        doc: Y offset, sign-and-magnitude (bit 7 is the sign).
    instances:
      dx:
        value: '(x_raw & 0x80) != 0 ? -(x_raw & 0x7f) : x_raw'
        doc: |
          Signed X offset in 0.1 mm units (Unverified). Raw 0x80 gives 0
          here; pyembroidery reads it as 128 (not in the samples).
      dy:
        value: '(y_raw & 0x80) != 0 ? -(y_raw & 0x7f) : y_raw'
        doc: |
          Signed Y offset as stored. pyembroidery negates it, so Y is down in
          its output; which way is up in the file is Unverified.
      is_end:
        value: control == 0x1f
        doc: End record.
