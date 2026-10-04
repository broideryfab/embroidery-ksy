# embroidery-ksy

Open, machine-readable [Kaitai Struct](https://kaitai.io) specifications for
machine embroidery file formats — DST, PES, JEF, EXP, VP3 and more.

> 🚧 **Work in progress (pre-1.0).** Most formats are stubs. Specs and
> layouts may change without notice until 1.0.

Machine embroidery formats are mostly undocumented. This repository describes
them as `.ksy` specs, from which Kaitai Struct generates parsers for
JavaScript, Python, Java, Go, C++, Rust and other languages.

Maintained by [BroideryFab](https://broideryfab.com).

## Layout

Each format is self-contained:

```text
formats/<vendor>_<format>/
├── <vendor>_<format>.ksy   spec
├── README.md               notes: structure, versions, quirks, sources consulted
├── samples/                redistributable sample files + MANIFEST.yaml
└── tests/                  expected parse results: <sample-name>.json
```

Shared tooling lives in `tools/`, conventions in
[`docs/style-guide.md`](docs/style-guide.md).

## Usage

```bash
# Generate parsers (requires kaitai-struct-compiler + Java)
tools/compile.sh python javascript

# Run sample tests (requires Python 3, kaitaistruct, pyyaml)
python3 tools/run_tests.py
```

Generated parsers are also attached to each
[release](https://github.com/broideryfab/embroidery-ksy/releases).

You can also open any `.ksy` file in the
[Kaitai Web IDE](https://ide.kaitai.io) together with a sample file.

## Formats

Priority: **1** launch · **2** soon after · **3** long tail ·
**Proprietary** source formats (preview/partial only) · **Colors** thread
color companion files.

| Spec | Extensions | Vendor | Priority | Status |
|---|---|---|---|---|
| [tajima_dst](formats/tajima_dst/) | .dst | Tajima | 1 | 🔲 Stub |
| [brother_pes](formats/brother_pes/) | .pes | Brother / Baby Lock | 1 | 🔲 Stub |
| [brother_pec](formats/brother_pec/) | .pec | Brother | 1 | 🔲 Stub |
| [janome_jef](formats/janome_jef/) | .jef | Janome / Elna | 1 | 🔲 Stub |
| [melco_exp](formats/melco_exp/) | .exp | Melco / Bernina | 1 | 🔲 Stub |
| [husqvarna_vp3](formats/husqvarna_vp3/) | .vp3 | Husqvarna Viking / Pfaff | 1 | 🔲 Stub |
| [singer_xxx](formats/singer_xxx/) | .xxx | Singer | 1 | 🔲 Stub |
| [husqvarna_hus](formats/husqvarna_hus/) | .hus | Husqvarna Viking | 2 | 🔲 Stub |
| [husqvarna_vip](formats/husqvarna_vip/) | .vip | Husqvarna Viking / Pfaff | 2 | 🔲 Stub |
| [husqvarna_shv](formats/husqvarna_shv/) | .shv | Husqvarna Viking | 2 | 🔲 Stub |
| [janome_sew](formats/janome_sew/) | .sew | Janome | 2 | 🔲 Stub |
| [barudan_u01](formats/barudan_u01/) | .u01, .u00 | Barudan | 2 | 🔲 Stub |
| [barudan_dsb](formats/barudan_dsb/) | .dsb | Barudan | 2 | 🔲 Stub |
| [zsk_dsz](formats/zsk_dsz/) | .dsz | ZSK | 2 | 🔲 Stub |
| [tajima_tbf](formats/tajima_tbf/) | .tbf | Tajima | 2 | 🔲 Stub |
| [pfaff_ksm](formats/pfaff_ksm/) | .ksm | Pfaff | 2 | 🔲 Stub |
| [pfaff_pcs](formats/pfaff_pcs/) | .pcs | Pfaff | 2 | 🔲 Stub |
| [happy_tap](formats/happy_tap/) | .tap | Happy | 2 | 🔲 Stub |
| [sunstar_dat](formats/sunstar_dat/) | .dat | Sunstar | 2 | 🔲 Stub |
| [barudan_dat](formats/barudan_dat/) | .dat | Barudan | 2 | 🔲 Stub |
| [toyota_10o](formats/toyota_10o/) | .10o | Toyota | 3 | 🔲 Stub |
| [toyota_100](formats/toyota_100/) | .100 | Toyota | 3 | 🔲 Stub |
| [bits_volts_bro](formats/bits_volts_bro/) | .bro | Bits & Volts | 3 | 🔲 Stub |
| [melco_cnd](formats/melco_cnd/) | .cnd | Melco | 3 | 🔲 Stub |
| [singer_csd](formats/singer_csd/) | .csd | Singer | 3 | 🔲 Stub |
| [melco_dem](formats/melco_dem/) | .dem | Melco | 3 | 🔲 Stub |
| [elna_emd](formats/elna_emd/) | .emd | Elna | 3 | 🔲 Stub |
| [eltac_exy](formats/eltac_exy/) | .exy | Eltac | 3 | 🔲 Stub |
| [sierra_eys](formats/sierra_eys/) | .eys | Sierra | 3 | 🔲 Stub |
| [fortron_fxy](formats/fortron_fxy/) | .fxy | Fortron | 3 | 🔲 Stub |
| [gold_thread_gt](formats/gold_thread_gt/) | .gt | Gold Thread | 3 | 🔲 Stub |
| [inbro_inb](formats/inbro_inb/) | .inb | Inbro | 3 | 🔲 Stub |
| [janome_jpx](formats/janome_jpx/) | .jpx | Janome | 3 | 🔲 Stub |
| [pfaff_max](formats/pfaff_max/) | .max | Pfaff | 3 | 🔲 Stub |
| [mitsubishi_mit](formats/mitsubishi_mit/) | .mit | Mitsubishi | 3 | 🔲 Stub |
| [ameco_new](formats/ameco_new/) | .new | Ameco | 3 | 🔲 Stub |
| [pfaff_pcd](formats/pfaff_pcd/) | .pcd | Pfaff | 3 | 🔲 Stub |
| [pfaff_pcm](formats/pfaff_pcm/) | .pcm | Pfaff | 3 | 🔲 Stub |
| [pfaff_pcq](formats/pfaff_pcq/) | .pcq | Pfaff | 3 | 🔲 Stub |
| [brother_pel](formats/brother_pel/) | .pel | Brother | 3 | 🔲 Stub |
| [brother_pem](formats/brother_pem/) | .pem | Brother | 3 | 🔲 Stub |
| [brother_phb](formats/brother_phb/) | .phb | Brother | 3 | 🔲 Stub |
| [brother_phc](formats/brother_phc/) | .phc | Brother | 3 | 🔲 Stub |
| [pfaff_spx](formats/pfaff_spx/) | .spx | Pfaff | 3 | 🔲 Stub |
| [sunstar_sst](formats/sunstar_sst/) | .sst | Sunstar | 3 | 🔲 Stub |
| [gunold_stc](formats/gunold_stc/) | .stc | Gunold | 3 | 🔲 Stub |
| [data_stitch_stx](formats/data_stitch_stx/) | .stx | Data Stitch | 3 | 🔲 Stub |
| [pfaff_t01](formats/pfaff_t01/) | .t01 | Pfaff | 3 | 🔲 Stub |
| [pfaff_t09](formats/pfaff_t09/) | .t09 | Pfaff | 3 | 🔲 Stub |
| [thredworks_thr](formats/thredworks_thr/) | .thr | ThredWorks | 3 | 🔲 Stub |
| [zeng_hsing_zhs](formats/zeng_hsing_zhs/) | .zhs | Zeng Hsing | 3 | 🔲 Stub |
| [zsk_zxy](formats/zsk_zxy/) | .zxy | ZSK | 3 | 🔲 Stub |
| [zsk_zsk](formats/zsk_zsk/) | .zsk | ZSK USA | 3 | 🔲 Stub |
| [wilcom_emb](formats/wilcom_emb/) | .emb | Wilcom | Proprietary | 🔲 Stub |
| [bernina_art](formats/bernina_art/) | .art | Bernina | Proprietary | 🔲 Stub |
| [melco_ofm](formats/melco_ofm/) | .ofm | Melco | Proprietary | 🔲 Stub |
| [pulse_pxf](formats/pulse_pxf/) | .pxf | Pulse | Proprietary | 🔲 Stub |
| [embird_edr](formats/embird_edr/) | .edr | Embird | Colors | 🔲 Stub |
| [color_inf](formats/color_inf/) | .inf | Various | Colors | 🔲 Stub |
| [color_rgb](formats/color_rgb/) | .rgb | Various | Colors | 🔲 Stub |

Status: 🔲 Stub · 🟡 Partial · 🟢 Complete (all known versions, tested).

## Contributing

Corrections, new findings and sample files you have the right to share are
welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Specs must be written from
format facts; never copied or translated from copyleft code.

## License

[MIT](LICENSE)
