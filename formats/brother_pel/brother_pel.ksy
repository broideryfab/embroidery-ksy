meta:
  id: brother_pel
  title: Brother PEL embroidery format
  file-extension: pel
  license: MIT
doc: |
  Brother PEL: stitch-only format. libembroidery lists it as stitch-only with unimplemented reader and writer. Unverified: no
  open-source reader decodes this format and no redistributable sample was
  available, so the spec only exposes the whole file as raw bytes.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/brother_pel
seq:
  - id: body
    size-eos: true
    doc: |
      Unverified: the whole file, undecoded. Neither the header nor the
      stitch encoding is known.
