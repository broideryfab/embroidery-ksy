meta:
  id: thredworks_thr
  title: ThredWorks THR embroidery format
  file-extension: thr
  license: MIT
  endian: le
doc: |
  ThredWorks THR: a 26-byte header (signature, version, stitch count), an
  optional 144-byte extension in versions 1 and 2, 12-byte stitch records
  (X, Y, attribute word), then a bitmap name, a background color and 16
  custom thread colors. Unverified: no redistributable .thr sample was
  available; the layout follows one reader's description (libembroidery),
  including the numeric type of the coordinates, which may really be
  floating point.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/thredworks_thr
seq:
  - id: header
    type: header
    doc: Fixed 26-byte header.
  - id: extension
    type: extension
    if: header.version == 1 or header.version == 2
    doc: Extension block, only in versions 1 and 2.
  - id: stitches
    type: stitch
    repeat: expr
    repeat-expr: header.num_stitches
    doc: Stitch records.
  - id: bitmap_name
    size: 16
    doc: |
      Unverified: name of a background bitmap, 16 bytes, probably
      NUL-padded text.
  - id: background_color
    type: rgbx
    doc: Background color.
  - id: custom_colors
    type: rgbx
    repeat: expr
    repeat-expr: 16
    doc: The 16 thread colors; a stitch selects one with its low 4 bits.
  - id: thread_sizes
    size-eos: true
    doc: |
      Unverified: 16 bytes of thread sizes as ASCII (e.g. "4"), as noted by
      a reader's comment; whatever follows the colors is kept raw.
types:
  header:
    seq:
      - id: signature
        size: 3
        doc: |
          Unverified: the low three bytes of a 32-bit value that is
          0x746872 in the reader, so 72 68 74 in the file ("rht").
      - id: version
        type: u1
        doc: |
          Version: 0 has no extension, 1 and 2 have the 144-byte extension.
          Other versions are unsupported by the reader.
      - id: length
        type: u4
        doc: |
          Unverified: a writer stores 12 * stitch count + 16 (plus the
          header size for versions 1 and 2), the size of the stitch data
          including the trailing 16 bytes.
      - id: num_stitches
        type: u2
        doc: Number of stitch records.
      - id: hoop_size
        type: u2
        doc: |
          Unverified: hoop size code; a writer stores 5.
      - id: reserved_0x0c
        size: 14
        doc: |
          Reserved: seven 16-bit words, 0 in a writer.
    instances:
      is_signature_valid:
        value: signature == [0x72, 0x68, 0x74]
        doc: Whether `signature` has the value the reader checks for.
  extension:
    doc: |
      Unverified: 144 bytes, read from a writer's layout.
    seq:
      - id: hoop_x
        type: s4
        doc: |
          Unverified: hoop width; a writer stores 640.
      - id: hoop_y
        type: s4
        doc: |
          Unverified: hoop height; a writer stores 640.
      - id: stitch_granularity
        type: s4
        doc: |
          Unverified: stitch granularity; 0 in a writer.
      - id: creator_name
        size: 50
        doc: |
          Unverified: name of the creator, text.
      - id: modifier_name
        size: 50
        doc: |
          Unverified: name of the last modifier, text.
      - id: aux_format
        type: u1
        doc: |
          Unverified: auxiliary format code; a writer stores 1.
      - id: reserved_0x8d
        size: 31
        doc: Reserved.
  stitch:
    doc: |
      Unverified: one 12-byte stitch record with an absolute position. The
      coordinates are 32-bit values that the reader divides by 10 to get
      millimeters, so one unit is 0.1 mm.
    seq:
      - id: x
        type: s4
        doc: |
          Absolute X in 0.1 mm units. Unverified: real files may store an
          IEEE float; the reader treats the 4 bytes as an integer.
      - id: 'y'
        type: s4
        doc: Absolute Y in 0.1 mm units; same caveat as `x`.
      - id: attributes
        type: u4
        doc: |
          Bit flags. Bits 0..3: color index (0..15). Bits 4..14: form
          pointer. Bit 19: not a form stitch. Bit 20: center walk. Bit 21:
          edge walk. Bit 22: underlay. Bit 23: knot. Bit 24: feather. Bits
          25..27: layer. Bits 29..30: stitch type (0 not a form stitch, 1
          form fill, 2 form border fill, 3 applique). Bit 31: edited by the
          user. These come from a comment in one reader.
    instances:
      color_index:
        value: attributes & 0x0f
        doc: Index into `custom_colors`.
      stitch_type:
        value: (attributes >> 29) & 0x03
        doc: 0 not a form stitch, 1 form fill, 2 border fill, 3 applique.
  rgbx:
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
      - id: unused
        type: u1
        doc: Padding byte (0 in a writer).
