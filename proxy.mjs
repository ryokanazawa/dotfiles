/**
 * agent-proxy — see what Claude Code actually sends the model.
 *
 * A zero-dependency logging proxy for Claude Code. It sits between the CLI and
 * the Anthropic API, forwards every request untouched (auth header and all),
 * streams the response straight back so the CLI is unaffected, and for each
 * request writes a readable Markdown document — led by a ranked table of what
 * is eating your context.
 *
 * Run:   node proxy.mjs
 * Point Claude Code at it:
 *   ANTHROPIC_BASE_URL=http://localhost:8787 claude
 *
 * Zero runtime dependencies — Node built-ins only. Requires Node 18+.
 *
 * Deep modules (testable without I/O):
 *   proxy/audit.mjs   — rank tools / context weight
 *   proxy/decode.mjs  — SSE → markdown + input tokens
 *   proxy/render.mjs  — full Markdown document
 */

import http from "node:http";
import https from "node:https";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { auditRequest, printAudit } from "./proxy/audit.mjs";
import { decodeResponse } from "./proxy/decode.mjs";
import { renderMarkdown } from "./proxy/render.mjs";

const PORT = Number(process.env.PORT ?? 8787);
const UPSTREAM = "api.anthropic.com";

const HERE = path.dirname(fileURLToPath(import.meta.url));
const LOG_DIR = path.join(HERE, "logs");

/** count_tokens calls send content but get back only a number, never a reply.
 * A single turn fires many as housekeeping — pure noise here, so skip them. */
const isTokenCount = (reqPath) => reqPath.includes("count_tokens");

/** Strip hop-by-hop and encoding headers so the captured response is readable,
 * recompute content-length, and pass auth through untouched so the real request
 * still authenticates. */
function forwardHeaders(headers, body) {
  const out = { ...headers };
  delete out["host"];
  delete out["connection"];
  delete out["accept-encoding"]; // force identity so we can read the stream
  delete out["transfer-encoding"];
  delete out["content-length"];
  if (body.length > 0) out["content-length"] = String(body.length);
  return out;
}

function baseName() {
  const stamp = new Date().toISOString().replace(/:/g, "-").replace(".", "-").replace("Z", "");
  return `${stamp}_anthropic`;
}

function handle(req, res) {
  const reqPath = req.url ?? "/";
  const chunks = [];
  req.on("data", (c) => chunks.push(c));
  req.on("end", () => {
    const body = Buffer.concat(chunks);
    const timestamp = new Date().toISOString();
    const base = baseName();

    const upstream = https.request(
      { hostname: UPSTREAM, port: 443, path: reqPath, method: req.method, headers: forwardHeaders(req.headers, body) },
      (up) => {
        res.writeHead(up.statusCode ?? 502, up.headers);
        const respChunks = [];
        up.on("data", (c) => { respChunks.push(c); res.write(c); });
        up.on("end", () => {
          res.end();
          if (isTokenCount(reqPath)) return;
          try {
            const reqJson = JSON.parse(body.toString("utf8"));
            const { markdown, inputTokens } = decodeResponse(Buffer.concat(respChunks).toString("utf8"));
            const audit = auditRequest(reqJson, inputTokens);
            fs.mkdirSync(LOG_DIR, { recursive: true });
            fs.writeFileSync(path.join(LOG_DIR, `${base}.request.txt`), body.toString("utf8"));
            fs.writeFileSync(path.join(LOG_DIR, `${base}.md`), renderMarkdown({ reqJson, timestamp, method: req.method ?? "POST", path: reqPath, statusCode: up.statusCode ?? 0, headers: req.headers }, audit, markdown));
            printAudit(audit, base);
          } catch (err) {
            console.error(`[agent-proxy] could not render (non-JSON body?): ${err.message}`);
          }
        });
      }
    );
    upstream.on("error", (err) => {
      console.error(`[agent-proxy] upstream error: ${err.message}`);
      if (!res.headersSent) res.writeHead(502, { "content-type": "application/json" });
      res.end(JSON.stringify({ error: `agent-proxy upstream error: ${err.message}` }));
    });
    if (body.length > 0) upstream.write(body);
    upstream.end();
  });
}

http.createServer(handle).listen(PORT, () => {
  console.log(`[agent-proxy] listening on http://localhost:${PORT}`);
  console.log(`[agent-proxy] point Claude Code at it:  ANTHROPIC_BASE_URL=http://localhost:${PORT} claude`);
});
