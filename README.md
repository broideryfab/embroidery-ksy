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
# Compiling and testing run on Node.js (no Java needed)
npm install

# Generate parsers with the npm kaitai-struct-compiler
tools/compile.sh python javascript

# Run sample tests
node tools/run_tests.js
```

The generated Python, Java and Go parsers are products for users; the
repository's compiler and tests run on Node. The one exception is the
compiler-warning check (`tools/check_specs.js`), which needs the JVM
compiler because the npm build does not report warnings.

### Downloads

Generated parsers (Python, JavaScript, Java, Go) and the specs are published
as zip files:

- **Latest pre-release** —
  [`/releases/tag/edge`](https://github.com/broideryfab/embroidery-ksy/releases/tag/edge).
  Rebuilt from `main` on every push, after CI passes. Always current, not
  stable; its title shows the commit.
- **Releases** —
  [`/releases`](https://github.com/broideryfab/embroidery-ksy/releases).
  Tagged versions (`vX.Y.Z`); the newest one is marked *Latest*.

### What CI checks

[CI](.github/workflows/ci.yml) runs on every push to any branch, on pull
requests, and on demand (Actions → CI → Run workflow). It uses the official
Kaitai Struct tools at the version in [`tools/KSC_VERSION`](tools/KSC_VERSION):
the npm `kaitai-struct-compiler` and `kaitai-struct` runtime.

1. **Warning check** — `tools/check_specs.js` compiles every `.ksy` for the
   release targets (Python, JavaScript, Java, Go) with the JVM compiler and
   fails on any compiler error *or warning*. This is the JVM compiler's only
   job in CI.
2. **Compile** — `tools/compile.sh python javascript` with the npm compiler
   (through `tools/ksc.js`).
3. **Tests** — `tools/run_tests.js --require-build`: layout, manifests,
   sha256; every generated JavaScript parser loads; every sample in a
   `samples/MANIFEST.yaml` parses, and the result matches `tests/*.json`
   (subset match).
4. **Parsed trees** — the full parsed tree of every sample as JSON, uploaded
   as the `parsed-json` artifact. See
   [CONTRIBUTING.md](CONTRIBUTING.md#reading-ci-results).

You can also open any `.ksy` file in the
[Kaitai Web IDE](https://ide.kaitai.io) together with a sample file.

## Formats

Priority: **1** launch · **2** soon after · **3** long tail ·
**Proprietary** source formats (preview/partial only) · **Colors** thread
color companion files.

| Spec | Extensions | Vendor | Priority | Status |
|---|---|---|---|---|
| [tajima_dst](formats/tajima_dst/) | .dst | Tajima | 1 | 🟡 Partial |
| [brother_pes](formats/brother_pes/) | .pes | Brother / Baby Lock | 1 | 🟡 Partial |
| [brother_pec](formats/brother_pec/) | .pec | Brother | 1 | 🟡 Partial |
| [janome_jef](formats/janome_jef/) | .jef | Janome / Elna | 1 | 🟡 Partial |
| [melco_exp](formats/melco_exp/) | .exp | Melco / Bernina | 1 | 🟡 Partial |
| [husqvarna_vp3](formats/husqvarna_vp3/) | .vp3 | Husqvarna Viking / Pfaff | 1 | 🟡 Partial |
| [singer_xxx](formats/singer_xxx/) | .xxx | Singer | 1 | 🟡 Partial |
| [husqvarna_hus](formats/husqvarna_hus/) | .hus | Husqvarna Viking | 2 | 🟡 Partial |
| [husqvarna_vip](formats/husqvarna_vip/) | .vip | Husqvarna Viking / Pfaff | 2 | 🟡 Partial |
| [husqvarna_shv](formats/husqvarna_shv/) | .shv | Husqvarna Viking | 2 | 🟡 Partial |
| [janome_sew](formats/janome_sew/) | .sew | Janome | 2 | 🟡 Partial |
| [barudan_u01](formats/barudan_u01/) | .u01, .u00 | Barudan | 2 | 🟡 Partial |
| [barudan_dsb](formats/barudan_dsb/) | .dsb | Barudan | 2 | 🟡 Partial |
| [zsk_dsz](formats/zsk_dsz/) | .dsz | ZSK | 2 | 🟡 Partial |
| [tajima_tbf](formats/tajima_tbf/) | .tbf | Tajima | 2 | 🟡 Partial |
| [pfaff_ksm](formats/pfaff_ksm/) | .ksm | Pfaff | 2 | 🟡 Partial |
| [pfaff_pcs](formats/pfaff_pcs/) | .pcs | Pfaff | 2 | 🟡 Partial |
| [happy_tap](formats/happy_tap/) | .tap | Happy | 2 | 🟡 Partial |
| [sunstar_dat](formats/sunstar_dat/) | .dat | Sunstar | 2 | 🟡 Partial |
| [barudan_dat](formats/barudan_dat/) | .dat | Barudan | 2 | 🟡 Partial |
| [toyota_10o](formats/toyota_10o/) | .10o | Toyota | 3 | 🟡 Partial |
| [toyota_100](formats/toyota_100/) | .100 | Toyota | 3 | 🟡 Partial |
| [bits_volts_bro](formats/bits_volts_bro/) | .bro | Bits & Volts | 3 | 🟡 Partial |
| [melco_cnd](formats/melco_cnd/) | .cnd | Melco | 3 | 🟡 Partial |
| [singer_csd](formats/singer_csd/) | .csd | Singer | 3 | 🟡 Partial |
| [melco_dem](formats/melco_dem/) | .dem | Melco | 3 | 🟡 Partial |
| [elna_emd](formats/elna_emd/) | .emd | Elna | 3 | 🟡 Partial |
| [eltac_exy](formats/eltac_exy/) | .exy | Eltac | 3 | 🟡 Partial |
| [sierra_eys](formats/sierra_eys/) | .eys | Sierra | 3 | 🔲 Stub |
| [fortron_fxy](formats/fortron_fxy/) | .fxy | Fortron | 3 | 🟡 Partial |
| [gold_thread_gt](formats/gold_thread_gt/) | .gt | Gold Thread | 3 | 🟡 Partial |
| [inbro_inb](formats/inbro_inb/) | .inb | Inbro | 3 | 🟡 Partial |
| [janome_jpx](formats/janome_jpx/) | .jpx | Janome | 3 | 🟡 Partial |
| [pfaff_max](formats/pfaff_max/) | .max | Pfaff | 3 | 🟡 Partial |
| [mitsubishi_mit](formats/mitsubishi_mit/) | .mit | Mitsubishi | 3 | 🟡 Partial |
| [ameco_new](formats/ameco_new/) | .new | Ameco | 3 | 🟡 Partial |
| [pfaff_pcd](formats/pfaff_pcd/) | .pcd | Pfaff | 3 | 🟡 Partial |
| [pfaff_pcm](formats/pfaff_pcm/) | .pcm | Pfaff | 3 | 🟡 Partial |
| [pfaff_pcq](formats/pfaff_pcq/) | .pcq | Pfaff | 3 | 🟡 Partial |
| [brother_pel](formats/brother_pel/) | .pel | Brother | 3 | 🟡 Partial |
| [brother_pem](formats/brother_pem/) | .pem | Brother | 3 | 🟡 Partial |
| [brother_phb](formats/brother_phb/) | .phb | Brother | 3 | 🟡 Partial |
| [brother_phc](formats/brother_phc/) | .phc | Brother | 3 | 🟡 Partial |
| [pfaff_spx](formats/pfaff_spx/) | .spx | Pfaff | 3 | 🟡 Partial |
| [sunstar_sst](formats/sunstar_sst/) | .sst | Sunstar | 3 | 🟡 Partial |
| [gunold_stc](formats/gunold_stc/) | .stc | Gunold | 3 | 🟡 Partial |
| [data_stitch_stx](formats/data_stitch_stx/) | .stx | Data Stitch | 3 | 🟡 Partial |
| [pfaff_t01](formats/pfaff_t01/) | .t01 | Pfaff | 3 | 🟡 Partial |
| [pfaff_t09](formats/pfaff_t09/) | .t09 | Pfaff | 3 | 🟡 Partial |
| [thredworks_thr](formats/thredworks_thr/) | .thr | ThredWorks | 3 | 🟡 Partial |
| [zeng_hsing_zhs](formats/zeng_hsing_zhs/) | .zhs | Zeng Hsing | 3 | 🟡 Partial |
| [zsk_zxy](formats/zsk_zxy/) | .zxy | ZSK | 3 | 🟡 Partial |
| [zsk_zsk](formats/zsk_zsk/) | .zsk | ZSK USA | 3 | 🟡 Partial |
| [wilcom_emb](formats/wilcom_emb/) | .emb | Wilcom | Proprietary | 🟡 Partial |
| [bernina_art](formats/bernina_art/) | .art | Bernina | Proprietary | 🟡 Partial |
| [melco_ofm](formats/melco_ofm/) | .ofm | Melco | Proprietary | 🟡 Partial |
| [pulse_pxf](formats/pulse_pxf/) | .pxf | Pulse | Proprietary | 🔲 Stub |
| [embird_edr](formats/embird_edr/) | .edr | Embird | Colors | 🟡 Partial |
| [color_inf](formats/color_inf/) | .inf | Various | Colors | 🟡 Partial |
| [color_rgb](formats/color_rgb/) | .rgb | Various | Colors | 🟡 Partial |

Status: 🔲 Stub · 🟡 Partial · 🟢 Complete (all known versions, tested).

## Contributing

Corrections, new findings and sample files you have the right to share are
welcome — see [CONTRIBUTING.md](CONTRIBUTING.md). Specs must be written from
format facts; never copied or translated from copyleft code.

## License

[MIT](LICENSE)
