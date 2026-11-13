# Changelog

All notable changes to this project are documented here.
Versions follow [Semantic Versioning](https://semver.org); before 1.0, specs
may change without notice.

## [Unreleased]

### Added

- Repository layout: per-format directories with spec, notes, samples and
  tests.
- Stubs for 60 formats (tiers 1–3, proprietary source formats, thread color
  companions).
- Tooling: `tools/compile.sh`, `tools/run_tests.js`; CI workflow with releases.
- Spec style guide and contributing guide.
- `tajima_dst`: first full spec — 512-byte header fields, 3-byte stitch
  records with decoded `dx`, `dy` and command flags, trailer. Four MIT
  samples from EmbroidePy/samples (Wilcom, Premier+, My Editor) with NOTICE
  and subset tests. Status 🟡 Partial until purpose-built samples land.
- Tier 1 specs, each 🟡 Partial with README notes, MIT samples
  (MANIFEST + NOTICE) and subset tests: `brother_pec`, `brother_pes`,
  `janome_jef`, `melco_exp`, `husqvarna_vp3`, `singer_xxx`.
- Tier 2 specs, 🟡 Partial: `husqvarna_hus`, `husqvarna_vip`,
  `husqvarna_shv`, `janome_sew`, `barudan_u01`, `barudan_dsb`,
  `barudan_dat`, `zsk_dsz`, `tajima_tbf`, `pfaff_ksm`, `pfaff_pcs`,
  `happy_tap`, `sunstar_dat`. `barudan_dat` and `sunstar_dat` have no
  samples or tests yet (no redistributable files).
- Tier 3, proprietary and colour-companion specs, 🟡 Partial: `toyota_10o`,
  `toyota_100`, `pfaff_pcm`, `pfaff_pcq`, `pfaff_pcd`, `pfaff_max`,
  `pfaff_spx`, `pfaff_t01`, `pfaff_t09`, `bits_volts_bro`, `inbro_inb`,
  `data_stitch_stx`, `singer_csd`, `sunstar_sst`, `elna_emd`, `embird_edr`,
  `color_inf`, `color_rgb`, `brother_pel`, `brother_pem`, `brother_phb`,
  `brother_phc`, `janome_jpx`, `melco_cnd`, `melco_dem`, `eltac_exy`,
  `fortron_fxy`, `gold_thread_gt`, `mitsubishi_mit`, `ameco_new`,
  `gunold_stc`, `zeng_hsing_zhs`, `zsk_zxy`, `zsk_zsk`, `thredworks_thr`,
  `wilcom_emb`, `bernina_art` and `melco_ofm` (the last two container-only).
  Formats without samples have no tests. `sierra_eys` and `pulse_pxf` stay
  stubs.
- Test runner: list elements can be checked by index
  (`"records": {"0": …, "-1": …}`); `samples/NOTICE` is allowed.
- CI runs on every branch push and on demand, with kaitai-struct-compiler
  0.11 (version kept in `tools/KSC_VERSION`). It fails on any compiler
  error or warning for any release target (`tools/check_specs.js`) and
  uploads the parsed tree of every sample as the `parsed-json` artifact.

### Changed

- Tests and tooling are JavaScript (Node, `package.json`):
  `tools/run_tests.js` and `tools/check_specs.js` replace the Python
  scripts and `tools/requirements.txt`. Samples are tested with the
  generated JavaScript parsers; test keys stay `.ksy` ids. Enums in
  `tests/*.json` are now integer values. Python remains a compile target
  for the released parsers.
- The compiler is the npm `kaitai-struct-compiler` (Scala.js build), run
  through `tools/ksc.js` by `tools/compile.sh` in CI and releases. The JVM
  compiler is used only for the warning check, since the npm build does not
  report warnings.
- Releases: every push to `main` republishes the rolling `edge`
  pre-release (assets replaced, tag moved, never *Latest*); a pushed `v*`
  tag publishes a full release marked *Latest*. Both run only after the CI
  checks pass; `release.yml` is folded into `ci.yml`.
