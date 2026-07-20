---
name: commit
description: Create a git commit, immediately merge worktree commits into main, and push following the user's personal rules. Use when the user types /commit or asks to commit changes.
---

# /commit — コミット・main反映・push

今セッションの変更だけをコミットする。worktree上のコミットは即mainへマージし、mainをpushする。

## 守るべきルール

1. タイトル・本文は日本語で書く。
2. `#N`を書かない。GitHubのissue参照になるため、必要なら「todo 147」のように書く。
3. 今セッションで触ったファイルだけを名指しでステージする。`git add -A`と`git add .`は禁止。
4. 無関係な変更はコミットせず、最終報告で列挙する。
5. 新しいブランチを作らない。amendしない。force pushしない。
6. `--no-verify`と`--no-gpg-sign`を使わない。
7. `.env`、`credentials*`、鍵などのsecretを含めない。
8. detached HEADを含むworktreeのコミットは、作業worktreeからpushして終わらず、即mainへマージする。

## 手順

### 1. 状態を確認する

以下を並列で実行する。

- `git status`（`-uall`は使わない）
- `git diff`
- `git diff --staged`
- `git log --oneline -10`

全変更を今セッション由来・無関係・secret候補へ分類できたら完了。

### 2. ステージしてコミットする

関連ファイルを名指しで`git add`し、ステージ差分を再確認してからコミットする。ステージとコミットは直列に行う。

```sh
git commit -m "$(cat <<'EOF'
<タイトル日本語>

<本文（任意）>
EOF
)"
```

コミットSHAを取得し、作業worktreeが期待どおりの状態なら完了。

### 3. worktreeなら即mainへマージする

`git worktree list --porcelain`で`refs/heads/main`のチェックアウト先を特定する。現在地がmainでなければ、コミット直後に次を行う。

1. mainチェックアウトで`git status --short --branch`を確認する。
2. mainの未コミット変更パスと今回のコミットの変更パスを比較する。
3. パスが重ならなければ、mainの未コミット変更を保持したまま`git merge --ff-only <コミットSHA>`を実行する。
4. mainが進んでいてfast-forwardできない場合は`git merge --no-edit <コミットSHA>`を実行する。
5. `git merge-base --is-ancestor <コミットSHA> main`で反映を確認する。

mainがdirtyという理由だけでは停止しない。変更パスが重なる、未追跡ファイルを上書きする、または競合した場合だけ停止し、mainの変更をstash・破棄・同梱しない。

mainチェックアウトが存在しない場合は、新しいworktreeやブランチを作らず、コミットSHAを報告して停止する。

### 4. mainをpushする

worktreeでコミットした場合はmainチェックアウトから、mainで直接コミットした場合は現在地から`git push`する。upstream未設定なら`git push -u origin main`を使う。

push後に`git status --short --branch`でmainとremoteの同期を確認したら完了。push失敗時はforceせず、pullやrebaseが必要ならユーザーへ確認する。

## 失敗時

- pre-commit hook失敗: 原因を直し、再ステージして新しいコミットを作る。amendしない。
- mainとのパス重複・競合: worktreeのコミットSHAを報告して停止する。
- secret検出: ステージせず、ユーザーへ報告する。
- 無関係な差分: 含めず、最終報告で列挙する。

## 完了条件

- 日本語メッセージで今セッションの変更だけがコミットされている。
- worktreeの場合、コミットがmainの祖先になっている。
- mainがremoteへpushされ、forceしていない。
