meta:
  id: pfaff_ksm
  title: Pfaff KSM embroidery format
  file-extension: ksm
  license: MIT
doc: |
  Older Pfaff format (stitch data only). A 512-byte header that is blank in
  every sample is followed by 3-byte records, each holding a relative move
  (magnitudes in two bytes, signs in a control byte) and a command code. The
  last record has command 0x08. No thread colors are stored; color changes
  are needle-change commands.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pfaff_ksm
seq:
  - id: header
    size: 512
    doc: |
      Unverified: no known content. Wilcom writes 256 spaces (0x20) followed
      by 256 zero bytes; Wings My Editor writes 512 zero bytes.
  - id: records
    type: stitch_record
    repeat: until
    repeat-until: _.is_end or _io.eof
    doc: |
      Records up to and including the end record (command 0x08). Parsing
      also stops at end of file.
  - id: trailer
    size-eos: true
    doc: Bytes after the end record. Empty in all samples.
instances:
  num_records:
    value: records.size
    doc: Number of records, including the end record.
types:
  stitch_record:
    doc: |
      One 3-byte record. Bit 7 of the control byte is set in every record of
      every sample.
    seq:
      - id: dy_magnitude
        type: u1
        doc: Absolute Y move, in 0.1 mm units. Sign is in `control` bit 5.
      - id: dx_magnitude
        type: u1
        doc: Absolute X move, in 0.1 mm units. Sign is in `control` bit 6.
      - id: control
        type: u1
        doc: |
          Bit 7: always 1 (Unverified meaning). Bit 6: X is negative.
          Bit 5: Y is negative (Y up). Bits 4..0: command code.
    instances:
      command_code:
        value: control & 0x1f
        doc: |
          Command code. 0x00 stitch; 0x07 first record of every sample;
          0x0b..0x10, 0x1d, 0x1e needle/color change (observed in this
          order for colors 1..8, Unverified; pyembroidery also treats
          0x0b..0x12 as needle 1..8 and 0x05 as stop); 0x17, 0x18, 0x19
          and 0x1b are written around moves and before the end (meaning
          Unverified); 0x08 end.
      dx:
        value: 'dx_negative ? -dx_magnitude : dx_magnitude'
        doc: Relative X move in 0.1 mm units, positive to the right.
      dy:
        value: 'dy_negative ? -dy_magnitude : dy_magnitude'
        doc: |
          Relative Y move in 0.1 mm units, positive up (screen coordinates
          need the sign flipped).
      dx_negative:
        value: (control & 0x40) != 0
        doc: X move is to the left.
      dy_negative:
        value: (control & 0x20) != 0
        doc: Y move is down.
      is_stitch:
        value: command_code == 0
        doc: Plain stitch.
      is_end:
        value: command_code == 0x08
        doc: End of stitch data.
