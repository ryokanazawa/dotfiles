---
name: commit
description: Default commit workflow: create a git commit with changelog when needed, immediately merge worktree commits into main, and push. Use when the user types /commit or asks to commit; run the full flow including push unless the user explicitly wants a local-only commit.
---

# /commit — autoreview, changelog, commit, merge into main, push

Commit only the changes from the current session. Before updating the changelog, use the `autoreview` skill to check the changes and fix them until clean. If the changes are user-facing, update `CHANGELOG.md` (or the repository's changelog equivalent). Commits made on a worktree must be rebased onto the latest main and then always integrated via fast-forward (merge commits are forbidden); push main, then confirm synchronization with a pull.

This is the default workflow for every commit request. A plain request to commit (e.g. "commit", "commitして") runs this entire flow — including merge into main and push — exactly like `/commit`. Skip merge or push only when the user explicitly asks to keep the commit local.

## Rules to follow

1. Write the title and body in Japanese.
2. Do not write `#N`. It becomes a GitHub issue reference; if needed, write something like `todo 147` instead.
3. Stage only the files touched in the current session, by explicit path. `git add -A` and `git add .` are forbidden.
4. Do not commit unrelated changes; list them in the final report.
5. Do not create new branches. Do not amend. Do not force push.
6. Do not use `--no-verify` or `--no-gpg-sign`.
7. Do not include secrets such as `.env`, `credentials*`, or keys.
8. Commits on a worktree — including a detached HEAD — must be merged into main immediately; do not finish by pushing from the working worktree.
9. Split logically separable changes into grouped commits (do not bundle unrelated chunks into one commit).
10. Append a `Co-authored-by` trailer to the end of every commit message body. **Use the model name and email address of the agent currently running** (do not leave placeholders, and do not use another model's name). The format is `Co-authored-by: NAME <EMAIL>`. On Cursor, EMAIL is `cursoragent@cursor.com`. Put a blank line between the title and the body, and another blank line immediately before the trailer. Do not abbreviate or alter the model name (example: `Co-authored-by: Cursor Grok 4.5 <cursoragent@cursor.com>`).

## Procedure

### 1. Check the state

Run the following in parallel:

- `git status` (do not use `-uall`)
- `git diff`
- `git diff --staged`
- `git log --oneline -10`

Also check whether a changelog file exists (`CHANGELOG.md`, `CHANGELOG`, `changelog.md`, etc. — follow the repository's conventions).

Done once all changes can be classified as from the current session, unrelated, or secret candidates.

### 2. Check with autoreview

Before updating the changelog, always read and follow the `autoreview` skill. The scope is the local changes from the current session (staged / unstaged / untracked). Exclude unrelated diffs from the scope and record the excluded paths.

`/commit` is a request that authorizes changes, so fix autoreview's "in-scope blockers" and re-review. Leave commit, push, PR updates, and merges to the subsequent steps of this procedure; autoreview itself must not perform them.

Do not proceed to the changelog update until autoreview is clean. If there are outstanding items that require stopping and confirmation, or items that do not converge, stop and report without touching the changelog, committing, or pushing.

### 3. Update the changelog

Changes matching any of the following must be appended to the changelog after autoreview is clean and before committing:

- New features, behavior changes, UI/UX changes
- User-observable bug fixes
- Breaking changes and changes requiring migration
- Public API / CLI changes

Do not add entries for the following. In the final report, note "changelog skipped" with the reason.

- Tests only, internal refactoring, CI, type-only changes, comments only
- Docs-only changes (except additions of user-facing documentation or changes with real user impact)
- Dependency updates with no user impact
- Changes added and reverted within the same session
- Repositories with no changelog file

**File roles (when both exist in the repository)**

| File | When to write | What to write |
|---|---|---|
| `CHANGELOG.md` | User-facing changes listed above | One-line history for developers |
| `docs/release_notes.md` or equivalent for the App Store "What's New" | Only when preparing an App Store submission or when explicitly asked | Polished copy for pasting into the store. Do not write every time |

In repositories without `CHANGELOG.md`, follow the existing changelog equivalent. Skip only when there is no changelog at all.

**How to write (match the house style; if unclear, stop and ask)**

1. Append under the leading `## … Unreleased` (or equivalent). If there is none, create `## X.Y.Z — Unreleased` at the top only when the next patch version can be determined from the existing version numbers. If it cannot be determined, follow the existing format or stop because the decision cannot be made.
2. In repositories with categories (e.g. `### Added` / `### Changed` / `### Fixed`), place entries under the appropriate heading. Otherwise use a flat `-` list.
3. **One line, concise.** Prefer `Area: what was done`. Avoid long prose, hard wraps, and repeated verbose phrasing.
4. If ordering by impact is the convention: breaking → features → fixes → other.
5. Do not write `#N` in the changelog either (rule 2). If PR numbers are the repository convention, follow it; otherwise omit them.
6. Do not create duplicate entries. If the existing Unreleased section already has an entry with the same gist, do not add one.
7. The changelog diff is part of the current session's changes; include it in a subsequent commit.

**App Store What's New (optional, at submission time)**

Only when the user asks for release/submission preparation, update `docs/release_notes.md` (or equivalent) from the relevant version of `CHANGELOG.md`. Do not touch it during everyday `/commit` runs.

**Right after a release**

If a release was made with a finalized version, finish by creating `## X.Y.Z — Unreleased` for the next patch at the top, with empty category headings in place.

### 4. Stage and commit

`git add` the relevant files by explicit path, re-check the staged diff, then commit. Stage and commit sequentially.

If there are multiple logical units, repeat stage → commit per unit (e.g. separate implementation and changelog, separate unrelated modules).

```sh
git commit -m "$(cat <<'EOF'
<title in Japanese>

<body (optional)>

Co-authored-by: NAME <EMAIL>
EOF
)"
```

Note: replace `NAME` and `EMAIL` with the model name and email of the agent currently running (example: `Cursor Grok 4.5` / `cursoragent@cursor.com`). Do not commit with placeholders left in place.

When creating multiple commits, attach the same `Co-authored-by` to each. Record the commit SHA (all of them if multiple); done once the working worktree is in the expected state.

### 5. On a worktree, merge into main immediately (rebase → ff-only, merge commits forbidden)

Use `git worktree list --porcelain` to identify where `refs/heads/main` is checked out. If the current location is not main, do the following right after committing:

1. Check `git status --short --branch` in the main checkout. If a remote exists and main is behind, update the local main with `git pull --ff-only` (if there is no remote, or this fails, proceed with the local main as-is).
2. Run `git rebase main` on the worktree branch to catch it up to main. If conflicts occur, resolve them and `git rebase --continue`. Note that rebasing changes the tip SHA.
3. Compare the paths of uncommitted changes on main with the paths changed by these commits.
4. If the paths do not overlap, run `git merge --ff-only <post-rebase tip commit SHA>` in the main checkout, keeping main's uncommitted changes intact.
5. If `--ff-only` fails, the rebase was insufficient: go back to step 2 and redo `git rebase main`. Never use `--no-ff` or a plain `git merge`.
6. Confirm integration with `git merge-base --is-ancestor <each post-rebase commit SHA> main`.

Do not stop merely because main is dirty. Stop only when the changed paths overlap or untracked files would be overwritten; do not stash, discard, or bundle main's changes. If rebase conflicts cannot be resolved, restore the original state with `git rebase --abort` and then stop.

If no main checkout exists, do not create a new worktree or branch; report the post-rebase commit SHA and stop.

### 6. Push main and verify with a pull

Push is part of the default flow; do not stop after committing. If you committed on a worktree, run `git push` from the main checkout; if you committed directly on main, run it from the current location. If upstream is not configured, use `git push -u origin main`.

After pushing:

1. `git pull --ff-only` (or an equivalent fast-forward sync)
2. Confirm with `git status --short --branch` that main and the remote are in sync

If the push fails, do not force it; if a pull or rebase is needed, confirm with the user.

## On failure

- autoreview does not become clean: do not touch the changelog, commit, or push; report the outstanding items and the reason for stopping.
- pre-commit hook failure: fix the cause, re-stage, and create a new commit. Do not amend.
- Path overlap with main: report the post-rebase commit SHA on the worktree and stop.
- Rebase conflicts cannot be resolved: restore the original state with `git rebase --abort`, then report the situation and the commit SHA and stop.
- Secret detected: do not stage; report to the user.
- Unrelated diffs: do not include them; list them in the final report.
- Unknown changelog Unreleased format: if the existing style cannot be inferred, do not append anything; confirm with the user.

## Completion criteria

- autoreview is clean.
- The required changelog has been updated (or a skip reason has been reported).
- Only the current session's changes have been committed with Japanese messages, and every commit has a `Co-authored-by` with the model name.
- On a worktree, the commits are ancestors of main.
- main has been pushed to the remote, is in sync after the pull, and no force push was used.

## Final report

Keep it short, but always include the following:

- Commit SHAs and titles
- Changelog: what was appended, or the reason for skipping
- The result of the push / main sync
