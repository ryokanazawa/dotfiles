---
name: improve-codebase-architecture
description: Scan a codebase for deepening opportunities, present them as a visual HTML report, then grill through whichever one you pick.
disable-model-invocation: true
---

# Improve Codebase Architecture

Surface architectural friction and propose **deepening opportunities** — refactors that turn shallow modules into deep ones. The aim is testability and AI-navigability.

This command is _informed_ by the project's domain model and built on a shared design vocabulary:

- Run the `/codebase-design` skill for the architecture vocabulary (**module**, **interface**, **depth**, **seam**, **adapter**, **leverage**, **locality**) and its principles (the deletion test, "the interface is the test surface", "one adapter = hypothetical seam, two = real"). Use these terms exactly in every suggestion — don't drift into "component," "service," "API," or "boundary."
- The domain language in `CONTEXT.md` gives names to good seams. Existing architecture decisions are reference material only; this command must not create or update RFCs, ADRs, or other decision records.

## Outputs

Do NOT create GitHub issues, pull requests, or other external tracking artifacts. Allowed deliverables are only what **Process** below describes.

## Process

### 1. Explore

Read the project's domain glossary (`CONTEXT.md`) and any existing architecture decision records in the area you're touching first. Treat them as context only; do not create, update, or submit RFCs or ADRs.

Then use the Agent tool with `subagent_type=Explore` to walk the codebase. Don't follow rigid heuristics — explore organically and note where you experience friction:

- Where does understanding one concept require bouncing between many small modules?
- Where are modules **shallow** — interface nearly as complex as the implementation?
- Where have pure functions been extracted just for testability, but the real bugs hide in how they're called (no **locality**)?
- Where do tightly-coupled modules leak across their seams?
- Which parts of the codebase are untested, or hard to test through their current interface?

Apply the **deletion test** to anything you suspect is shallow: would deleting it concentrate complexity, or just move it? A "yes, concentrates" is the signal you want.

### 2. Present candidates as an HTML report

Write a self-contained HTML file to the OS temp directory so nothing lands in the repo. Resolve the temp dir from `$TMPDIR`, falling back to `/tmp` (or `%TEMP%` on Windows), and write to `<tmpdir>/architecture-review-<timestamp>.html`. Open it for the user — `xdg-open <path>` on Linux, `open <path>` on macOS, `start <path>` on Windows — and tell them the absolute path.

Follow [HTML-REPORT.md](HTML-REPORT.md) for scaffold, candidate cards, diagram patterns, and styling. Be visual — each candidate needs a before/after diagram.

End the report with a **Top recommendation** section: which candidate you'd tackle first and why.

**Decision-record conflicts**: if a candidate contradicts an existing decision record, only surface it when the friction is real enough to warrant discussing the conflict. Mark it clearly in the card (e.g. a warning callout: _"contradicts an existing decision — but worth discussing because…"_). Do not create or update an RFC/ADR, and don't list every theoretical refactor a decision record forbids.

Do NOT propose interfaces yet. After the file is written, ask the user: "Which of these would you like to explore?"

### 3. Grilling loop

Once the user picks a candidate, run the `/grilling` skill to walk the design tree with them — constraints, dependencies, the shape of the deepened module, what sits behind the seam, what tests survive.

As decisions crystallize, summarize them in the conversation or the report only. Do not update `CONTEXT.md`, create or update ADRs, or offer to record an RFC/ADR when the user rejects a candidate.

To explore alternative interfaces, run `/codebase-design` and use its design-it-twice parallel sub-agent pattern.
