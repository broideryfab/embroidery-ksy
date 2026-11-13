meta:
  id: embird_edr
  title: Embird EDR thread colors embroidery format
  file-extension: edr
  license: MIT
doc: |
  Thread color companion file written by Embird. It is a plain list of
  4-byte entries (red, green, blue, 0) with no header and no count: the
  number of colors is the file size divided by 4. It holds only the colors
  of a design, not stitches. Layout shared with the RGB color file.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/embird_edr
seq:
  - id: colors
    type: color
    repeat: expr
    repeat-expr: num_colors
    doc: Thread colors in color-change order (first color first).
  - id: trailer
    size-eos: true
    doc: Remaining bytes that do not make a complete entry (0 to 3). Empty in all samples.
instances:
  num_colors:
    value: _io.size / 4
    doc: Number of complete 4-byte entries in the file.
types:
  color:
    seq:
      - id: red
        type: u1
      - id: green
        type: u1
      - id: blue
        type: u1
      - id: reserved_0x03
        type: u1
        doc: Always 0 in the samples.
