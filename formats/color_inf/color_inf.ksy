meta:
  id: color_inf
  title: INF thread colors embroidery format
  file-extension: inf
  license: MIT
  endian: be
doc: |
  Thread color companion file (Wilcom/Bernina/My Editor style). A 16-byte
  header (three 32-bit values and the color count) is followed by variable
  length color records, each with an RGB color and two zero-terminated
  strings. All numbers are big-endian.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/color_inf
seq:
  - id: version
    type: u4
    doc: 1 in every sample. Unverified meaning.
  - id: header_size
    type: u4
    doc: 8 in every sample. Unverified meaning.
  - id: data_size
    type: u4
    doc: File size minus 8 in every sample.
  - id: num_colors
    type: u4
    doc: Number of records that follow.
  - id: colors
    type: color_record
    repeat: expr
    repeat-expr: num_colors
    doc: Color records.
types:
  color_record:
    seq:
      - id: record_length
        type: u2
        doc: Length of the record in bytes, including this field.
      - id: body
        type: color_body
        size: record_length - 2
  color_body:
    seq:
      - id: index
        type: u2
        doc: 1-based position of the color in the table (1, 2, 3, ...).
      - id: red
        type: u1
      - id: green
        type: u1
      - id: blue
        type: u1
      - id: reserved_0x05
        type: u1
        doc: Always 0 in the samples.
      - id: unknown_0x06
        type: u1
        doc: |
          Unknown. Equals the low byte of `index` in the Embroidery Wizard (`-ew-+`) samples and
          0 in the My Editor (`-me`) samples.
      - id: first_string
        type: strz
        encoding: UTF-8
        doc: |
          "BERNINA" in the `-ew-+` samples, "Default" in the `-me` samples.
          Unverified: pyembroidery calls this the description; it looks like
          a thread brand or chart name.
      - id: second_string
        type: strz
        encoding: UTF-8
        doc: |
          Color name ("Grey", "Navy Blue") in the `-ew-+` samples, a single
          space in the `-me` samples. Unverified: pyembroidery calls this the chart.
      - id: trailer
        size-eos: true
        doc: Bytes left in the record. Empty in all samples.
