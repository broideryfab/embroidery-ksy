meta:
  id: color_rgb
  title: RGB thread colors embroidery format
  file-extension: rgb
  license: MIT
doc: |
  Thread color companion file. A plain list of 4-byte entries (red, green,
  blue, padding byte) with no header and no count: the number of colors is
  the file size divided by 4. Unverified: this description comes from the
  Embroidermodder reader, which states that RGB is a color-only file for use
  with other formats; the layout is the same as Embird EDR. No real-world
  sample was found.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/color_rgb
seq:
  - id: colors
    type: color
    repeat: expr
    repeat-expr: num_colors
    doc: Thread colors in order.
  - id: trailer
    size-eos: true
    doc: Remaining bytes that do not make a complete entry (0 to 3).
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
      - id: padding
        type: u1
        doc: Unverified. Not interpreted by readers; 0 when written by the tool in the sources consulted.
