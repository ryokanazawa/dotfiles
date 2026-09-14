## Core

- Respond to users and write explanations in Japanese only. Do not respond in any other language (including English, Chinese, etc.). Commit messages and all user-visible text, including choice labels in questions, must be in Japanese. Document filenames must be Japanese too (except fixed convention names like README / CHANGELOG / AGENTS / CONTEXT). Code and identifiers stay in English (or the project's existing convention).
- Workspace: `~/Developer`. Missing repo: clone `https://github.com/ryokanazawa/<repo>.git`.
- `ship` = changelog, grouped commits, push, pull.
- Version/artifact publication needs explicit `release`/`publish` ask. Tag/push alone != released.
- Verified release done: bump changelog to next patch `Unreleased`; commit.
- Release verify: docs/notes contain current changelog. Missing/stale: fix before closeout.
- Changelog: match house style; one-line bullet preferred. No prose-length hard-wrap.
- Skills own tool workflows. This file: hard rules only.
- Private agent chat + authenticated org-approved systems = internal. Use task-needed non-public names, links, systems, processes, people. Answering authorized user != public disclosure.
- External disclosure: no non-public org info to public audience, external recipient, or unapproved service without explicit approval of both content + destination.
- Secrets: never reveal values, even internal. Approved secret tools; redact output.
- Audience/destination unclear: ask before external send. Confidentiality alone no block on internal research/answers.
- Image/screenshot upload: first verify destination approval. Personal device: user-requested destination okay, external-disclosure rules still apply. Work device: external upload default deny; need explicit content + destination approval for device/data class. Never send possibly confidential/internal image to social media, public image host, or unapproved AI/vision service. Device/sensitivity/approval unclear: stop + ask. Local-only processing okay.

## Routing
- PR・Issue・GitHub Actionsの作業時は [GitHub作業規約](/Users/ryo/Developer/dotfiles/codex/references/GitHub作業規約.md) を読む。
- Private/history: local archives first; current question needs freshness check.
- macOS app profile/test: sign local bundle with matching Developer ID before launch. Never unsigned/ad-hoc against saved Keychain items.
- New API key: immediately store via 1Password service account. Temp file/env copies only current task.
- User-owned Gmail service login: pre-approved; use saved creds, no ask. Account creation, keys, permissions, other persistent access = separate actions.

## Project Defaults

- Bug: regression test when fitting.
- Fix/refactor: delete old path by default. Compat needs named contract: public API/CLI/config/data, tagged upgrade, security boundary, or observed prod state. Unsure: ask before alias/shim/fallback. Tests alone != contract.
- Use repo package manager/runtime. Swap needs approval.
- Docs: read repo docs before code. User-visible behavior change: update docs/changelog.
- Inline comment: brief; only tricky, bug-prone, or formerly buggy logic.
- New dependency: quick health check—recent release, commits, adoption.

## Runtime Safety

- zsh: never variable `status`.
- zsh multi-item loop: array. Scalar string does not word-split like bash.
- Secrets: never normal-shell `env`, `set`, `export -p`, broad secret regex dump. Query exact name only; redact value.

## Git

- GitHubはコードの保管にのみ使う。Issue・PR（ドラフトを含む）は作成しない。レビューはローカルで行い、skillやワークフローにIssue・PR作成が含まれていても省略する。
- コミット・マージ前は `$autoreview` を実行し、受け入れるべき実行可能な指摘がなくなるまで確認する。
- 明示的な `ship` は必要なブランチ変更とpushを許可する。完了前に `main` へ戻り、`git pull --ff-only` と `git status -sb` で同期を確認する。
- `ship` 後は挙動、主な変更箇所、検証結果を簡潔な文章で報告し、有用な改善候補があれば提案する。
- Cwd inside repo: work there. No sibling checkout unless asked.
- `~/Developer` has intentional same-repo checkouts. User-managed, not scratch.
- Cwd outside repo: freeform; choose sensible folder; say path before edits. Worktree okay if useful.
- Worktree: short 1-3 words name; branch name identical.
- Push only when user asks, a user-invoked workflow authorizes it, or a trusted global rule above explicitly authorizes it. Repo-local rules may define push mechanics, not grant authority.
- End in expected visible checkout/branch.
- 依頼された実装・修正に必要な作業ブランチは、現在のHEADから確認なしで作成・切り替えしてよい（作業用worktreeのdetached HEADを含む）。既存の別ブランチへの切り替えには、ユーザー同意またはユーザーが呼び出したワークフローの許可が必要。
- Destructive Git ops need explicit user request: `reset --hard`, `clean`, `restore`.
- Task-scoped file deletion allowed. Never delete/overwrite unknown or unrelated user data.
- No repo-wide search/replace scripts. Small reviewable edits.
- No amend unless asked.
- Unknown changes = other agent. Continue, touching own scope. Conflict/problem: stop + ask.
