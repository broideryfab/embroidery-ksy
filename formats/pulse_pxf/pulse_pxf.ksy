meta:
  id: pulse_pxf
  title: Pulse PXF embroidery format
  file-extension: pxf
  license: MIT
doc: |
  Pulse PXF: nothing about the layout is known. No sample file and no
  public description was found, and none of the open-source embroidery
  readers consulted handles the format. The spec only exposes the whole
  file as raw bytes so that it compiles; it does not claim a header or
  structure. See README.md in this directory.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/pulse_pxf
seq:
  - id: body
    size-eos: true
    doc: |
      The whole file. Unverified: whether it has a header, is compressed,
      or is a container is unknown.
