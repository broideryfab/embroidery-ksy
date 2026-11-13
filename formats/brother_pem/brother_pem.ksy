meta:
  id: brother_pem
  title: Brother PEM embroidery format
  file-extension: pem
  license: MIT
doc: |
  Brother PEM: stitch-only format. libembroidery lists it as stitch-only with unimplemented reader and writer. Unverified: no
  open-source reader decodes this format and no redistributable sample was
  available, so the spec only exposes the whole file as raw bytes.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/brother_pem
seq:
  - id: body
    size-eos: true
    doc: |
      Unverified: the whole file, undecoded. Neither the header nor the
      stitch encoding is known.
