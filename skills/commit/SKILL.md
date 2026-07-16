---
name: commit
description: Create a git commit and push following the user's personal rules — Japanese message, session-only diff, no `#N`, no new branches, optional task-log archive + todo/lessons updates. Use when the user types /commit or asks to commit changes.
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

### 2. プロジェクト固有ファイルの存在確認

以下を確認し、存在するものだけ後続ステップを実行する:

- `tasks/todo.md` → ある場合は **アーカイブステップ + review セクション追記を検討**
- `tasks/lessons.md` → セッション内で訂正があれば **更新を検討**

### 3. アーカイブ（**ソースが 1000 行を超えたときだけ**）

このステップは「毎回呼んで OK」ではない。archive スクリプトは古い日付ブロックを無条件に別ファイルへ動かすので、安全閾値を超えるまでは呼ばない。

判定 → 実行の順:

```sh
need_archive=0
for src in tasks/todo.md tasks/lessons.md; do
  if [[ -f "$src" ]] && (( $(wc -l < "$src") > 1000 )); then
    need_archive=1
  fi
done

if (( need_archive )); then
  if [[ -x scripts/archive-work-logs.sh ]]; then
    scripts/archive-work-logs.sh 1000
  else
    ~/.claude/skills/commit/scripts/archive-work-logs.sh 1000
  fi
fi
```

優先順位: プロジェクト内に `scripts/archive-work-logs.sh` があれば**そちら**を実行（プロジェクト側でメンテされている版を尊重）。無ければ skill 同梱版を使う。

`tasks/todo.md` も `tasks/lessons.md` も無い、または両方 1000 行以下のプロジェクトでは何もしない。アーカイブで差分が出たら同じコミットに含める。

### 4. tasks/todo.md の review 追記（該当時のみ）

現在セッションで `tasks/todo.md` のタスクを進めた場合、対象タスクの `### 変更` の下に `### review` を追記する。例:

```markdown
### review
- やったこと: ○○ を実装、テスト追加
- 動作確認: △△ のログで p50 を確認、SLA 内
- 残課題: なし
```

タスク完了でも `[x]` チェックが付いているだけで review が空ならまだ完了扱いにしない。

### 5. tasks/lessons.md 更新（該当時のみ）

セッション中にユーザーから訂正・指摘を受けて方針が変わった場合、`tasks/lessons.md` の最上部に新規エントリを追加:

```markdown
## <最大番号+1> タイトル
- 事象: 何が起きたか
- 根本原因: なぜ起きたか
- 防止規則: 次回どう避けるか
- 関連: <ファイルパスや commit hash>
```

書く前に既存ファイルを読み、最大番号を確認する。

### 6. メッセージ作成

- タイトル: 1 行・日本語・動詞起点（例: 「○○ を修正」「△△ を追加」）
- 本文: 「なぜ」を 1-2 文で。「何を」はコード差分で読めるので最小限。
- `#N` を含めない (例: 「タスク #147」ではなく「todo 147」のように)。
- 末尾に空行を挟んで `Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>`。

### 7. ステージ + コミット（並列）

並列で:

- 関連ファイルを名指しで `git add path/to/file ...`
- HEREDOC でメッセージを渡してコミット:

```sh
git commit -m "$(cat <<'EOF'
<タイトル日本語>

<本文（任意）>

Co-Authored-By: Claude Opus 4.7 <noreply@anthropic.com>
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
- [ ] `tasks/todo.md` / `tasks/lessons.md` が 1000 行を超えていたらアーカイブを実行したか
- [ ] `tasks/todo.md` に review を追記すべきタスクは追記したか
- [ ] `tasks/lessons.md` に書くべき訂正があれば書いたか
- [ ] `--no-verify` を使っていないか
- [ ] 新ブランチを勝手に作っていないか
- [ ] コミット後に `git push` したか（force は使っていないか）
