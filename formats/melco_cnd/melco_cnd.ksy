meta:
  id: melco_cnd
  title: Melco CND embroidery format
  file-extension: cnd
  license: MIT
doc: |
  Melco CND: stitch-only format. libembroidery lists it as stitch-only and says that nothing is known about it. Unverified: no
  open-source reader decodes this format and no redistributable sample was
  available, so the spec only exposes the whole file as raw bytes.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/melco_cnd
seq:
  - id: body
    size-eos: true
    doc: |
      Unverified: the whole file, undecoded. Neither the header nor the
      stitch encoding is known.
