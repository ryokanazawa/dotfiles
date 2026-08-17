---
name: worktree
description: Create a git worktree for the task and rename it to a short name once the implementation content is clear. Use when the user asks to cut a worktree, work in a worktree, or start a task in a worktree.
---

# worktree — cut a working worktree and give it a short name matching the implementation

Cut a worktree when starting a task, and once the implementation content is settled, align the worktree name and branch name to a short name that represents the content.

## Naming rules

- kebab-case, 1–2 words, within 64 characters. Use a name that represents the implementation content (e.g. `fix-login`, `csv-export`, `dark-mode`).
- Do not include ticket numbers, dates, or model names.
- Use a name that does not collide with existing branches (check with `git branch --list <name>`).

## Procedure

### 1. Cut the worktree

- If the implementation content is already known: call `EnterWorktree` with a `name` following the naming rules. The host may append a random suffix or a `claude/` prefix, so if the created directory name / branch name does not match the desired short name, rename it in step 2. If it matches, you are done.
- If not yet known: call `EnterWorktree` with no arguments (start with a random name).
- In environments without the `EnterWorktree` tool, run `git worktree add "$(git rev-parse --show-toplevel)/.claude/worktrees/<name>" -b <name>` and `cd` into it. If the implementation content is not yet known, create it with a provisional name such as `wip` and rename it in step 2. In repositories where `.claude/` is not ignored, add `.claude/` to `"$(git rev-parse --git-common-dir)/info/exclude"`.

### 2. Rename once the implementation content is settled

Once you have started and grasped the implementation content (aim for before the first commit), decide a new name following the naming rules and run the following **in a single Bash invocation**. Do not split it up, because move removes the original cwd path:

```sh
MAIN=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
ROOT=$(git rev-parse --show-toplevel)
OLD=$(git branch --show-current)
DST="$(dirname "$ROOT")/<new-name>"
git -C "$MAIN" worktree move "$ROOT" "$DST" && echo "moved: $DST" \
  && { [ -z "$OLD" ] || git -C "$MAIN" branch -m "$OLD" "<new-name>"; }
```

- On a detached HEAD (`OLD` is empty), renaming the directory alone completes the step. Do not rename a branch.

Immediately afterward, call `EnterWorktree`, passing the absolute path of `$DST` printed above **as a literal** to `path` to switch the session to the new path (do not use variable references across Bash invocations). In environments without `EnterWorktree`, move with `cd`. Do not make any other Bash calls between the successful move and re-entering (the original cwd is gone and they would fail).

- If only `branch -m` failed (name collision, etc.), the move is already complete. Re-enter `$DST` as above first, then run `git branch -m <old-name> <other-name>` with a non-colliding name.

## Notes

- A worktree re-entered via `path` after renaming will not be removed by `ExitWorktree`'s remove. It stays on disk, so if asked after merging into main, remove it with `git worktree remove`.
