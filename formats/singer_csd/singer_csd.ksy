meta:
  id: singer_csd
  title: Singer CSD embroidery format
  file-extension: csd
  license: MIT
doc: |
  Singer CSD: an 8-byte identifier followed by a body that is obfuscated
  byte by byte (an XOR and subtract mask indexed by the file offset). The
  spec exposes the identifier and the encrypted body as raw bytes; Kaitai
  Struct cannot express the mask. The type `decrypted_body` describes the
  layout of the body after decryption (see README.md for the algorithm) and
  can be applied to the decrypted bytes by the user. Verified on six
  Wilcom-written files.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/singer_csd
seq:
  - id: magic
    contents: [0x7c, 0x4b, 0xc3, 0x74]
    doc: |
      Start of the identifier, the same in all six samples. Unverified: other
      producers may write other values (see README.md).
  - id: unknown_0x04
    type: u1
    doc: |
      Unknown. Differs per design (`3d 39 35 0d 7e 80` in the samples); the
      other identifier bytes are the same in every file.
  - id: identifier_tail
    contents: [0xc8, 0x53, 0xa4]
    doc: Rest of the identifier, the same in every sample.
  - id: encrypted_body
    size-eos: true
    doc: |
      Obfuscated body from offset 8 to the end of the file. See type
      `decrypted_body` for the layout after decryption.
types:
  decrypted_body:
    doc: |
      Layout of the body once the mask is removed (not applied by this spec).
      A size of 64 header bytes plus 3-byte records up to the end.
    seq:
      - id: colors
        type: rgb
        repeat: expr
        repeat-expr: 16
        doc: Thread colors; unused entries are 0, 0, 0.
      - id: unknown_0x30
        size: 2
        doc: Unknown. `7f 7f` in every sample.
      - id: color_order
        size: 14
        doc: |
          Color order. 0, 1, 2 ... 13 in every sample. Unverified: index into
          `colors` for each color change.
      - id: records
        type: record
        repeat: eos
        doc: Records to the end of the body; the last is `end`.
  rgb:
    seq:
      - id: red
        type: u1
      - id: green
        type: u1
      - id: blue
        type: u1
  record:
    doc: |
      Three bytes. Bit 7 of `flags` is set in every sample record; the sign
      bits and the command are in the other bits.
    seq:
      - id: flags
        type: u1
        doc: |
          Bits 0 to 4 `command`, bit 5 (`0x20`) x is negative, bit 6 (`0x40`)
          y is negative.
      - id: dy_abs
        type: u1
        doc: Absolute y move in 0.1 mm units.
      - id: dx_abs
        type: u1
        doc: Absolute x move in 0.1 mm units.
    instances:
      command:
        value: flags & 0x1f
        enum: command
        doc: Record command.
      is_negative_x:
        value: (flags & 0x20) != 0
      is_negative_y:
        value: (flags & 0x40) != 0
      dx:
        value: 'is_negative_x ? -dx_abs : dx_abs'
        doc: Signed x move in 0.1 mm units.
      dy:
        value: 'is_negative_y ? -dy_abs : dy_abs'
        doc: |
          Signed y move in 0.1 mm units. The running sum of the sample moves
          is the mirror of screen Y.
enums:
  command:
    0x00: stitch
    0x05: color_change    # no move
    0x07: end             # last record
    0x0a: unknown_0x0a    # first record in every sample, no move
    0x10: jump            # Unverified: move without stitching
