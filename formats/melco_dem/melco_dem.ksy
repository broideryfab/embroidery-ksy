meta:
  id: melco_dem
  title: Melco DEM embroidery format
  file-extension: dem
  license: MIT
doc: |
  Melco DEM: stitch-only format. libembroidery lists it as stitch-only and falls back to its DST reader, a placeholder rather than documentation. Unverified: no
  open-source reader decodes this format and no redistributable sample was
  available, so the spec only exposes the whole file as raw bytes.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/melco_dem
seq:
  - id: body
    size-eos: true
    doc: |
      Unverified: the whole file, undecoded. Neither the header nor the
      stitch encoding is known.
