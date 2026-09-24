// sessao-atual — injeta o session id da sessão no contexto, todo turno (garantido).
//
// Motivo: com 2+ sessões ativas no mesmo diretório (ex.: outro agente rodando em
// paralelo), não dá para adivinhar o id — a skill `retrospectiva` precisa dele
// explícito. O hook `context` recebe `event.sessionID` a cada request do loop e é
// o ponto de injeção mais forte da API v2 (docs: opencode.ai/v2/docs/build/plugins).
//
// Verificação: `opencode plugin list` deve listar `sessao-atual local`.
export default {
  id: "sessao-atual",
  async setup(ctx) {
    await ctx.session.hook("context", (event) => {
      const sid = event?.sessionID;
      if (!sid || !Array.isArray(event.system)) return;
      event.system.push({
        type: "text",
        text:
          `<!-- sessao-atual --> OpenCode session id DESTA sessão: ${sid}. ` +
          `Use ESTE id ao rodar scripts da skill retrospectiva (ex.: \`sessao.sh ${sid}\`); ` +
          `não adivinhe nem use o auto-resolve quando houver 2+ sessões no mesmo diretório.`,
      });
    });
  },
};
