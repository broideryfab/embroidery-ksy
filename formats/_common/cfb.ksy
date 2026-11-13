meta:
  id: cfb
  title: Compound File Binary (OLE2) container
  license: MIT
  endian: le
doc: |
  Microsoft Compound File Binary container ("OLE2", "structured storage"),
  as published in the open [MS-CFB] specification. Several proprietary
  embroidery source formats are stored inside one (Wilcom EMB, Melco OFM,
  Bernina ART). The container is a small file system: a 512-byte (or
  4096-byte) header, sectors of that size, a sector chain table (FAT) and a
  directory of named storages and streams.

  This type reads the header, the first FAT sector and the first two
  directory sectors (8 entries at 512 bytes per sector). A full reader must
  follow sector chains through the FAT (and the mini-FAT for streams under
  4096 bytes), which Kaitai Struct cannot loop over. The stream position
  given by `dir_entry::stream_pos` is therefore only offered for regular
  (not mini) streams and is only correct when the stream's sectors are
  consecutive in the file (true for every such stream in the Wilcom
  samples, Unverified in general). Small streams are stored in the "mini
  stream", itself a chain of sectors that is fragmented in the samples;
  their data is not reachable here.
doc-ref: https://github.com/broideryfab/embroidery-ksy/tree/main/formats/_common/README.md
seq:
  - id: header
    type: header
    doc: The 512-byte file header.
instances:
  sector_size:
    value: 1 << header.sector_shift
    doc: Sector size in bytes (512 for version 3, 4096 for version 4).
  fat_sector_0:
    pos: (header.difat[0] + 1) * sector_size
    size: 1 << header.sector_shift
    type: fat_sector
    doc: |
      The first FAT sector, whose index is the first DIFAT entry. Entry
      `n` of the FAT is the sector that follows sector `n` in its chain.
      Covers sector numbers below `sector_size / 4` only.
  root_entry:
    pos: (header.first_dir_sector + 1) * sector_size
    size: 128
    type: dir_entry(sector_size, header.mini_stream_cutoff)
    doc: |
      The root entry (first entry of the first directory sector). Its
      stream is the mini stream, the storage for small streams.
  directory_sector_0:
    pos: (header.first_dir_sector + 1) * sector_size
    size: 1 << header.sector_shift
    type: dir_sector(sector_size, header.mini_stream_cutoff)
    doc: First directory sector.
  has_directory_sector_1:
    value: fat_sector_0.entries[header.first_dir_sector] < 0xfffffffa
    doc: |
      Whether the FAT gives a second sector for the directory. Only valid
      when `first_dir_sector` is covered by the first FAT sector.
  directory_sector_1:
    pos: (fat_sector_0.entries[header.first_dir_sector] + 1) * sector_size
    size: 1 << header.sector_shift
    type: dir_sector(sector_size, header.mini_stream_cutoff)
    if: has_directory_sector_1
    doc: |
      Second directory sector. Directories longer than two sectors are
      not read.
types:
  header:
    seq:
      - id: signature
        contents: [0xd0, 0xcf, 0x11, 0xe0, 0xa1, 0xb1, 0x1a, 0xe1]
        doc: Compound file signature.
      - id: clsid
        size: 16
        doc: Class id; zero in every sample.
      - id: minor_version
        type: u2
        doc: Minor version (0x3e in every sample).
      - id: major_version
        type: u2
        doc: "Major version: 3 for 512-byte sectors, 4 for 4096-byte sectors."
      - id: byte_order
        type: u2
        doc: Byte order mark, 0xfffe for little endian.
      - id: sector_shift
        type: u2
        doc: Sector size as a power of two (9 = 512 bytes, 12 = 4096 bytes).
      - id: mini_sector_shift
        type: u2
        doc: Mini-sector size as a power of two (6 = 64 bytes).
      - id: reserved_0x22
        size: 6
        doc: Reserved, zero.
      - id: num_dir_sectors
        type: u4
        doc: Number of directory sectors; zero for version 3.
      - id: num_fat_sectors
        type: u4
        doc: Number of FAT sectors.
      - id: first_dir_sector
        type: u4
        doc: Sector number of the first directory sector.
      - id: transaction_signature
        type: u4
        doc: Transaction signature, zero in every sample.
      - id: mini_stream_cutoff
        type: u4
        doc: |
          Streams smaller than this (4096) live in the mini stream; larger
          ones in regular sectors.
      - id: first_mini_fat_sector
        type: u4
        doc: Sector number of the first mini-FAT sector.
      - id: num_mini_fat_sectors
        type: u4
        doc: Number of mini-FAT sectors.
      - id: first_difat_sector
        type: u4
        doc: First DIFAT sector, 0xfffffffe when the header DIFAT is enough.
      - id: num_difat_sectors
        type: u4
        doc: Number of DIFAT sectors.
      - id: difat
        type: u4
        repeat: expr
        repeat-expr: 109
        doc: |
          First 109 FAT sector numbers; 0xffffffff marks an unused slot.
  fat_sector:
    seq:
      - id: entries
        type: u4
        repeat: eos
        doc: |
          Next sector of each sector number. 0xfffffffe ends a chain,
          0xffffffff is a free sector, 0xfffffffd a FAT sector.
  dir_sector:
    params:
      - id: sector_size
        type: u4
      - id: mini_cutoff
        type: u4
    seq:
      - id: entries
        type: dir_entry(sector_size, mini_cutoff)
        size: 128
        repeat: eos
        doc: Directory entries, 128 bytes each.
  dir_entry:
    params:
      - id: sector_size
        type: u4
      - id: mini_cutoff
        type: u4
    seq:
      - id: name_raw
        size: 64
        doc: Entry name, UTF-16LE, zero-terminated, padded to 64 bytes.
      - id: name_len
        type: u2
        doc: Length of the name in bytes including the terminator.
      - id: object_type
        type: u1
        enum: object_type
        doc: Entry type.
      - id: color
        type: u1
        doc: Red-black tree node color (0 red, 1 black).
      - id: left_sibling
        type: u4
        doc: Directory index of the left sibling, 0xffffffff for none.
      - id: right_sibling
        type: u4
        doc: Directory index of the right sibling, 0xffffffff for none.
      - id: child
        type: u4
        doc: Directory index of the child, 0xffffffff for none.
      - id: clsid
        size: 16
        doc: Class id; zero in every sample.
      - id: state_bits
        type: u4
        doc: User-defined state flags.
      - id: created
        type: u8
        doc: Creation time as Windows FILETIME; zero in every sample.
      - id: modified
        type: u8
        doc: Modification time as Windows FILETIME; zero in every sample.
      - id: start_sector
        type: u4
        doc: |
          First sector of the stream (of the mini stream for small
          streams), and for the root entry the first sector of the mini
          stream.
      - id: size_low
        type: u4
        doc: Low 32 bits of the stream size in bytes.
      - id: size_high
        type: u4
        doc: |
          High 32 bits of the stream size; must be ignored for version 3,
          zero in every sample.
    instances:
      name:
        pos: 0
        size: name_len - 2
        type: str
        encoding: UTF-16LE
        if: name_len >= 2
        doc: Entry name without the terminator.
      stream_size:
        value: size_low
        doc: Stream size in bytes (low 32 bits).
      is_mini:
        value: object_type == object_type::stream and stream_size < mini_cutoff
        doc: Whether the stream is stored in the mini stream.
      stream_pos:
        value: (start_sector + 1) * sector_size
        if: object_type == object_type::stream and not is_mini
        doc: |
          File offset of the first byte of a regular (not mini) stream,
          valid only when its sectors are consecutive (Unverified in
          general).
    enums:
      object_type:
        0: unallocated
        1: storage
        2: stream
        5: root
