meta:
  id: bernina_art
  title: Bernina ART embroidery format
  file-extension: art
  license: MIT
  endian: le
  imports:
    - ../_common/cfb
doc: |
  Bernina ART (partial, Unverified): reads the file as a Compound File
  Binary (OLE2) container, see `_common/cfb`. That the format is a compound
  file with a stream named "Contents" comes from an unfinished reader in
  another open-source project; no ART file was available to check it. The
  contents of that stream are not described: the same reader skips 4 bytes,
  de-obfuscates every byte and inflates the result with zlib, but what comes
  out is unknown. Because no sample exists, the stream is not located here
  and nothing past the container directory is specified.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/bernina_art
seq:
  - id: container
    type: cfb
    doc: |
      Compound file header, first FAT sector and the first directory
      sectors. Unverified for ART: parsing fails when a file does not start
      with the compound file signature.
