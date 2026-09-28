#!/usr/bin/env node
// Pontua um handoff consolidado contra a verdade do fixture (seção-aware).
// Uso: node check.mjs <consolidado.md>
import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) { console.error("uso: node check.mjs <consolidado.md>"); process.exit(2); }
const text = readFileSync(file, "utf8");
const lines = text.split(/\r?\n/);

// Classifica uma linha-cabeçalho (heading ou "Label:") como open/done/obsolete.
function kindOf(line) {
  const s = line.replace(/^[#*\s>]+/, "").replace(/^[0-9]+[.)]\s*/, "").toLowerCase();
  if (/^(pend|abert|open|todo|pr[óo]xim)/.test(s)) return "open";
  if (/^(itens\s+conclu|conclu|fei|done|complet|resolvid)/.test(s)) return "done";
  if (/^(obsolet|legad|dispens)/.test(s)) return "obsolete";
  return null;
}

const sections = [];
let cur = null;
for (const line of lines) {
  const k = kindOf(line);
  if (k) cur = k;
  sections.push(cur);
}

const ids = ["P1", "P2", "P3", "P4", "P5", "Q1", "Q2", "Q3"];
const kinds = Object.fromEntries(ids.map((id) => [id, new Set()]));
// Conta só o PRIMEIRO id de cada linha (a entrada primária); ids citados na
// prosa do mesmo item não contam como status daquele item.
lines.forEach((line, i) => {
  if (!sections[i]) return;
  const m = line.match(/\b(P[1-9]|Q[1-9])\b/);
  if (m) kinds[m[1]].add(sections[i]);
});

const open = (id) => kinds[id].has("open");
const present = (id) => kinds[id].size > 0;
const naoAberto = (id) => present(id) && !open(id);

const criteria = [
  ["P2 aberto",         open("P2")],
  ["Q2 aberto",         open("Q2")],
  ["doc P4/Q3 aberto",  open("P4") || open("Q3")],
  ["P1 nao-aberto",     naoAberto("P1")],
  ["P5 nao-aberto",     naoAberto("P5")],
  ["Q1 nao-aberto",     naoAberto("Q1")],
  ["P3 nao-aberto",     naoAberto("P3")],
  ["correlacao srclib", /srclib/i.test(text)],
  ["duplicata P4/Q3",   (present("P4") || present("Q3")) && /duplicat|mesma|id[eê]ntic|merge/i.test(text)],
  ["provenance",        /ses_(aaa1|aaa2|bbb1|bbb2)/.test(text)],
];

let ok = 0;
for (const [name, pass] of criteria) {
  console.log(`${pass ? "PASS" : "FAIL"} ${name}`);
  if (pass) ok++;
}
console.log(`\nscore ${ok}/${criteria.length}`);
process.exit(ok === criteria.length ? 0 : 1);
