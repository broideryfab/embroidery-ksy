# Wilcom EMB

| | |
|---|---|
| Spec | [`wilcom_emb.ksy`](wilcom_emb.ksy) |
| Extensions | `.emb` |
| Vendor | Wilcom |
| Priority | Proprietary source format — preview/partial only |
| Status | 🟡 Partial |

Proprietary object-based source format. Only the container and a few of the
streams inside it are described; the stitch and object data is not.

## Structure

Every sample is a Compound File Binary ("OLE2", [MS-CFB]) file, parsed by
the shared type [`formats/_common/cfb.ksy`](../_common/cfb.ksy): version 3,
512-byte sectors, 64-byte mini sectors, one FAT sector, two directory
sectors. All 15 samples have the same eight directory entries in the same
order:

| # | Name | Content |
|---|---|---|
| 0 | `Root Entry` | root storage; its stream is the mini stream |
| 1 | `AUX_INFO` | 9 or 17 bytes, starts with the u4 `1`; meaning unknown |
| 2 | `Contents` | u4 size + zlib stream; the inflated data (about 9 to 51 KB) is unexplained |
| 3 | `DesignDocument` | 3.8 to 10 KB; high-entropy bytes, not zlib; unknown |
| 4 | `\u0005SummaryInformation` | standard OLE property set, 381 to 389 bytes; holds the design name as the title (property 2) |
| 5 | `\u0005WilcomDesignInformationDDD` | OLE property set with Wilcom's own format id (see below) |
| 6 | `DESIGN_ICON` | u4 size + zlib stream that inflates to a 100x100, 8-bit BMP |
| 7 | `TRUEVIEW_ICON` | u4 size + zlib stream that inflates to a JPEG (JFIF) |

The u4 in front of the zlib streams equals the inflated size in every
stream checked.

### What the spec reads

Streams smaller than 4096 bytes live in the container's mini stream. That
stream is made of fragmented sectors in the samples (and `Contents` and
`DESIGN_ICON` are fragmented inside it), and Kaitai Struct cannot follow
sector chains, so the spec reaches only the regular streams. It
assumes their sectors are consecutive, which held for every regular stream
in the 15 samples. The directory entries of all eight streams are read,
including start sector and size, so a consuming application can do the
chain walk itself.

| Item | In the samples | Read by the spec |
|---|---|---|
| `WilcomDesignInformationDDD` | always 4 KB or more | yes, as `design_information` |
| `DesignDocument` | always 4 KB or more | raw bytes only |
| `Contents` | mini in 8 of 15, regular in the rest | inflated to raw bytes when regular |
| `TRUEVIEW_ICON` | mini in `scene-wilcom` only | JPEG bytes when regular |
| `SummaryInformation`, `AUX_INFO`, `DESIGN_ICON` | always mini | not read |

### Design information property set

The stream is an OLE property set ([MS-OLEPS]) with one section. The file
carries its own names for the properties in the section's dictionary
(property 0), so the names below are the file's own words. Values in the
table are from `random1-wilcom.EMB`, `scene-wilcom.EMB` is in the tests too.

| Property | Name in the file | Type | Notes |
|---|---|---|---|
| 3 | number of colours | int32 | 10 in `random1-wilcom`, 3 in `scene-wilcom` |
| 4 | number of stops | int32 | |
| 5 | number of trims | int32 | |
| 6 | number of stitches | int32 | 156 and 147 |
| 7 | number of objects | int32 | |
| 8, 9 | thread length, bobbin length | double | unit unknown |
| 10, 11, 12, 13 | design left, right, up, down | int32 and double | unit and sign convention unknown |
| 14, 15 | end x, end y | int32 | |
| 16, 17 | design height, width | double | |
| 19 | embroidery machine name | string | "Melco" in the samples |
| 20, 18, 25, 28, 30 | unit conversion info, sequence list, intended version, actual creator version, infostore | blob | contents unknown |
| 21 | number of funtions in the file | int32 | spelled so in the file |
| 22, 23 | shortest, longest stitch in design | int32 | unit unknown |
| 24 | number of jumps per trim | int32 | |
| 26 | (no name in dictionary) | int32 | |
| 27 | number of colour changes | int32 | |
| 29 | filetype | int32 | 32 in the samples |
| 31 | fabricthickness | int32 | 180 |
| 32 | adjustbobbin | int32 | 100 |

The spec exposes the table and dictionary generically; it does not map
names to properties. The numbers above are not checked against the
original designs: for example `random1-wilcom.DST` has 30 stitches while
this set says 156 (the files may differ in how stitches are counted or may
not be the same design; unknown).

## Versions

All samples have the same container layout (CFB 3.62) and stream set. The
`-e1`, `-e15`, `-e18`, `-e2` and `-e2006` suffixes in the file names come
from the sample uploader; the files differ in size and in how their
streams are laid out, but there is no version field known that tells them
apart. Whether they are EMB versions (Wilcom's `e1`/`e15`... naming) is
Unverified.

## Units and coordinates

Unknown. The property set holds extents, end point and stitch lengths but
no unit is stated in the file.

## Open questions

- Layout of `Contents` and `DesignDocument` (where the stitches are).
- Mini-stream streams: `SummaryInformation` and `DESIGN_ICON` are described
  here but not parsed.
- The meaning and units of the numeric properties above.
- Whether other Wilcom versions use another directory order or more streams
  (the spec reads streams by directory index).
- Whether large designs use more FAT or directory sectors (the spec reads
  only the first of each and two directory sectors).

## Samples

See [`samples/MANIFEST.yaml`](samples/MANIFEST.yaml): 15 files from
EmbroidePy/samples (MIT, see [`samples/NOTICE`](samples/NOTICE)). The
expected values in `tests/` come from a separate reader written for this
purpose that follows the CFB sector chains and inflates the streams with
zlib; the property names come from the files.

## Sources consulted

_Format facts only — no code copied or translated._

- [MS-CFB] Compound File Binary File Format and [MS-OLEPS] OLE Property
  Set Data Structures, Microsoft's public specifications: container and
  property-set layout.
- The 15 EmbroidePy/samples `.EMB` files (MIT), inspected directly.
- pyembroidery and libembroidery were read; neither reads EMB.
