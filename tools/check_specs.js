#!/usr/bin/env node
// Compile every spec and fail on any compiler error or warning.
//
// This is the only tool that uses the JVM kaitai-struct-compiler: the npm
// build (tools/ksc.js) drops warnings and has no --ksc-json-output.
// Everything else (compile.sh, tests, releases) uses the npm compiler.
//
// Runs the JVM compiler once over all specs with --ksc-json-output and reads
// its report. In that mode ksc exits 0 even when a spec has errors, and it
// never fails on warnings, so the report is the only reliable signal.
// Generated code goes to a temporary directory and is discarded.
//
// Usage: node tools/check_specs.js [target ...]
//        (default: python javascript java go — the release targets)
// Env:   KSC — JVM compiler command (default: kaitai-struct-compiler), at
//        the version in tools/KSC_VERSION

"use strict";

const { spawnSync } = require("child_process");
const fs = require("fs");
const os = require("os");
const path = require("path");

const ROOT = path.resolve(__dirname, "..");
const FORMATS = path.join(ROOT, "formats");
const DEFAULT_TARGETS = ["python", "javascript", "java", "go"];

// Yield [severity, where, problem] for every error and warning in node.
function* problems(node, where) {
  if (Array.isArray(node)) {
    for (let i = 0; i < node.length; i++) yield* problems(node[i], where.concat(String(i)));
  } else if (node !== null && typeof node === "object") {
    for (const [key, value] of Object.entries(node)) {
      if ((key === "errors" || key === "warnings") && Array.isArray(value)) {
        for (const problem of value) yield [key.slice(0, -1), where, problem];
      } else {
        yield* problems(value, where.concat(key));
      }
    }
  }
}

function describe([severity, where, problem]) {
  if (problem === null || typeof problem !== "object") {
    return `${severity}: ${problem}`;
  }
  const pos = ["line", "col"]
    .filter((k) => problem[k] !== undefined && problem[k] !== null)
    .map((k) => problem[k])
    .join(":");
  let loc = problem.file || "";
  if (pos) loc += `:${pos}`;
  if (Array.isArray(problem.path) && problem.path.length) loc += " /" + problem.path.join("/");
  const context = where.length ? ` [${where.join("/")}]` : "";
  const message = problem.message !== undefined ? problem.message : JSON.stringify(problem);
  return `${loc}: ${severity}: ${message}${context}`;
}

function main(argv) {
  const targets = argv.length ? argv : DEFAULT_TARGETS;
  const ksc = process.env.KSC || "kaitai-struct-compiler";
  // formats/_common/ holds shared types; they are compiled via imports.
  const specs = fs
    .readdirSync(FORMATS, { withFileTypes: true })
    .filter((d) => d.isDirectory() && /^[a-z]/.test(d.name))
    .flatMap((d) =>
      fs
        .readdirSync(path.join(FORMATS, d.name))
        .filter((f) => f.endsWith(".ksy"))
        .map((f) => `formats/${d.name}/${f}`)
    )
    .sort();

  const outdir = fs.mkdtempSync(path.join(os.tmpdir(), "ksc-check-"));
  const args = ["--ksc-json-output", "--import-path", "formats", "--outdir", outdir];
  for (const target of targets) args.push("--target", target);
  const proc = spawnSync(ksc, args.concat(specs), {
    cwd: ROOT,
    encoding: "utf8",
    maxBuffer: 256 * 1024 * 1024,
  });
  fs.rmSync(outdir, { recursive: true, force: true });

  if (proc.error) {
    console.error(`cannot run ${ksc}: ${proc.error.message}`);
    return 1;
  }
  if (proc.status !== 0) {
    console.log(proc.stdout + proc.stderr);
    console.error(`${ksc} exited with status ${proc.status}`);
    return 1;
  }
  let report;
  try {
    report = JSON.parse(proc.stdout);
  } catch (err) {
    console.log(proc.stdout + proc.stderr);
    console.error(`${ksc} did not print a JSON report`);
    return 1;
  }

  let failed = 0;
  if (proc.stderr.trim()) {
    // ksc reports its own problems in the JSON; stderr is JVM noise.
    console.log(`note: compiler stderr:\n${proc.stderr.trimEnd()}\n`);
  }
  const entries = Object.keys(report).sort();
  if (entries.length !== specs.length) {
    failed++;
    console.log(`FAIL report has ${entries.length} entries for ${specs.length} specs`);
  }

  for (const spec of entries) {
    const found = [...problems(report[spec], [])].map(describe);
    if (found.length) {
      failed++;
      console.log(`FAIL ${spec}`);
      for (const line of found) console.log(`     ${line}`);
    } else {
      console.log(`ok   ${spec}`);
    }
  }

  console.log(`\n${specs.length} specs, targets: ${targets.join(" ")}, ${failed} failed`);
  return failed ? 1 : 0;
}

process.exitCode = main(process.argv.slice(2));
