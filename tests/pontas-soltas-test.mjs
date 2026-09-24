import { mkdirSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { join, dirname } from "node:path";
import { tmpdir } from "node:os";

const ROOT = join(dirname(new URL(import.meta.url).pathname), "..");
const PLUGIN = join(ROOT, ".config/opencode/plugins/pontas-soltas.js");
const ROOT_TMP = join(tmpdir(), `agent-dotfiles-ps-${process.pid}-${Date.now()}`);
const PROJECT = join(ROOT_TMP, "project");
const STORAGE = join(ROOT_TMP, "storage");
process.env.PONTA_SOLTAS_DIR = STORAGE;
mkdirSync(join(PROJECT, ".git"), { recursive: true });
mkdirSync(STORAGE, { recursive: true });

let passed = 0;
let failed = 0;
const check = (name, condition, detail = "") => {
  if (condition) { passed++; console.log(`PASS ${name}`); }
  else { failed++; console.error(`FAIL ${name}${detail ? `: ${detail}` : ""}`); }
};

async function boot() {
  const mod = await import(`file://${PLUGIN}?t=${Date.now()}-${Math.random()}`);
  const hooks = {};
  let tool;
  await mod.default.setup({
    session: {
      hook: async (name, callback) => { hooks[name] = callback; },
      get: async ({ sessionID }) => ({ id: sessionID, location: { directory: PROJECT } }),
    },
    tool: { transform: async (callback) => callback({ add: (value) => { tool = value; } }) },
    event: { subscribe: async function* () {} },
  });
  return { hooks, tool };
}

try {
  const first = await boot();
  const sid = "ses_test_aaaaaaaaaaaaaaaaaaaaaaaa";
  const added = await first.tool.execute({ action: "add", text: "primeira" }, { sessionID: sid });
  const id = added.content.match(/ps_[a-f0-9]{32}/)?.[0];
  check("add returns canonical id", Boolean(id), added.content);
  await first.tool.execute({ action: "add", text: "segunda\u0001 invisível" }, { sessionID: sid });
  const listed = (await first.tool.execute({ action: "list" }, { sessionID: sid })).content;
  check("list uses real line breaks", listed.includes("primeira\n") && !listed.includes("primeira\\n"), JSON.stringify(listed));
  check("control chars are sanitized", !listed.includes("\u0001"), JSON.stringify(listed));

  const file = readFileSync(join(STORAGE, (await import("node:fs")).readdirSync(STORAGE).find((name) => name.endsWith(".jsonl"))), "utf8");
  writeFileSync(join(STORAGE, (await import("node:fs")).readdirSync(STORAGE).find((name) => name.endsWith(".jsonl"))), `${file}{not-json}\n`);
  const afterCorruption = (await first.tool.execute({ action: "list" }, { sessionID: sid })).content;
  check("storage errors are visible", afterCorruption.includes("ERRO storage") && afterCorruption.includes("JSON inválido"), afterCorruption);

  const system = [];
  await first.hooks.context({ sessionID: sid, system });
  check("context injects open items", system.some((part) => part.text.includes("primeira")));

  console.log(`\n${passed} pass, ${failed} fail`);
  process.exitCode = failed ? 1 : 0;
} catch (error) {
  console.error(error);
  process.exitCode = 1;
} finally {
  rmSync(ROOT_TMP, { recursive: true, force: true });
}
