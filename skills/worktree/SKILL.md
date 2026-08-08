---
name: worktree
description: Create a git worktree for the task and rename it to a short name once the implementation content is clear. Use when the user asks to cut a worktree, work in a worktree, or start a task in a worktree.
---

# worktree — 作業用worktreeを切り、実装内容に合わせた短い名前を付ける

タスク開始時にworktreeを切り、実装内容が固まった時点でworktree名とブランチ名を内容を表す短い名前に揃える。

## 命名ルール

- kebab-case、1〜2語、64字以内。実装内容を表す名前にする（例: `fix-login`、`csv-export`、`dark-mode`）。
- チケット番号・日付・モデル名は入れない。
- 既存ブランチと衝突しない名前にする（`git branch --list <名前>` で確認）。

## 手順

### 1. worktreeを切る

- 実装内容がすでに分かっている場合: 命名ルールに従った名前で `EnterWorktree` を `name` 付きで呼ぶ。ホストがランダム接尾辞や `claude/` 接頭辞を付けることがあるため、作成されたディレクトリ名・ブランチ名が望む短い名前と一致しなければ手順2で改名する。一致していれば完了。
- まだ分からない場合: `EnterWorktree` を引数なしで呼ぶ（ランダム名で開始）。
- `EnterWorktree` ツールが無い環境では `git worktree add "$(git rev-parse --show-toplevel)/.claude/worktrees/<名前>" -b <名前>` して `cd` する。実装内容がまだ分からない場合は `wip` などの仮名で作り、手順2で改名する。`.claude/` がignoreされていないリポジトリでは `"$(git rev-parse --git-common-dir)/info/exclude"` に `.claude/` を足す。

### 2. 実装内容が固まったら改名する

着手して実装内容を把握した時点（目安は最初のコミットより前）で、命名ルールに従い新しい名前を決め、次を**1回のBash呼び出しで**実行する。moveすると元のcwdパスが消えるため、分割しない:

```sh
MAIN=$(git worktree list --porcelain | head -1 | sed 's/^worktree //')
ROOT=$(git rev-parse --show-toplevel)
OLD=$(git branch --show-current)
DST="$(dirname "$ROOT")/<新名前>"
git -C "$MAIN" worktree move "$ROOT" "$DST" && echo "moved: $DST" \
  && { [ -z "$OLD" ] || git -C "$MAIN" branch -m "$OLD" "<新名前>"; }
```

- detached HEAD（`OLD` が空）ならディレクトリ改名のみで完了。ブランチ改名はしない。

直後に `EnterWorktree` を呼び、上で出力された `$DST` の絶対パスを**リテラルで** `path` に渡してセッションを新しいパスへ切り替える（Bash呼び出しをまたぐ変数参照は使わない）。`EnterWorktree` が無い環境では `cd` で移動する。move成功から入り直しまでの間に他のBash呼び出しをしない（元のcwdが消えていて失敗する）。

- `branch -m` だけが失敗した場合（名前衝突など）、moveは完了済み。先に上記のとおり `$DST` へ入り直してから、衝突しない名前で `git branch -m <旧名> <別名>` を実行する。

## 補足

- 改名後に `path` で入り直したworktreeは `ExitWorktree` の remove では消えない。ディスクに残るので、mainへ統合後に依頼があれば `git worktree remove` で消す。
