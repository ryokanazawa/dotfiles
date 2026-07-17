---
name: commit
description: Create a git commit and push following the user's personal rules — Japanese message, session-only diff, no `#N`, no new branches. Use when the user types /commit or asks to commit changes.
---

# /commit — コミット + push の標準手順

このスキルは「コミットして remote に push する」ための手順書。スコープを広げない。

## 守るべきルール

1. **日本語でメッセージを書く** — タイトル・本文ともに日本語。
2. **`#N` を書かない** — GitHub が issue 参照として解釈してしまう。タスク番号を残したいときは `(#N)` ではなく別表記（例: `tasks/todo.md #147` を本文で言及するなら「todo #147」のような形）に置き換える。
3. **今セッションの変更のみコミット** — `git status` を確認し、自分が触っていないファイルが modified/untracked にあれば**コミットに含めず**、ユーザーに「次の差分が含まれていません: ...」と申告する。
4. **ブランチを勝手に切らない** — 明示指示がない限り現在ブランチ（`main` 等を含む）に直接コミット。
5. **amend しない** — pre-commit hook が失敗した場合も新しいコミットを積む。
6. **`--no-verify` / `--no-gpg-sign` を使わない** — hook が失敗したら原因を直す。
7. **secrets を含めない** — `.env`, `credentials*`, 鍵ファイルなどはステージしない。明示要求があれば警告する。
8. **`git add -A` / `git add .` を避ける** — 関連ファイルを名指しでステージ。

## 手順

### 1. 状態確認（並列）

並列で以下を実行:

- `git status` (untracked 含む。`-uall` は使わない)
- `git diff` (staged/unstaged 両方)
- `git diff --staged` (staged のみ)
- `git log --oneline -10` (直近のコミットスタイルを確認)

### 7. ステージ + コミット（並列）

並列で:

- 関連ファイルを名指しで `git add path/to/file ...`
- HEREDOC でメッセージを渡してコミット:

```sh
git commit -m "$(cat <<'EOF'
<タイトル日本語>

<本文（任意）>

Co-Authored-By: エージェントのモデル名 >
EOF
)"
```

その後（直列で） `git status` を確認し、ワーキングツリーが期待通りクリーンかチェック。

### 8. push する

コミット成功後、現在ブランチを remote に push する。

```sh
git push
```

- upstream 未設定なら `git push -u origin HEAD` を使う。
- `force` / `--force-with-lease` は使わない（ユーザーが明示した場合のみ）。
- push 成功後に `git status` で remote と同期していることを確認する。

## 失敗時の対応

- **pre-commit hook 失敗** → 失敗原因を読む → 原因を修正 → 再度 `git add` + 新規 `git commit`（**amend しない**）。
- **push 失敗** → エラー内容を報告し、rebase/pull が必要ならユーザーに確認してから進める。勝手に force push しない。
- **secrets 検出** → ユーザーに報告して指示を仰ぐ。
- **無関係な差分発見** → コミットに含めず、報告だけする。ユーザーが「含めて」と言うまで待つ。

## チェックリスト（コミット前に必ず確認）

- [ ] メッセージは日本語か
- [ ] `#N` が本文・タイトルに含まれていないか
- [ ] ステージしたファイルは全部このセッションで触ったものか
- [ ] secrets を含めていないか
- [ ] `--no-verify` を使っていないか
- [ ] 新ブランチを勝手に作っていないか
- [ ] コミット後に `git push` したか（force は使っていないか）
