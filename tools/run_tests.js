#!/usr/bin/env node
// Check format directories and test specs against their samples.
//
// For every formats/<id>/:
//   - layout: <id>.ksy (with matching meta id), README.md,
//     samples/MANIFEST.yaml, tests/
//   - every sample file is listed in MANIFEST.yaml with license and sha256
//   - every sample has tests/<sample-stem>.json
//   - the generated JavaScript parser (build/javascript/<Class>.js) parses
//     the sample, every field and instance can be read, and the result
//     matches the expected JSON
// Every generated parser in build/javascript/ must also load.
//
// Expected JSON is a subset match: only the listed fields are checked.
//   - objects: each key is a .ksy id (snake_case) or the parser's camelCase
//     property name (seq fields and instances)
//   - lists:   length and every element must match
//   - list as object with index keys ("0", "-1"): only those elements
//   - bytes:   compared as lowercase hex string
//   - enums:   compared by integer value (the JavaScript parsers keep
//              enums as numbers)
//
// Usage: node tools/run_tests.js [--require-build] [--dump <dir>] [format_id ...]
//          --dump writes the full parsed tree of each tested sample to
//          <dir>/<id>/<sample-file>.json
//        node tools/run_tests.js --list-samples [format_id ...]
//          prints "<id> <path>" (tab-separated) per sample
// Needs: npm install (js-yaml, kaitai-struct); tools/compile.sh javascript

"use strict";

const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const FORMATS = path.join(ROOT, "formats");
const BUILD = path.join(ROOT, "build", "javascript");
const ID_RE = /^[a-z][a-z0-9_]*$/;

let yaml;
try {
  yaml = require("js-yaml");
} catch (err) {
  console.error("js-yaml is required: npm install");
  process.exit(1);
}

function className(formatId) {
  return formatId
    .split("_")
    .map((part) => part.slice(0, 1).toUpperCase() + part.slice(1))
    .join("");
}

// .ksy id -> generated JavaScript property name (lowerCamelCase).
function camel(id) {
  return id.replace(/_([a-z0-9])/g, (_, c) => c.toUpperCase());
}

function isObject(value) {
  return value !== null && typeof value === "object";
}

function typeName(value) {
  if (value === null) return "null";
  if (Array.isArray(value)) return "list";
  if (isObject(value)) return value.constructor ? value.constructor.name : "object";
  return typeof value;
}

function show(value) {
  return typeof value === "string" ? JSON.stringify(value) : String(value);
}

function match(actual, expected, where, errors) {
  if (isObject(expected) && !Array.isArray(expected)) {
    for (const [key, value] of Object.entries(expected)) {
      let present = false;
      let child;
      if (Array.isArray(actual) && /^-?\d+$/.test(key)) {
        const index = Number(key);
        present = index >= -actual.length && index < actual.length;
        if (present) child = actual[index < 0 ? actual.length + index : index];
      } else if (isObject(actual)) {
        const prop = key in actual ? key : camel(key);
        present = prop in actual;
        if (present) child = actual[prop];
      }
      if (!present) {
        errors.push(`${where}.${key}: missing`);
        continue;
      }
      match(child, value, `${where}.${key}`, errors);
    }
  } else if (Array.isArray(expected)) {
    if (!Array.isArray(actual)) {
      errors.push(`${where}: expected list, got ${typeName(actual)}`);
      return;
    }
    if (actual.length !== expected.length) {
      errors.push(`${where}: expected ${expected.length} items, got ${actual.length}`);
      return;
    }
    expected.forEach((e, i) => match(actual[i], e, `${where}[${i}]`, errors));
  } else {
    if (actual instanceof Uint8Array) {
      actual = Buffer.from(actual).toString("hex");
    }
    if (actual !== expected) {
      errors.push(`${where}: expected ${show(expected)}, got ${show(actual)}`);
    }
  }
}

// Read seq fields (own properties) and instances (prototype getters) so
// lazy instances are evaluated too. Keys starting with "_" are internals.
function walk(obj, seen) {
  if (!isObject(obj) || ArrayBuffer.isView(obj) || seen.has(obj)) {
    return;
  }
  seen.add(obj);
  if (Array.isArray(obj)) {
    obj.forEach((value) => walk(value, seen));
    return;
  }
  for (const key of Object.keys(obj)) {
    if (!key.startsWith("_")) walk(obj[key], seen);
  }
  const descriptors = Object.getOwnPropertyDescriptors(Object.getPrototypeOf(obj));
  for (const [key, desc] of Object.entries(descriptors)) {
    if (desc.get && !key.startsWith("_")) walk(obj[key], seen);
  }
}

// Same traversal as walk(), building a JSON-ready tree: bytes as hex,
// properties under their JavaScript names, a failing instance as
// {"_error": message}.
function toPlain(value, seen) {
  if (value instanceof Uint8Array) return Buffer.from(value).toString("hex");
  if (typeof value === "bigint") return value.toString();
  if (!isObject(value)) return value;
  if (seen.has(value)) return "[cycle]";
  seen.add(value);
  if (Array.isArray(value)) return value.map((v) => toPlain(v, seen));
  const out = {};
  for (const key of Object.keys(value)) {
    if (!key.startsWith("_")) out[key] = toPlain(value[key], seen);
  }
  const descriptors = Object.getOwnPropertyDescriptors(Object.getPrototypeOf(value));
  for (const [key, desc] of Object.entries(descriptors)) {
    if (!desc.get || key.startsWith("_")) continue;
    try {
      out[key] = toPlain(value[key], seen);
    } catch (err) {
      out[key] = { _error: err.message || String(err) };
    }
  }
  return out;
}

// ksc 0.11 exports {ClassName: class}; ksc 0.10 exported the class itself.
function loadParser(name) {
  const module = require(path.join(BUILD, `${name}.js`));
  const cls = typeof module === "function" ? module : module[name];
  if (typeof cls !== "function") {
    throw new Error(`${name}.js does not export ${name}`);
  }
  return cls;
}

function formatDirs(selected) {
  return fs
    .readdirSync(FORMATS, { withFileTypes: true })
    .filter((d) => d.isDirectory() && !d.name.startsWith("_"))
    .map((d) => d.name)
    .sort()
    .filter((name) => selected.length === 0 || selected.includes(name));
}

function readManifest(fdir) {
  const file = path.join(fdir, "samples", "MANIFEST.yaml");
  return (yaml.load(fs.readFileSync(file, "utf8")) || {}).samples || [];
}

function checkFormat(fid, haveBuild, KaitaiStream, dumpDir) {
  const fdir = path.join(FORMATS, fid);
  const errors = [];
  let tested = 0;

  if (!ID_RE.test(fid)) {
    errors.push(`directory name ${show(fid)} is not a valid Kaitai id`);
  }
  const spec = path.join(fdir, `${fid}.ksy`);
  if (!fs.existsSync(spec) || !fs.statSync(spec).isFile()) {
    errors.push(`missing ${fid}.ksy`);
  } else {
    const escaped = fid.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    if (!new RegExp(`^\\s+id:\\s*${escaped}\\s*$`, "m").test(fs.readFileSync(spec, "utf8"))) {
      errors.push(`${fid}.ksy: meta id must be ${show(fid)}`);
    }
  }
  for (const required of ["README.md", "samples/MANIFEST.yaml", "tests"]) {
    if (!fs.existsSync(path.join(fdir, required))) {
      errors.push(`missing ${required}`);
    }
  }
  if (errors.length) {
    return { errors, tested };
  }

  const listed = new Set();
  for (const entry of readManifest(fdir)) {
    const name = entry && entry.file;
    if (!name) {
      errors.push("MANIFEST.yaml: entry without 'file'");
      continue;
    }
    listed.add(name);
    const file = path.join(fdir, "samples", name);
    if (!fs.existsSync(file) || !fs.statSync(file).isFile()) {
      errors.push(`MANIFEST.yaml: ${name} does not exist`);
      continue;
    }
    for (const field of ["license", "sha256"]) {
      if (!entry[field]) {
        errors.push(`MANIFEST.yaml: ${name} has no ${field}`);
      }
    }
    const digest = crypto.createHash("sha256").update(fs.readFileSync(file)).digest("hex");
    if (entry.sha256 && entry.sha256 !== digest) {
      errors.push(`MANIFEST.yaml: ${name} sha256 mismatch (actual ${digest})`);
    }
  }

  for (const name of fs.readdirSync(path.join(fdir, "samples")).sort()) {
    if (!["MANIFEST.yaml", "NOTICE"].includes(name) && !name.startsWith(".") && !listed.has(name)) {
      errors.push(`samples/${name} is not listed in MANIFEST.yaml`);
    }
  }

  if (listed.size === 0 || !haveBuild) {
    return { errors, tested };
  }

  let Parser;
  try {
    Parser = loadParser(className(fid));
  } catch (err) {
    errors.push(`cannot load parser: ${err.message}`);
    return { errors, tested };
  }
  for (const name of [...listed].sort()) {
    const stem = path.basename(name, path.extname(name));
    const expectedPath = path.join(fdir, "tests", `${stem}.json`);
    if (!fs.existsSync(expectedPath)) {
      errors.push(`samples/${name} has no tests/${stem}.json`);
      continue;
    }
    const data = fs.readFileSync(path.join(fdir, "samples", name));
    let parsed;
    try {
      const buffer = data.buffer.slice(data.byteOffset, data.byteOffset + data.byteLength);
      parsed = new Parser(new KaitaiStream(buffer));
      walk(parsed, new Set());
    } catch (err) {
      // parser errors are test failures
      errors.push(`samples/${name}: parse error: ${err.message || err}`);
      continue;
    }
    match(parsed, JSON.parse(fs.readFileSync(expectedPath, "utf8")), name, errors);
    tested++;
    if (dumpDir) {
      const out = path.join(dumpDir, fid, `${name}.json`);
      fs.mkdirSync(path.dirname(out), { recursive: true });
      fs.writeFileSync(out, JSON.stringify(toPlain(parsed, new Set()), null, 2) + "\n");
    }
  }
  return { errors, tested };
}

function listSamples(selected) {
  for (const fid of formatDirs(selected)) {
    const fdir = path.join(FORMATS, fid);
    if (!fs.existsSync(path.join(fdir, "samples", "MANIFEST.yaml"))) continue;
    for (const entry of readManifest(fdir)) {
      if (entry && entry.file) {
        console.log(`${fid}\t${path.relative(ROOT, path.join(fdir, "samples", entry.file))}`);
      }
    }
  }
  return 0;
}

function main(argv) {
  let dumpDir = null;
  const flags = [];
  const selected = [];
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === "--dump") {
      if (i + 1 >= argv.length) {
        console.error("--dump needs a directory");
        return 1;
      }
      dumpDir = path.resolve(argv[++i]);
    } else if (argv[i].startsWith("--")) {
      flags.push(argv[i]);
    } else {
      selected.push(argv[i]);
    }
  }
  if (flags.includes("--list-samples")) {
    return listSamples(selected);
  }
  const requireBuild = flags.includes("--require-build");

  const haveBuild = fs.existsSync(BUILD) && fs.statSync(BUILD).isDirectory();
  if (requireBuild && !haveBuild) {
    console.error("build/javascript not found — run tools/compile.sh javascript first");
    return 1;
  }

  let failed = 0;
  let KaitaiStream = null;
  if (haveBuild) {
    KaitaiStream = require("kaitai-struct/KaitaiStream");
    const generated = fs.readdirSync(BUILD).filter((f) => f.endsWith(".js")).sort();
    for (const file of generated) {
      try {
        loadParser(path.basename(file, ".js"));
      } catch (err) {
        failed++;
        console.log(`FAIL build/javascript/${file}\n     cannot load: ${err.message}`);
      }
    }
  } else {
    console.log("note: build/javascript not found — checking layout and manifests only\n");
  }

  const dirs = formatDirs(selected);
  let totalTested = 0;
  for (const fid of dirs) {
    const { errors, tested } = checkFormat(fid, haveBuild, KaitaiStream, dumpDir);
    totalTested += tested;
    if (errors.length) {
      failed++;
      console.log(`FAIL ${fid}`);
      for (const err of errors) console.log(`     ${err}`);
    } else {
      console.log(`ok   ${fid}` + (tested ? ` (${tested} samples)` : ""));
    }
  }

  console.log(`\n${dirs.length} formats, ${totalTested} samples tested, ${failed} failed`);
  return failed ? 1 : 0;
}

process.exitCode = main(process.argv.slice(2));
