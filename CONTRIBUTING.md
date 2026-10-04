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

Check locally (requires
[kaitai-struct-compiler](https://kaitai.io/#download), Java and Python 3):

```bash
pip install -r tools/requirements.txt
tools/compile.sh python
python3 tools/run_tests.py <id>
```

Or open the spec and a sample in the [Kaitai Web IDE](https://ide.kaitai.io).
CI runs the full check on every pull request.

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
