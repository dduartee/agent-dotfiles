#!/usr/bin/env node
// Pontua um handoff consolidado contra a verdade do fixture (seção-aware).
// Uso: node check.mjs <consolidado.md>
import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) { console.error("uso: node check.mjs <consolidado.md>"); process.exit(2); }
const text = readFileSync(file, "utf8");
const lines = text.split(/\r?\n/);

// Classifica um rótulo de seção (heading ou "Label:"). done/obsolete ANTES de open.
function kindOf(line) {
  const s = line.replace(/^[#*\s>]+/, "").replace(/^[0-9]+[.)]\s*/, "").toLowerCase();
  if (/verifica|assumir|antes de/.test(s)) return null;
  if (/(conclu|fei|done|complet|resolvid|hist[óo]rico)/.test(s)) return "done";
  if (/(obsolet|legad|dispens|n[ãa]o\s+[ée]\s+mais)/.test(s)) return "obsolete";
  if (/^(pend|abert|open|todo|pr[óo]xim)/.test(s)) return "open";
  return null;
}

const idsOn = (l) => [...l.matchAll(/\b(P[1-9]|Q[1-9])\b/g)].map((m) => m[1]);

const isItemLine = (line) => /^\s*([-*+]|\d+[.)])\s/.test(line);
function labelKind(line) {
  if (isItemLine(line)) return null; // linha de item nunca é rótulo de seção
  const isHeading = /^#{1,6}\s+\S/.test(line);
  const isLabelish = isHeading || /^[^\s:][^:]{0,40}:/.test(line.trimStart());
  return isLabelish ? kindOf(line) : null;
}

// section por linha + flag "linha é rótulo" (compacto conta todos os ids).
const state = [];
let cur = null;
for (const line of lines) {
  const k = labelKind(line);
  const isHeading = /^#{1,6}\s+\S/.test(line);
  let label = false;
  if (k !== null) { cur = k; label = true; }
  else if (isHeading) { cur = null; } // heading não-status quebra a seção anterior
  state.push({ section: cur, label });
}

const ids = ["P1", "P2", "P3", "P4", "P5", "Q1", "Q2", "Q3"];
const kinds = Object.fromEntries(ids.map((id) => [id, new Set()]));
let openDupLines = 0;
lines.forEach((line, i) => {
  const { section, label } = state[i];
  if (!section) return;
  const all = idsOn(line);
  const use = label ? all : all.slice(0, 1); // em item comum, só o id primário
  for (const id of use) kinds[id].add(section);
  if (section === "open" && all.some((id) => id === "P4" || id === "Q3")) openDupLines++;
});

const open = (id) => kinds[id].has("open");
const present = (id) => kinds[id].size > 0;
const naoAberto = (id) => present(id) && !open(id);

const cluster = ["P2", "Q1", "P5"];
const correlOk = lines.some(
  (l) => /srclib/i.test(l) && idsOn(l).filter((x) => cluster.includes(x)).length >= 2,
);

const criteria = [
  ["P2 aberto",            open("P2")],
  ["Q2 aberto",            open("Q2")],
  ["doc P4/Q3 aberto",     open("P4") || open("Q3")],
  ["P1 nao-aberto",        naoAberto("P1")],
  ["P5 nao-aberto",        naoAberto("P5")],
  ["Q1 nao-aberto",        naoAberto("Q1")],
  ["P3 nao-aberto",        naoAberto("P3")],
  ["correlacao srclib",    correlOk],
  ["duplicata declarada",  (present("P4") || present("Q3")) && /duplicat|mesma|id[eê]ntic|merge/i.test(text)],
  ["duplicata nao-repetida", openDupLines === 1],
  ["provenance",           /ses_(aaa1|aaa2|bbb1|bbb2)/.test(text)],
];

let ok = 0;
for (const [name, pass] of criteria) {
  console.log(`${pass ? "PASS" : "FAIL"} ${name}`);
  if (pass) ok++;
}
console.log(`\nscore ${ok}/${criteria.length}`);
process.exit(ok === criteria.length ? 0 : 1);
