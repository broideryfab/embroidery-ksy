meta:
  id: mitsubishi_mit
  title: Mitsubishi MIT embroidery format
  file-extension: mit
  license: MIT
doc: |
  Mitsubishi MIT: a headerless stream of 2-byte records. Each byte holds a
  5-bit move magnitude, a sign bit and two bits of a shared 4-bit command.
  Unverified: no redistributable .mit sample was available; the layout
  follows other readers' description only, including the unit of the
  magnitudes and the meaning of most command values.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/mitsubishi_mit
seq:
  - id: records
    type: record
    repeat: eos
    doc: |
      Records to end of file. Unverified: a trailing odd byte would make
      parsing fail; one reader ignores it.
instances:
  num_records:
    value: records.size
    doc: Number of records.
types:
  record:
    doc: |
      Unverified: one 2-byte record. The first byte carries X, the second Y.
    seq:
      - id: byte0
        type: u1
        doc: |
          Bit 7: X is negative. Bits 6..5: command bits 3..2. Bits 4..0:
          X magnitude.
      - id: byte1
        type: u1
        doc: |
          Bit 7: Y is negative. Bits 6..5: command bits 1..0. Bits 4..0:
          Y magnitude.
    instances:
      x_magnitude:
        value: byte0 & 0x1f
        doc: Absolute X move in raw units (see README for the unit).
      y_magnitude:
        value: byte1 & 0x1f
        doc: Absolute Y move in raw units.
      dx:
        value: '(byte0 & 0x80) != 0 ? -x_magnitude : x_magnitude'
        doc: Relative X move in raw units, positive to the right.
      dy:
        value: '(byte1 & 0x80) != 0 ? -y_magnitude : y_magnitude'
        doc: Relative Y move in raw units, positive up.
      command:
        value: ((byte0 & 0x60) >> 3) | ((byte1 & 0x60) >> 5)
        doc: |
          4-bit command. Values other readers act on: 0b0111, 0b0100 and
          0b0101 stitch; 0b1100 jump; 0b1000 color change when the previous
          record was 0b0111; 0b0000 end marker. Other values are treated as
          stitches.
      is_jump:
        value: command == 12
        doc: Move without stitching (0b1100).
      is_color_change:
        value: command == 8
        doc: |
          Unverified: color change marker (0b1000). It only counts after a
          record with command 0b0111.
      is_end:
        value: command == 0
        doc: End marker (0b0000), which other readers say appears at the end.
