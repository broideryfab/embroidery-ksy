meta:
  id: pfaff_pcm
  title: Pfaff PCM embroidery format
  file-extension: pcm
  license: MIT
  endian: be
doc: |
  Pfaff PCM format (older Pfaff machines; the machine models are not
  verified here). All values are big-endian. A header (version, hoop) is followed
  by a list of palette indices, a stitch count and 9-byte records with
  absolute fixed-point positions and a control byte. Same record layout as
  PCS, but the byte order is reversed and colors are indices into a fixed
  16-color palette instead of RGB values.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pfaff_pcm
seq:
  - id: version
    type: u1
    doc: 0x32 ("2") in every sample. Unverified meaning.
  - id: hoop_code
    type: u1
    doc: |
      Hoop code. 3 in most samples, 2 in spiralbox-wilcom.PCM
      (same meaning as in PCS, Unverified).
  - id: num_colors
    type: u2
    doc: |
      Number of entries in the color table (16 in every sample). Not the
      number of colors used.
  - id: colors
    type: color
    repeat: expr
    repeat-expr: num_colors
    doc: Color table.
  - id: stitch_count
    type: u2
    doc: |
      Stitch count. Unverified meaning: it matches no simple rule. In the
      five My Editor samples it is the number of complete records minus 5;
      in the four Wilcom samples it differs from the record count by an
      unrelated amount (for example 156 for 79 records).
  - id: records
    type: stitch_record
    repeat: expr
    repeat-expr: num_records
    doc: |
      All complete 9-byte records up to the end of the file. There is no end
      marker. My Editor files end with a zero record and 4 more zero bytes;
      Wilcom files end exactly after the last record.
  - id: trailer
    size-eos: true
    doc: Remaining bytes that do not make a complete record (4 in My Editor files, 0 in Wilcom files).
instances:
  num_records:
    value: (_io.size - (4 + 2 * num_colors + 2)) / 9
    doc: |
      Number of complete 9-byte records between the stitch count and the end
      of the file, padding records included.
types:
  color:
    seq:
      - id: palette_index
        type: u2
        doc: |
          Index (0-15) into a fixed 16-color palette (black, navy, blue,
          teal, cyan, purple, magenta, maroon, red, green, lime, olive,
          yellow, gray, silver, white; palette order from pyembroidery,
          Unverified). The palette is not stored in the file.
  stitch_record:
    doc: |
      One 9-byte record. X and Y are 32-bit little-endian fixed-point
      numbers: the first three bytes are the signed integer part and the last byte is a fraction in 1/256, the upper 24 bits are
      the signed integer part. In color change records the low byte of X
      holds the color index and the rest is 0.
    seq:
      - id: x_raw
        type: s4be
        doc: X position, fixed point (integer part << 8 | fraction).
      - id: y_raw
        type: s4be
        doc: Y position, fixed point (integer part << 8 | fraction).
      - id: control
        type: u1
        doc: 0x00 stitch, 0x03 color change, 0x04 move (jump).
    instances:
      x:
        value: x_raw >> 8
        doc: |
          Integer part of the X position. Absolute, not a delta. pyembroidery
          scales it by 5/3 to 0.1 mm. Unverified.
      x_fraction:
        value: x_raw & 0xff
        doc: |
          Fractional part of X in 1/256. My Editor files use multiples of about
          0.2 (0x33, 0x66, ...); Wilcom files use other values. In color change
          records this byte is the palette index instead.
      y:
        value: y_raw >> 8
        doc: |
          Integer part of the Y position. Absolute. Unverified direction:
          pyembroidery negates it, so it is probably Y up in the file.
      y_fraction:
        value: y_raw & 0xff
        doc: Fractional part of Y in 1/256.
      palette_index:
        value: x_raw & 0xff
        doc: |
          Only meaningful when `is_color_change`: index (0-15) into the fixed
          16-color palette of the color that starts here (the byte is the
          same value as in the header color table, not a slot number).
          Wilcom files list the colors in order of use; My Editor files
          list 0..15. Meaning from sample observation.
      is_stitch:
        value: control == 0
        doc: Stitch.
      is_color_change:
        value: (control & 0x01) != 0
        doc: Color change (control 0x03 in all samples).
      is_move:
        value: (control & 0x01) == 0 and (control & 0x04) != 0
        doc: Move without stitching (control 0x04).
