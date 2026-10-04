#!/usr/bin/env python3
"""Check format directories and test specs against their samples.

For every formats/<id>/:
  - layout: <id>.ksy (with matching meta id), README.md,
    samples/MANIFEST.yaml, tests/
  - every sample file is listed in MANIFEST.yaml with license and sha256
  - every sample has tests/<sample-stem>.json
  - the generated Python parser (build/python/<id>.py) parses the sample and
    the result matches the expected JSON

Expected JSON is a subset match: only the listed fields are checked.
  - objects: each key is read as an attribute (seq fields and instances)
  - lists:   length and every element must match
  - bytes:   compared as lowercase hex string
  - enums:   compared by name

Usage: python3 tools/run_tests.py [--require-build] [format_id ...]
"""

import enum
import hashlib
import importlib
import json
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
FORMATS = ROOT / "formats"
BUILD = ROOT / "build" / "python"
ID_RE = re.compile(r"^[a-z][a-z0-9_]*$")


def class_name(format_id):
    return "".join(part[:1].upper() + part[1:] for part in format_id.split("_"))


def match(actual, expected, where, errors):
    if isinstance(expected, dict):
        for key, value in expected.items():
            if isinstance(actual, dict):
                present, child = key in actual, actual.get(key)
            else:
                present, child = hasattr(actual, key), getattr(actual, key, None)
            if not present:
                errors.append(f"{where}.{key}: missing")
                continue
            match(child, value, f"{where}.{key}", errors)
    elif isinstance(expected, list):
        if not isinstance(actual, (list, tuple)):
            errors.append(f"{where}: expected list, got {type(actual).__name__}")
            return
        if len(actual) != len(expected):
            errors.append(f"{where}: expected {len(expected)} items, got {len(actual)}")
            return
        for i, (a, e) in enumerate(zip(actual, expected)):
            match(a, e, f"{where}[{i}]", errors)
    else:
        if isinstance(actual, (bytes, bytearray)):
            actual = actual.hex()
        elif isinstance(actual, enum.Enum):
            actual = actual.name
        if actual != expected:
            errors.append(f"{where}: expected {expected!r}, got {actual!r}")


def check_format(fdir, yaml, have_build):
    fid = fdir.name
    errors = []
    tested = 0

    if not ID_RE.match(fid):
        errors.append(f"directory name {fid!r} is not a valid Kaitai id")
    spec = fdir / f"{fid}.ksy"
    if not spec.is_file():
        errors.append(f"missing {spec.name}")
    elif not re.search(rf"^\s+id:\s*{re.escape(fid)}\s*$", spec.read_text(), re.M):
        errors.append(f"{spec.name}: meta id must be {fid!r}")
    for required in ("README.md", "samples/MANIFEST.yaml", "tests"):
        if not (fdir / required).exists():
            errors.append(f"missing {required}")
    if errors:
        return errors, tested

    manifest = yaml.safe_load((fdir / "samples" / "MANIFEST.yaml").read_text()) or {}
    entries = manifest.get("samples") or []
    listed = set()
    for entry in entries:
        name = entry.get("file")
        if not name:
            errors.append("MANIFEST.yaml: entry without 'file'")
            continue
        listed.add(name)
        path = fdir / "samples" / name
        if not path.is_file():
            errors.append(f"MANIFEST.yaml: {name} does not exist")
            continue
        for field in ("license", "sha256"):
            if not entry.get(field):
                errors.append(f"MANIFEST.yaml: {name} has no {field}")
        digest = hashlib.sha256(path.read_bytes()).hexdigest()
        if entry.get("sha256") and entry["sha256"] != digest:
            errors.append(f"MANIFEST.yaml: {name} sha256 mismatch (actual {digest})")

    for path in sorted((fdir / "samples").iterdir()):
        if path.name != "MANIFEST.yaml" and not path.name.startswith(".") and path.name not in listed:
            errors.append(f"samples/{path.name} is not listed in MANIFEST.yaml")

    if not listed or not have_build:
        return errors, tested

    module = importlib.import_module(fid)
    cls = getattr(module, class_name(fid))
    for name in sorted(listed):
        expected_path = fdir / "tests" / f"{Path(name).stem}.json"
        if not expected_path.is_file():
            errors.append(f"samples/{name} has no tests/{expected_path.name}")
            continue
        data = (fdir / "samples" / name).read_bytes()
        try:
            parsed = cls.from_bytes(data)
        except Exception as exc:  # parser errors are test failures
            errors.append(f"samples/{name}: parse error: {exc}")
            continue
        match(parsed, json.loads(expected_path.read_text()), name, errors)
        tested += 1
    return errors, tested


def main(argv):
    require_build = "--require-build" in argv
    selected = [a for a in argv if not a.startswith("--")]

    try:
        import yaml
    except ImportError:
        sys.exit("pyyaml is required: pip install -r tools/requirements.txt")

    have_build = BUILD.is_dir()
    if require_build and not have_build:
        sys.exit("build/python not found — run tools/compile.sh python first")
    if have_build:
        sys.path.insert(0, str(BUILD))
    else:
        print("note: build/python not found — checking layout and manifests only\n")

    dirs = sorted(d for d in FORMATS.iterdir() if d.is_dir() and not d.name.startswith("_"))
    if selected:
        dirs = [d for d in dirs if d.name in selected]

    failed = 0
    total_tested = 0
    for fdir in dirs:
        errors, tested = check_format(fdir, yaml, have_build)
        total_tested += tested
        if errors:
            failed += 1
            print(f"FAIL {fdir.name}")
            for err in errors:
                print(f"     {err}")
        else:
            print(f"ok   {fdir.name}" + (f" ({tested} samples)" if tested else ""))

    print(f"\n{len(dirs)} formats, {total_tested} samples tested, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
