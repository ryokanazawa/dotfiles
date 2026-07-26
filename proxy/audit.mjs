/** Rough token estimate for display. Real input tokens come from the response
 * usage; this is only for ranking the request before the reply arrives. */
export const estTokens = (bytes) => Math.round(bytes / 4);

/** Measure every removable region of the request and rank the tools by size.
 * This is the whole point of the proxy — the numbers you cut against. */
export function auditRequest(reqJson, realInputTokens) {
  const tools = Array.isArray(reqJson?.tools) ? reqJson.tools : [];
  const toolRows = tools
    .map((t) => {
      const bytes = Buffer.byteLength(JSON.stringify(t));
      return { name: t?.name ?? "(unnamed)", bytes, tokens: estTokens(bytes) };
    })
    .sort((a, b) => b.bytes - a.bytes);

  const toolsBytes = toolRows.reduce((n, r) => n + r.bytes, 0);
  const systemBytes = reqJson?.system ? Buffer.byteLength(JSON.stringify(reqJson.system)) : 0;
  const totalBytes = Buffer.byteLength(JSON.stringify(reqJson ?? {}));

  return {
    toolRows,
    toolCount: toolRows.length,
    toolsBytes,
    systemBytes,
    totalBytes,
    realInputTokens,
  };
}

/** The ranked table, as Markdown. The hero of the whole document. */
export function renderAudit(audit) {
  const pct = (bytes) => (audit.totalBytes ? ((bytes / audit.totalBytes) * 100).toFixed(1) : "0.0");
  const rows = audit.toolRows
    .map((r) => `| ${r.name} | ${r.bytes.toLocaleString()} | ~${r.tokens.toLocaleString()} | ${pct(r.bytes)}% |`)
    .join("\n");

  return [
    "<audit>",
    "",
    audit.realInputTokens != null
      ? `**${audit.realInputTokens.toLocaleString()} input tokens** billed for this request (from the response usage).`
      : "",
    "",
    `- **tools**: ${audit.toolCount} definitions, ${audit.toolsBytes.toLocaleString()} bytes (~${estTokens(audit.toolsBytes).toLocaleString()} tokens)`,
    `- **system prompt**: ${audit.systemBytes.toLocaleString()} bytes (~${estTokens(audit.systemBytes).toLocaleString()} tokens)`,
    `- **total request**: ${audit.totalBytes.toLocaleString()} bytes`,
    "",
    "**Tools, ranked by size — this is your cut list:**",
    "",
    "| tool | bytes | ~tokens | % of request |",
    "| --- | --: | --: | --: |",
    rows,
    "",
    "</audit>",
  ].join("\n");
}

/** The same ranking, compact, for the terminal — so you see the bloat live. */
export function printAudit(audit, base, log = console.log) {
  const top = audit.toolRows.slice(0, 12);
  const w = Math.max(4, ...top.map((r) => r.name.length));
  log(`\n[agent-proxy] ${audit.toolCount} tools · ${audit.toolsBytes.toLocaleString()} tool bytes` +
    (audit.realInputTokens != null ? ` · ${audit.realInputTokens.toLocaleString()} real input tokens` : ""));
  for (const r of top) {
    log(`  ${r.name.padEnd(w)}  ${String(r.bytes).padStart(7)} B  ~${r.tokens} tok`);
  }
  if (audit.toolRows.length > top.length) log(`  … ${audit.toolRows.length - top.length} more`);
  log(`  logs/${base}.md\n`);
}
