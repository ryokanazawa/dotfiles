---
name: start-work-branch
description: 作業内容から意味のあるGitブランチを作成してから、本来の作業を開始する。Git worktreeのdetached HEADを、識別しやすい作業ブランチへ移すときに明示的に使う。
---

# 作業ブランチを開始する

ファイルを変更する前に、次の順序で作業ブランチを準備する。

1. `git rev-parse --is-inside-work-tree`、`git status --short`、
   `git branch --show-current`、`git worktree list --porcelain` を実行する。
2. 未コミット変更がある場合は、変更元を安全に判断できないためブランチを作らず、
   状態と候補名を示してユーザーへ確認する。
3. 現在のブランチが作業内容を表す名前なら、そのブランチを維持して手順6へ進む。
   `main`、`master`、`develop`、`trunk`、または detached HEAD なら新規作成へ進む。
4. ユーザーがブランチ名を指定していればそれを優先する。指定がなければ依頼内容を
   2〜5語の短い英語kebab-caseに要約し、リポジトリ指示のprefixを付ける。
   prefix指定がなければ、実行中のエージェント名を小文字kebab-caseで使う
   （例: `codex/`、`claude/`、`gemini/`）。モデル名やバージョンは使わない。
   エージェント名を判別できない場合だけ `agent/` を使う。
5. `git check-ref-format --branch <name>` で妥当性を確認する。ブランチが既に存在する、
   または別worktreeで使用中なら作成せず、衝突理由と別名候補を示して確認する。
   問題がなければ `git switch -c <name>` を実行する。
6. `git branch --show-current` と `git status --short` で結果を確認する。
   意図したブランチ名が表示されるまで本来の作業を開始しない。
7. 使用するブランチ名を短く報告し、元の依頼を続行する。

ブランチ準備だけを行い、コミット、push、PR作成は元の依頼に含まれない限り実行しない。
