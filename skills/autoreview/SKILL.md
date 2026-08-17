---
name: autoreview
description: Review changes before commit, push, PR updates, or merges from a perspective separate from the implementer's, then verify findings, fix in-scope issues, test, and re-review until no findings remain. Use when the user asks for autoreview, an automatic review, a pre-commit review, a second pair of eyes, verification by another agent or model, or completion confirmation of non-trivial code changes.
---

# Automated code review

Use as the quality gate just before closing out a change. Do not depend on any specific agent product, model, or CLI. When available, delegate the review alone to an independent subagent; when not, the caller runs the same procedure with a fresh review perspective.

Review results are advice, not to be applied mechanically. Verify every finding against the actual code and adjacent paths, and fix only problems within the original request's scope.

## Respect execution authority

Invoking autoreview by itself grants no permission to modify files. If the user asked only for a review, diagnosis, or explanation, report the verified findings and finish without editing files (including formatting), committing, pushing, updating PRs, or merging.

Only when the original request already authorizes changes — implementation, fixes, commits, etc. — fix findings within that same request scope and re-review. Even then, perform operations from commit onward only when the original request or a separate explicit workflow authorizes them.

## 1. Fix the target and scope

Before starting the review, record:

- The intent: the original request, issue, or spec
- The target branch and comparison base
- The expected user-facing behavior
- The ownership boundaries of the change
- Changed files and changed line count excluding tests
- A starting-point fingerprint taken from `HEAD` and the target diff contents
- Verifications already performed

Determine the target with the following priority:

1. If the user specified paths, commits, a scope, a branch, a PR, or a work objective, target only the changes belonging to that request.
2. Otherwise, target only the staged, unstaged, untracked, and committed changes that the caller created or modified during this session. Do not include changes from other sessions or other work merely because they exist in the working tree.
3. If the user asked to check commits missed in past sessions or uncommitted changes, add only explicitly named files/commits, or changes confirmed via history and diffs to belong to the same work. If they cannot be distinguished, confirm the target.
4. If this session's changes are already committed, target that commit or series of commits. Do not automatically target an entire branch that was not explicitly named.

If the comparison base cannot be inferred, or the target diff is empty, stop and explain the reason rather than pretending the review was done. Do not fetch, push, or change branches just for the review.

Immediately before judging completion, re-check `HEAD`, the target files, and staged, unstaged, and untracked state. If the target scope's contents changed since the start or since the last fix, discard the stale review results and re-review the latest diff. Always exclude unrelated changes from other work, and report the excluded paths.

First read the repository's `AGENTS.md`, `CLAUDE.md`, `CONTRIBUTING.md`, design documents, testing policy, and original spec. If changes are authorized and a formatter moves line positions, run it before the review. If read-only, only check whether formatting diffs exist.

Changes limited to internal prose or `SKILL.md` may be covered by direct diff inspection and available lightweight validation. Do not treat configuration, scripts, runnable examples, generated artifacts, or user-facing documentation as lightweight.

## 2. Run the review

Choose the available method in this order:

1. If an independent subagent can be launched, use exactly one. An independent context with the same model is sufficient; a different model is not required.
2. If no subagent is available, the caller re-reads the diff from the top and reviews without justifying the implementation-time decisions.

When using an independent reviewer, pass the target, intent, comparison base, expected behavior, ownership boundaries, changed files, verification results, and previously rejected findings with reasons. Have it report only concrete problems introduced by this diff, each with severity, location, impact, evidence, and a minimal fix. Instruct the reviewer to stay read-only: no edits, commits, pushes, or launching other reviewers.

Before passing anything to an independent reviewer, check the target paths and contents for secrets, credentials, personal data, and private information. Never transmit secret or credential values, and never include them in output. Pass personal data or private information only to an approved private reviewer, limited to what the task requires. If the destination or disclosure scope is unknown, or the external service is not approved, do not pass anything until the content and destination are approved.

When reviewing untrusted PRs, forks, or dependency code, pass sanitized input containing only the necessary instructions, diff, and related code, inside an isolated environment with no access to the original repository, ignored files, credentials, a shell, or unnecessary network. If isolation cannot be guaranteed, do not use an independent subagent; the caller reviews the target diff directly.

Use a specific model or engine designation only when the user specified it. If it is unavailable, do not silently switch to another model; report whether it is a transient failure retryable with the same model, or an unsupported case requiring the user's judgment.

In the review, read the entire diff and related code, checking for:

- Mismatches with the spec, wrong assumptions, boundary values
- Regressions of existing behavior, failure paths, state transitions
- Concurrency, retries, persistence, compatibility breakage
- Concrete, exploitable security issues or removal of safeguards
- Contract violations with dependency APIs, types, configuration, data formats
- Test gaps that would miss real regressions
- Unnecessary complication, duplication, wrong ownership boundaries

Do not flag stylistic preferences, unfounded future concerns, pre-existing issues not introduced by the change, overly hypothetical inputs, or broad rewrites. Verify findings that depend on external behavior against official documentation, types, or the dependency's code.

## 3. Verify and classify findings

For each finding, read not just the line in question but its callers, callees, types, tests, and failure paths. Run a minimal reproduction or a focused test if needed. Then classify:

- **In-scope blocker**: introduced by this diff, fixable within the same ownership boundary without changing the request's contract.
- **Rejected**: misreading, pre-existing issue, unrealistic condition, invariant already upheld, or the fix would be more complicated.
- **Follow-up**: real, but belongs to adjacent-area improvements, generalization, or broader hardening.
- **Stop and confirm**: requires changing public APIs, configuration, data formats, migrations, another ownership boundary, release procedures, or product decisions.

Record rejection reasons concisely. Add a short code comment only when future readers need to know the invariant or ownership decision.

If the same bug shape appears multiple times within this change's scope, check the sibling sites and fix them all at once. Do not explore beyond the change scope to fix things.

## 4. Fix, verify, re-review

If read-only, report the verified findings and end the procedure.

If changes are authorized, fix in-scope blockers with minimal changes and re-run the relevant tests and static checks. After changing code, re-review the entire updated diff with the same target criteria. Pass previously rejected findings with their reasons to the reviewer, and have it re-raise them only with new evidence.

Repeat until one of the following:

- There are no actionable findings left to accept.
- An out-of-scope design decision is needed.
- Two rounds of review-driven fixes have not converged.

If two rounds do not converge, reclassify all remaining items. Proceed to one more round only if every remaining item is in scope and the fixes are narrow. Otherwise, do not widen the change; report the minimal safe completion scope and the follow-ups.

Stop if fixes would exceed roughly double the original file count or non-test changed line count, or grow into architecture changes, protocol changes, migrations, or release procedure changes. Exceptions are limited to ongoing data loss, crashes, inability to install/update, release blockers, and concrete security exposure.

For work involving release, beta, stable, hotfix, signing, notarize, or publish, fix only release blockers. Make non-blocking findings follow-ups for `main`; do not turn release work into a refactoring venue.

## 5. Report completion

Summarize concisely:

- Review target and comparison base
- Review method; note if no independent subagent was used
- Tests, static checks, and reproduction steps performed
- Accepted findings and fixes; rejected findings and reasons
- That the final review had no actionable findings, or the remaining items and the reason for stopping

Mark clean only if the target fingerprint still matches after the final review and no actionable findings remain. Once clean, do not run additional reviews or second opinions merely to polish wording. autoreview itself does not commit, push, update PRs, or merge.
