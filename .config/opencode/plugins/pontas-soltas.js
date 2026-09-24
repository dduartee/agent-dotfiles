// pontas-soltas — o agente ARMAZENA pontas soltas e os hooks as reinjetam no
// contexto (garantido). ESCOPO = PROJETO (não sessão): sobrevivem ao fim da
// sessão e são compartilhadas por todas as sessões do mesmo projeto.
//
// - chave do projeto: raiz do git (sobe até achar .git); fora de repo = o dir
// - storage: ~/.config/opencode/pontas-soltas/<slug>-<hash8>.jsonl (append-only)
// - tool `pontas_soltas`: add | list | resolve | reopen | remove
// - hook `context`:    injeta as ABERTAS todo turno (sem dedupe)
// - hook `compaction`: reinjeta antes de compactar (o ponto onde elas somem)
// - GC: `done` com mais de 7 dias sai do replay; `open` nunca some
//
// Append-only → N sessões no mesmo projeto escrevem o MESMO arquivo sem lock e
// sem perder update (read-modify-write não existe). Leitura = replay das linhas.
//
// Verificação: `opencode plugin list` deve listar `pontas-soltas local`.
import { appendFileSync, existsSync, mkdirSync, readFileSync } from "node:fs";
import { createHash } from "node:crypto";
import { homedir } from "node:os";
import { basename, dirname, join } from "node:path";

const DIR = join(homedir(), ".config", "opencode", "pontas-soltas");
const MAX_INJECT = 20; // itens injetados por turno
const MAX_ITEM_CHARS = 200; // cap por item NA INJEÇÃO
const MAX_TEXT = 1000; // cap do texto aceito no `add`
const GC_DAYS = 7; // `done` mais velho que isto sai do replay

const cache = new Map(); // sessionID -> file (evita session.get a cada request)

const newId = () => "ps_" + Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
const clip = (s, n) => (s.length > n ? s.slice(0, n - 1).trimEnd() + "…" : s);

// Sobe até a raiz do repo; sem .git acima, devolve o próprio dir.
function gitRoot(dir) {
  let d = dir || "";
  for (let i = 0; i < 64 && d; i++) {
    if (existsSync(join(d, ".git"))) return d;
    const p = dirname(d);
    if (p === d) break;
    d = p;
  }
  return dir;
}

function projectKey(root) {
  const base =
    (basename(root) || "proj")
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, "-")
      .replace(/^-+|-+$/g, "")
      .slice(0, 40) || "proj";
  const h = createHash("sha1").update(String(root)).digest("hex").slice(0, 8);
  return base + "-" + h;
}

async function projectDirFor(ctx, sessionID) {
  try {
    if (ctx?.session?.get && sessionID) {
      const s = await ctx.session.get({ sessionID });
      const d = s?.location?.directory ?? s?.directory;
      if (typeof d === "string" && d) return d;
    }
  } catch {}
  const inst = ctx?.location?.directory;
  if (typeof inst === "string" && inst) return inst;
  return process.cwd();
}

async function fileForSession(ctx, sessionID) {
  if (!sessionID) return null;
  if (cache.has(sessionID)) return cache.get(sessionID);
  const root = gitRoot(await projectDirFor(ctx, sessionID));
  const file = join(DIR, projectKey(root) + ".jsonl");
  cache.set(sessionID, file);
  return file;
}

// Replay do log append-only. `done` > GC_DAYS sai; `open` fica sempre.
function readItems(file) {
  let raw = "";
  try {
    raw = readFileSync(file, "utf8");
  } catch {
    return [];
  }
  const cutoff = Date.now() - GC_DAYS * 86400000;
  const map = new Map();
  for (const line of raw.split("\n")) {
    if (!line) continue;
    let e;
    try {
      e = JSON.parse(line);
    } catch {
      continue;
    }
    if (e.op === "add") {
      map.set(e.id, { id: e.id, text: e.text, status: "open", created: e.ts, sessionID: e.sessionID });
      continue;
    }
    const it = map.get(e.id);
    if (!it) continue;
    if (e.op === "resolve") {
      it.status = "done";
      it.resolvedAt = e.ts;
    } else if (e.op === "reopen") {
      it.status = "open";
      delete it.resolvedAt;
    } else if (e.op === "remove") {
      map.delete(e.id);
    }
  }
  const out = [];
  for (const it of map.values()) {
    if (it.status === "done" && it.resolvedAt && Date.parse(it.resolvedAt) < cutoff) continue;
    out.push(it);
  }
  return out;
}

function append(file, entry) {
  mkdirSync(DIR, { recursive: true });
  appendFileSync(file, JSON.stringify(entry) + "\n"); // O_APPEND: sem read-modify-write
}

function fmt(items) {
  if (!items.length) return "Nenhuma ponta solta.";
  return items.map((i) => `${i.status === "open" ? "[ ]" : "[x]"} ${i.id} — ${i.text}`).join("\n");
}

const openLine = (i) => `- ${clip(i.text, MAX_ITEM_CHARS)}`;

// As pontas vivas da sessão — assinatura: (ctx, sessionID)
export const __internals = { gitRoot, projectKey, readItems };

export default {
  id: "pontas-soltas",
  async setup(ctx) {
    let lastSessionID = null;

    await ctx.session.hook("context", async (event) => {
      if (event?.sessionID) lastSessionID = event.sessionID;
      if (!Array.isArray(event?.system) || !event?.sessionID) return;
      const file = await fileForSession(ctx, event.sessionID);
      if (!file) return;
      const open = readItems(file).filter((i) => i.status === "open");
      if (!open.length) return;
      const shown = open.slice(0, MAX_INJECT).map(openLine);
      const extra = open.length > MAX_INJECT ? `\n(+${open.length - MAX_INJECT} em ${file})` : "";
      event.system.push({
        type: "text",
        text: `<!-- pontas-soltas --> Pontas soltas abertas do projeto (${open.length}) — feche ou marque antes de encerrar:\n${shown.join("\n")}${extra}`,
      });
    });

    await ctx.session.hook("compaction", async (event) => {
      if (event?.sessionID) lastSessionID = event.sessionID;
      if (!Array.isArray(event?.system) || !event?.sessionID) return;
      const file = await fileForSession(ctx, event.sessionID);
      if (!file) return;
      const open = readItems(file).filter((i) => i.status === "open");
      if (!open.length) return;
      event.system.push({
        type: "text",
        text: `<!-- pontas-soltas --> ANTES DA COMPACTAÇÃO — pontas soltas abertas do projeto (${open.length}):\n${open.map(openLine).join("\n")}`,
      });
    });

    await ctx.tool.transform((editor) => {
      editor.add({
        name: "pontas_soltas",
        description:
          "Gerência de pontas soltas do PROJETO (itens abertos compartilhados por todas as sessões do repo). No INSTANTE em que decidir adiar/recusar/deixar algo sem resolver (item 'fora de escopo', 'depois', 'por enquanto', warning vivo, erro que sobra, pergunta ou oferta sem resposta), registre com action=add ANTES de seguir — o registro é PARTE do ato de adiar; sem registro, não se adia. Ao encerrar a resposta, confira se sobrou algo não registrado e registre. Registrar ≠ mexer (item 'não mexa' entra igual). action=resolve ao fechar.",
        input: {
          type: "object",
          properties: {
            action: { type: "string", enum: ["add", "list", "resolve", "reopen", "remove"] },
            text: { type: "string", description: "Texto da ponta (add)." },
            id: { type: "string", description: "Id da ponta (resolve/reopen/remove)." },
          },
          required: ["action"],
          additionalProperties: false,
        },
        execute: async (input, context) => {
          const sid = (context && context.sessionID) || lastSessionID;
          if (!sid) return { content: "ERRO: sessionID desconhecido ainda. Tente de novo após 1 turno." };
          const file = await fileForSession(ctx, sid);
          if (!file) return { content: "ERRO: não consegui resolver o projeto desta sessão." };
          const items = readItems(file);
          const a = input.action;

          if (a === "add") {
            if (!input.text) return { content: "ERRO: 'text' obrigatório para add." };
            const id = newId();
            append(file, { op: "add", id, text: clip(String(input.text), MAX_TEXT), ts: new Date().toISOString(), sessionID: sid });
            return { content: `Ponta adicionada: ${id}\n${fmt(readItems(file))}` };
          }
          if (a === "list") return { content: fmt(items) };

          if (!items.some((i) => i.id === input.id)) return { content: `ERRO: id não encontrado: ${input.id}\n${fmt(items)}` };
          if (!["resolve", "reopen", "remove"].includes(a)) return { content: `ERRO: ação inválida: ${a}` };

          append(file, { op: a, id: input.id, ts: new Date().toISOString(), sessionID: sid });
          return { content: fmt(readItems(file)) };
        },
      });
    });
  },
};
