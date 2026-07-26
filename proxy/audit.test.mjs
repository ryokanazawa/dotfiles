import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { auditRequest, estTokens, printAudit, renderAudit } from "./audit.mjs";

describe("auditRequest", () => {
  it("ranks tools by serialized size descending", () => {
    const audit = auditRequest({
      tools: [
        { name: "small", description: "x" },
        { name: "large", description: "x".repeat(200) },
      ],
      system: "hi",
    }, 1234);

    assert.equal(audit.toolCount, 2);
    assert.equal(audit.toolRows[0].name, "large");
    assert.equal(audit.toolRows[1].name, "small");
    assert.ok(audit.toolRows[0].bytes > audit.toolRows[1].bytes);
    assert.equal(audit.realInputTokens, 1234);
    assert.ok(audit.totalBytes > audit.toolsBytes);
    assert.ok(audit.systemBytes > 0);
  });

  it("tolerates missing tools and system", () => {
    const audit = auditRequest({}, null);
    assert.equal(audit.toolCount, 0);
    assert.equal(audit.toolsBytes, 0);
    assert.equal(audit.systemBytes, 0);
    assert.equal(audit.realInputTokens, null);
  });
});

describe("estTokens / renderAudit", () => {
  it("estimates tokens as bytes/4", () => {
    assert.equal(estTokens(400), 100);
  });

  it("includes billed tokens line when present", () => {
    const md = renderAudit(auditRequest({ tools: [{ name: "a" }] }, 42));
    assert.match(md, /42 input tokens/);
    assert.match(md, /\| a \|/);
  });

  it("prints the ranking through the injected logger", () => {
    const lines = [];
    const audit = auditRequest({ tools: [{ name: "peek", description: "look" }] }, 42);
    printAudit(audit, "sample", (line) => lines.push(line));

    assert.match(lines.join("\n"), /peek/);
    assert.match(lines.join("\n"), /42 real input tokens/);
    assert.match(lines.join("\n"), /logs\/sample\.md/);
  });
});
