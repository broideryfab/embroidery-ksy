# Spec style guide

Conventions for every `.ksy` file in this repository.

## Naming

- Format id = directory name = file name: `<vendor>_<format>`, snake_case
  (`tajima_dst`, `brother_pes`). Ids must match `^[a-z][a-z0-9_]*$`.
- Fields, types, enums and instances: snake_case, descriptive
  (`stitch_count`, not `sc`).
- Unknown fields: `unknown_<hex offset>` (e.g. `unknown_0x1c`) with
  `doc: Unknown.` plus any observations.
- Reserved / padding: `reserved_<hex offset>` or `padding`.

## `meta`

Required:

```yaml
meta:
  id: tajima_dst
  title: Tajima DST embroidery format
  file-extension: dst          # or a list: [u01, u00]
  license: MIT
  endian: le                   # when the format has multi-byte integers
```

Top level also has `doc` (one-paragraph summary) and `doc-ref` (link to the
format's README in this repository).

## Structure

- Use `contents` for magic bytes and fixed signatures.
- Every `seq` field gets a `doc`, including units: "Width in 0.1 mm units."
- Use `enum` for command codes, hoop codes, thread brands.
- Use `switch-on` to branch on version fields; keep one spec per format,
  not one per version.
- Use `instances` for values at known offsets and for simple derived values
  (e.g. decoding a DST delta from its bits).
- Mark data whose meaning is uncertain in `doc` with "Unverified:".

## Scope

Specs describe the **file structure**, not embroidery semantics.

- ✅ Header fields, sections, color tables, raw stitch records, decoded
  per-record deltas and flags.
- ❌ Cumulative absolute coordinates, trim inference from jump sequences,
  thread matching, rendering. These belong in consuming applications.

## Shared types

Put a type in `formats/_common/` only when a second format needs it. Import
with a relative path: `imports: [../_common/<name>]`.

## Samples

- Small and purpose-built: one file demonstrates one feature
  (`square-10mm.dst`, `two-colors.pes`, `long-jump.dst`).
- Name files in kebab-case and describe them in `MANIFEST.yaml`.
- Only files you created or that are licensed for redistribution.
  Never purchased, commercial or customer designs.
- Prefer one sample per known format version.

## Tests

`tests/<sample-stem>.json` holds the expected parse result. It is a subset
match: list only the fields worth asserting.

```json
{
  "header": { "label": "SQUARE" },
  "records": [
    { "dx": 0, "dy": 0 },
    { "dx": 100, "dy": 0 }
  ]
}
```

- Objects: keys are read as attributes (seq fields and instances).
- Lists: length and every element must match.
- Bytes: lowercase hex string. Enums: member name.

## Format README

Every `formats/<id>/README.md` keeps the template sections, and ends with
**Sources consulted**: every reference used, format facts only. Never copy or
translate code from copyleft projects.
