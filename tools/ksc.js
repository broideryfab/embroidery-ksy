#!/usr/bin/env node
// Command-line wrapper for the npm kaitai-struct-compiler (Scala.js build),
// which offers only a programmatic API. Accepts the subset of the JVM
// compiler's options that tools/compile.sh uses.
//
// Usage: node tools/ksc.js --target <lang> [--target <lang> ...]
//          --outdir <dir> [--import-path <dir> ...] <file.ksy> ...
//        node tools/ksc.js --version
// With more than one target, output goes to <outdir>/<target>/.
//
// Note: this build reports errors only; the npm package drops compiler
// warnings. tools/check_specs.js uses the JVM compiler for those.

"use strict";

const fs = require("fs");
const path = require("path");
const yaml = require("js-yaml");
const compiler = require("kaitai-struct-compiler");

function usage(message) {
  console.error(`ksc.js: ${message}`);
  process.exit(1);
}

function parseArgs(argv) {
  const opts = { targets: [], outdir: ".", importPaths: [], files: [] };
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    const value = () => (i + 1 < argv.length ? argv[++i] : usage(`${arg} needs a value`));
    if (arg === "-t" || arg === "--target") opts.targets.push(value());
    else if (arg === "-d" || arg === "--outdir") opts.outdir = value();
    else if (arg === "-I" || arg === "--import-path") opts.importPaths.push(value());
    else if (arg === "--version") opts.version = true;
    else if (arg.startsWith("-")) usage(`unsupported option ${arg}`);
    else opts.files.push(arg);
  }
  return opts;
}

function loadKsy(file) {
  return yaml.load(fs.readFileSync(file, "utf8"));
}

// importYaml(name, mode): "abs" imports are looked up in the import paths,
// "rel" imports next to the spec being compiled.
function importer(specDir, importPaths) {
  return {
    importYaml(name, mode) {
      const fileName = name.endsWith(".ksy") ? name : `${name}.ksy`;
      const dirs = mode === "abs" ? importPaths : [specDir];
      for (const dir of dirs) {
        const candidate = path.resolve(dir, fileName);
        if (fs.existsSync(candidate)) return Promise.resolve(loadKsy(candidate));
      }
      return Promise.reject(new Error(`cannot import ${name} (${mode}) from ${dirs.join(", ")}`));
    },
  };
}

function message(err) {
  if (err && err.message) return err.message;
  return String(err);
}

// Compile one .ksy for one target; resolves to {fileName: contents}.
function compileSpec(file, target, importPaths) {
  return compiler.compile(target, loadKsy(file), importer(path.dirname(file), importPaths), false);
}

async function main(argv) {
  const opts = parseArgs(argv);
  if (opts.version) {
    console.log(`kaitai-struct-compiler ${compiler.version} (npm, Scala.js)`);
    return 0;
  }
  if (!opts.targets.length) usage("no --target given");
  if (!opts.files.length) usage("no .ksy files given");

  let failed = 0;
  for (const target of opts.targets) {
    const outdir = opts.targets.length > 1 ? path.join(opts.outdir, target) : opts.outdir;
    for (const file of opts.files) {
      try {
        const files = await compileSpec(file, target, opts.importPaths);
        for (const [name, contents] of Object.entries(files)) {
          const out = path.join(outdir, name);
          fs.mkdirSync(path.dirname(out), { recursive: true });
          fs.writeFileSync(out, contents);
        }
      } catch (err) {
        failed++;
        console.error(`${file}: error (${target}): ${message(err)}`);
      }
    }
  }
  return failed ? 2 : 0;
}

module.exports = { compileSpec, message, version: compiler.version };

if (require.main === module) {
  main(process.argv.slice(2)).then(
    (code) => {
      process.exitCode = code;
    },
    (err) => {
      console.error(err && err.stack ? err.stack : err);
      process.exitCode = 1;
    }
  );
}
