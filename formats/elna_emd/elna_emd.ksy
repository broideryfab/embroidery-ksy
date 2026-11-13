meta:
  id: elna_emd
  title: Elna EMD embroidery format
  file-extension: emd
  license: MIT
  endian: le
doc: |
  Elna EMD: a 0x30-byte header that starts with `JEMD0`, followed by 2-byte
  stitch records up to the end of the file. A record with first byte `0x80`
  is a control record; a long move uses two more bytes. Distances are in
  0.1 mm units. Layout derived from five Wilcom-written files and cross-checked
  with their sizes against Singer CSD files of the same designs; only part of
  the header is understood.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/elna_emd
seq:
  - id: magic
    contents: JEMD0
  - id: unknown_0x05
    type: u1
    doc: Unknown. 0 in every sample.
  - id: unknown_0x06
    type: u2
    doc: |
      Unknown. 101 (`0x65`) in every sample. Unverified: may be a version or
      machine id.
  - id: unknown_0x08
    type: u2
    doc: Unknown. 10 in every sample.
  - id: width
    type: u2
    doc: |
      Design width in 0.1 mm units. Equals the range of the running sum of
      the record x values (counted from the origin) in every sample.
  - id: height
    type: u2
    doc: |
      Design height in 0.1 mm units. Equals the range of the running sum of
      the record y values (counted from the origin) in every sample.
  - id: num_colors
    type: u2
    doc: Number of colors (color changes + 1).
  - id: unknown_0x10
    type: u2
    doc: |
      Unknown. 125 to 164 in the samples, a little below the number of
      stitch and move records. Unverified: possibly a stitch count.
  - id: reserved_0x12
    size: 10
    doc: Zero in every sample.
  - id: unknown_0x1c
    type: s2
    doc: Unknown. -24 (`e8 ff`) in every sample.
  - id: reserved_0x1e
    size: 18
    doc: Zero in every sample.
  - id: records
    type: record
    repeat: eos
    doc: Records from offset 0x30 to the end of the file.
types:
  record:
    doc: |
      Two bytes. If the first is not `0x80`, they are a stitch (dx, dy). If it
      is `0x80`, the second byte is a control code; a `move` is followed by
      two more bytes, the (dx, dy) of a move without stitching.
    seq:
      - id: dx
        type: s1
        doc: |
          Stitch x move in 0.1 mm units. `-128` (`0x80`) marks a control
          record instead.
      - id: dy
        type: s1
        doc: Stitch y move in 0.1 mm units, or the control code (low byte).
      - id: move_dx
        type: s1
        if: is_move
        doc: Move x in 0.1 mm units.
      - id: move_dy
        type: s1
        if: is_move
        doc: Move y in 0.1 mm units.
    instances:
      is_control:
        value: dx == -128
        doc: True for a control record.
      control:
        value: dy & 0xff
        enum: control_code
        if: is_control
        doc: Control code.
      is_move:
        value: is_control and dy == -128
        doc: True for a move (two more bytes follow).
      is_end:
        value: is_control and dy == -3
        doc: True for the end record.
enums:
  control_code:
    0x2a: color_change   # no move
    0x7d: unknown_0x7d   # first record in every sample
    0x80: move           # followed by two move bytes
    0x90: trim_0x90      # Unverified: trim, shortly before the end
    0xad: trim_0xad      # Unverified: trim; in no sample
    0xfd: end
