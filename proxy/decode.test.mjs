import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { decodeResponse } from "./decode.mjs";

describe("decodeResponse", () => {
  it("reassembles text blocks and sums input tokens including cache", () => {
    const raw = [
      `data: ${JSON.stringify({ type: "message_start", message: { usage: { input_tokens: 10, cache_read_input_tokens: 5 } } })}`,
      `data: ${JSON.stringify({ type: "content_block_start", index: 0, content_block: { type: "text" } })}`,
      `data: ${JSON.stringify({ type: "content_block_delta", index: 0, delta: { text: "Hello" } })}`,
      `data: ${JSON.stringify({ type: "content_block_delta", index: 0, delta: { text: " world" } })}`,
      `data: ${JSON.stringify({ type: "message_delta", delta: { stop_reason: "end_turn" }, usage: { output_tokens: 3, cache_creation_input_tokens: 2 } })}`,
      "data: [DONE]",
    ].join("\n");

    const { markdown, inputTokens } = decodeResponse(raw);
    assert.equal(inputTokens, 17);
    assert.match(markdown, /stop reason.*end_turn/);
    assert.match(markdown, /<assistant-text>[\s\S]*Hello world[\s\S]*<\/assistant-text>/);
  });

  it("falls back to fenced raw when no events parse", () => {
    const { markdown, inputTokens } = decodeResponse("not sse");
    assert.equal(inputTokens, null);
    assert.match(markdown, /```\nnot sse\n```/);
  });
});
