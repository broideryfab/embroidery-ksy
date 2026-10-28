# Contributing to embroidery-ksy

Thanks for helping document embroidery formats. Read
[`docs/style-guide.md`](docs/style-guide.md) first.

## Ways to help

- **Report a parsing problem** — use the "Format issue" template. Include the
  format version and the software or machine that produced the file.
- **Share a sample file** — only if you have the right to redistribute it
  (you made it, or its license allows it). Never purchased or customer designs.
- **Improve a spec** — fill in a stub, add a version, resolve an unknown field.

## Working on a format

Everything for a format lives in `formats/<id>/`:

1. Edit `<id>.ksy`.
2. Document findings in `README.md` (structure, versions, open questions).
3. Add samples to `samples/` and list each in `samples/MANIFEST.yaml`
   (license and sha256 required — `shasum -a 256 <file>`).
4. Add `tests/<sample-stem>.json` with the expected parse result.
5. Update the format's status in the root `README.md` table.

Check locally (requires Node.js; `npm install` brings the compiler):

```bash
npm install
tools/compile.sh javascript
node tools/run_tests.js <id>
```

The npm compiler reports errors but not warnings. CI also fails on
warnings, using the JVM
[kaitai-struct-compiler](https://kaitai.io/#download) for that one check. To
run it locally, install the JVM compiler at the version in
`tools/KSC_VERSION` (needs Java) and run:

```bash
node tools/check_specs.js
```

If you have none of these tools, push your branch: CI runs the same checks.

Or open the spec and a sample in the [Kaitai Web IDE](https://ide.kaitai.io).

## Reading CI results

CI runs on every push to any branch, on pull requests, and on demand
(Actions → CI → Run workflow). Nothing needs to be installed on your
machine for it. The `test` job has these steps:

| Step | Fails when |
|---|---|
| Read compiler version | `kaitai-struct-compiler` or `kaitai-struct` in `package.json` differs from `tools/KSC_VERSION` |
| Install npm dependencies | `npm install` fails |
| Check specs for warnings (JVM compiler) | any `.ksy` gives a compiler error or warning for Python, JavaScript, Java or Go; the only step that uses the JVM compiler |
| Compile all specs (npm compiler) | `tools/compile.sh python javascript` fails |
| Test specs against samples | layout, manifest or sha256 problems, a generated parser that does not load, a sample that throws while parsing, or a mismatch with `tests/*.json` |

Steps after the spec check still run when an earlier one fails, so a single
run shows every problem. Each failing line names the spec or sample.

**Parsed trees.** Open the run's summary page and download the
`parsed-json` artifact (kept 30 days). It holds
`<format>/<sample-file>.json` for every tested sample: the whole tree the
JavaScript parser produced, with every field and instance (an instance that
throws shows as `{"_error": "…"}`). Bytes are hex strings. Keys are the
JavaScript property names (camelCase); `tests/*.json` accepts these as well
as the `.ksy` ids, so you can copy values straight across. Use it to check
values your tests do not cover, but take expected values from sources other
than our own parser (see the style guide).

To bump the compiler, change `tools/KSC_VERSION` and both
`kaitai-struct-compiler` and `kaitai-struct` in `package.json` together.

**npm lockfile.** There is no `package-lock.json` yet, so CI runs
`npm install` rather than `npm ci`. Each run uploads the lockfile it made as
the `package-lock` artifact: commit that file, then switch CI to `npm ci`.

## Releases

Both kinds are published by [CI](.github/workflows/ci.yml), only after all
checks pass:

- **Every push to `main`** rebuilds the single pre-release `edge`
  (`/releases/tag/edge`). The `edge` tag moves to the new commit and all
  assets are replaced; the notes give the commit sha and date. It is never
  marked *Latest*.
- **A pushed `v*` tag** publishes a full release with generated release
  notes, marked *Latest*. To cut one from the current `main`:

  ```bash
  git tag vX.Y.Z
  git push origin vX.Y.Z
  ```

  If the checks fail for that commit, nothing is released; fix it on `main`,
  then delete and re-push the tag.

## Adding a new format

Copy an existing stub directory, rename the directory and `.ksy` file to the
new id, update `meta`, and add a row to the root `README.md` table.

## Clean-room rule

Specs must be written from format knowledge, public documentation and
observation of files. **Do not copy or translate code from GPL/AGPL or other
copyleft projects**, and do not use proprietary SDKs or documentation you are
not allowed to share. List every reference you used under
"Sources consulted" in the format's README.

## Pull requests

- One format or topic per pull request.
- Describe what changed and how you verified it (which samples, which tool).
- By contributing you agree your contribution is licensed under the
  [MIT License](LICENSE).
