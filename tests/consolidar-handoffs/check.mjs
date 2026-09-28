#!/usr/bin/env node
// Pontua um handoff consolidado contra a verdade do fixture.
// Uso: node check.mjs <consolidado.md>
import { readFileSync } from "node:fs";

const file = process.argv[2];
if (!file) { console.error("uso: node check.mjs <consolidado.md>"); process.exit(2); }
const t = readFileSync(file, "utf8");

const perto = (id, re) => new RegExp(`${id}\\b[^\\n]{0,80}${re}`, "i").test(t);
const criteria = [
  ["P2 aberto",         perto("P2", "(aberto|pendente)")],
  ["Q2 aberto",         perto("Q2", "(aberto|pendente)")],
  ["P1 feito",          perto("P1", "(conclu|feito|resolv|done)")],
  ["P5 feito",          perto("P5", "(conclu|feito|resolv|done)")],
  ["Q1 feito",          perto("Q1", "(conclu|feito|resolv|done)")],
  ["P3 nao-aberto",     /P3\b/.test(t) && !perto("P3", "(aberto|pendente)")],
  ["correlacao srclib", /srclib/i.test(t)],
  ["duplicata P4/Q3",   /(P4|Q3)/.test(t) && /duplicat|mesma|id[eê]ntic|merge/i.test(t)],
  ["provenance",        /ses_(aaa1|aaa2|bbb1|bbb2)/.test(t)],
];

let ok = 0;
for (const [name, pass] of criteria) {
  console.log(`${pass ? "PASS" : "FAIL"} ${name}`);
  if (pass) ok++;
}
console.log(`\nscore ${ok}/${criteria.length}`);
process.exit(ok === criteria.length ? 0 : 1);
