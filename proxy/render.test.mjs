import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { auditRequest } from "./audit.mjs";
import { renderMarkdown } from "./render.mjs";

describe("renderMarkdown", () => {
  it("redacts auth headers and includes messages", () => {
    const reqJson = {
      model: "claude-test",
      system: "be brief",
      messages: [{ role: "user", content: "hi" }],
      tools: [{ name: "peek", description: "look", input_schema: { type: "object" } }],
    };
    const audit = auditRequest(reqJson, 9);
    const md = renderMarkdown(
      {
        reqJson,
        timestamp: "2026-01-01T00:00:00.000Z",
        method: "POST",
        path: "/v1/messages",
        statusCode: 200,
        headers: { authorization: "secret", "content-type": "application/json" },
      },
      audit,
      "<assistant-text>\nok\n</assistant-text>"
    );

    assert.match(md, /authorization: \[REDACTED\]/);
    assert.doesNotMatch(md, /secret/);
    assert.match(md, /be brief/);
    assert.match(md, /### peek/);
    assert.match(md, /role="user"/);
    assert.match(md, /<response>[\s\S]*ok/);
  });
});
