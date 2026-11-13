meta:
  id: zsk_zsk
  title: ZSK USA ZSK embroidery format
  file-extension: zsk
  license: MIT
doc: |
  ZSK USA ZSK: a 560-byte header area of unknown content, a list of colors
  (a number byte, an RGB color and 72 bytes of unknown data each, ended by a
  zero number byte), 46 more unknown bytes, then 3-byte records (flags, X
  magnitude, Y magnitude). Unverified: no redistributable .zsk sample was
  available; everything follows one reader's description (libembroidery),
  including its sign and unit handling, which looks incomplete there.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/zsk_zsk
seq:
  - id: unknown_0x00
    size: 560
    doc: |
      Unverified: not interpreted by any reader; contents unknown.
  - id: colors
    type: color_entry
    repeat: until
    repeat-until: _.color_number == 0
    doc: |
      Color list from offset 0x230, ended by an entry whose number byte is 0
      (that entry has nothing else). Unverified: another producer's writer
      stores the color count in the first number byte and counts down in the
      following ones.
  - id: unknown_after_colors
    size: 46
    doc: |
      Unverified: 46 bytes after the color list; contents unknown.
  - id: records
    type: record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record, or to end of file.
      Unverified: a trailing partial record would make parsing fail.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  color_entry:
    seq:
      - id: color_number
        type: u1
        doc: Color number; 0 ends the list.
      - id: color
        type: rgb
        if: color_number != 0
        doc: Thread color.
      - id: unknown_0x04
        size: 72
        if: color_number != 0
        doc: |
          Unverified: 72 bytes after the color; contents unknown.
  rgb:
    seq:
      - id: red
        type: u1
        doc: |
          Red. Unverified: the channel order is assumed.
      - id: green
        type: u1
        doc: Green.
      - id: blue
        type: u1
        doc: Blue.
  record:
    doc: |
      Unverified: one 3-byte record.
    seq:
      - id: flags
        type: u1
        doc: |
          Bit 3: X is negative. Bit 2: Y is negative. Bit 1: jump. Bit 5:
          special record (trim, end or color change, see `is_special`).
      - id: x_magnitude
        type: u1
        doc: |
          Absolute X move. In a special record: 2 means trim and 0xff means
          end; any other value is a color change. Unit unknown (0.1 mm?).
      - id: y_magnitude
        type: u1
        doc: |
          Absolute Y move. In a color change record, the new color number
          (1-based) when not 0.
    instances:
      dx:
        value: '(flags & 0x08) != 0 ? -x_magnitude : x_magnitude'
        doc: |
          Relative X move; the reader ignores the move in special records.
      dy:
        value: '(flags & 0x04) != 0 ? -y_magnitude : y_magnitude'
        doc: Relative Y move; sign convention for Y direction not known.
      is_special:
        value: (flags & 0x20) != 0
        doc: Trim, end or color change record.
      is_jump:
        value: (flags & 0x02) != 0 and not is_special
        doc: Move without stitching.
      is_trim:
        value: is_special and x_magnitude == 2
        doc: Trim.
      is_end:
        value: is_special and x_magnitude == 0xff
        doc: End of stitch data.
      is_color_change:
        value: is_special and x_magnitude != 2 and x_magnitude != 0xff
        doc: Color change; `y_magnitude` is the new color number if not 0.
