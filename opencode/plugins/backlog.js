// backlog — injeta o backlog aberto do usuário no contexto, todo turno (garantido).
//
// Fonte: ~/.config/opencode/pendentes.md (seção `## Abertas`).
// Por quê: o usuário gera muitas ideias; a memória do contexto perde (compactação/KV).
// Injeção forte = hook `context` -> event.system.push (roda a cada request do loop).
// Escopo: isto é SISTEMA. A skill `retrospectiva` NÃO lê este arquivo (escopo dela é a sessão).
//
// Verificação: `opencode plugin list` deve listar `backlog local`.
import { readFileSync, statSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";

const FILE = join(homedir(), ".config", "opencode", "pendentes.md");
const MAX_ITEMS = 8;
const MAX_CHARS = 160;

let cache = { mtime: 0, items: [] };

function parseOpenItems(raw) {
  const chunks = raw.split(/^##\s+/m);
  const sec = chunks.find((c) => /^Abertas\b/.test(c));
  if (!sec) return [];
  return sec
    .split("\n")
    .map((l) => l.trim())
    .filter((l) => /^-\s*\[ \]/.test(l))
    .map((l) => l.replace(/^-\s*\[ \]\s*/, ""));
}

function openItems() {
  try {
    const mtime = statSync(FILE).mtimeMs;
    if (mtime !== cache.mtime) cache = { mtime, items: parseOpenItems(readFileSync(FILE, "utf8")) };
    return cache.items;
  } catch {
    return [];
  }
}

export default {
  id: "backlog",
  async setup(ctx) {
    await ctx.session.hook("context", (event) => {
      if (!Array.isArray(event?.system)) return;
      const items = openItems();
      if (items.length === 0) return;
      const shown = items
        .slice(0, MAX_ITEMS)
        .map((i) => "- " + (i.length > MAX_CHARS ? i.slice(0, MAX_CHARS) + "…" : i));
      const extra =
        items.length > MAX_ITEMS ? `\n(+${items.length - MAX_ITEMS} outras em ~/.config/opencode/pendentes.md)` : "";
      event.system.push({
        type: "text",
        text: `<!-- backlog --> Backlog aberto (${items.length}) — o usuário não pode perder isto:\n${shown.join("\n")}${extra}`,
      });
    });
  },
};
