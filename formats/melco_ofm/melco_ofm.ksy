meta:
  id: melco_ofm
  title: Melco OFM embroidery format
  file-extension: ofm
  license: MIT
  endian: le
  imports:
    - ../_common/cfb
doc: |
  Melco OFM (partial, Unverified): reads the file as a Compound File Binary
  (OLE2) container, see `_common/cfb`. That OFM is a compound file whose
  stitch data is in a stream named "EdsIV Object" comes from an unfinished
  reader in another open-source project; no OFM file was available to
  check it. The layout of that stream (serialized objects holding a thread
  table and stitch blocks, according to the same reader) is not specified
  here, and the stream is not located: the directory entries are exposed,
  find the one named "EdsIV Object" in them.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/melco_ofm
seq:
  - id: container
    type: cfb
    doc: |
      Compound file header, first FAT sector and the first directory
      sectors. Unverified for OFM: parsing fails when a file does not start
      with the compound file signature.
