---
name: commit
description: Create a git commit with changelog when needed, immediately merge worktree commits into main, and push. Use when the user types /commit, or asks to commit or push changes.
---

# /commit — autoreview・changelog・コミット・main反映・push

今セッションの変更だけをコミットする。changelog更新の前に `autoreview` スキルで変更をチェックし、cleanになるまで直す。ユーザー向け変更なら `CHANGELOG.md`（またはリポジトリの changelog 相当）を更新する。worktree上のコミットは最新のmainへrebaseしてから必ずfast-forwardで統合し（merge commit禁止）、mainをpushしてからpullで同期を確認する。

## 守るべきルール

1. タイトル・本文は日本語で書く。
2. `#N`を書かない。GitHubのissue参照になるため、必要なら「todo 147」のように書く。
3. 今セッションで触ったファイルだけを名指しでステージする。`git add -A`と`git add .`は禁止。
4. 無関係な変更はコミットせず、最終報告で列挙する。
5. 新しいブランチを作らない。amendしない。force pushしない。
6. `--no-verify`と`--no-gpg-sign`を使わない。
7. `.env`、`credentials*`、鍵などのsecretを含めない。
8. detached HEADを含むworktreeのコミットは、作業worktreeからpushして終わらず、即mainへマージする。
9. 論理的に分かれる変更はgrouped commitsにする（無関係な塊を1コミットにまとめない）。
10. すべてのコミット本文末尾に`Co-authored-by`を付ける。**実行中の自分自身のモデル名とメールアドレスを入れる**（プレースホルダのまま残さない・他モデルの名前を使わない）。形式は`Co-authored-by: NAME <EMAIL>`。Cursor上なら EMAIL は`cursoragent@cursor.com`。タイトルと本文のあいだに空行を置き、trailerの直前にも空行を置く。モデル名は省略・改変しない（例: `Co-authored-by: Cursor Grok 4.5 <cursoragent@cursor.com>`）。

## 手順

### 1. 状態を確認する

以下を並列で実行する。

- `git status`（`-uall`は使わない）
- `git diff`
- `git diff --staged`
- `git log --oneline -10`

changelogファイルの有無も確認する（`CHANGELOG.md`、`CHANGELOG`、`changelog.md`など。リポジトリの慣習に従う）。

全変更を今セッション由来・無関係・secret候補へ分類できたら完了。

### 2. autoreviewでチェックする

changelogを更新する前に、必ず `autoreview` スキルを読んで従う。対象は今セッション由来のローカル変更（staged / unstaged / untracked）。無関係な差分は対象から除外し、除外したパスを記録する。

`/commit` は変更を許可する依頼なので、autoreviewの「範囲内の阻害事項」は修正して再レビューする。commit・push・PR更新・マージはこの手順の後続ステップに任せ、autoreview自体では行わない。

autoreviewがcleanになるまで changelog 更新へ進まない。停止して確認が必要な残件、または収束しない残件がある場合は、changelog・コミット・pushをせずに報告して停止する。

### 3. changelogを更新する

次のいずれかに当てはまる変更は、autoreviewがcleanになったあと、コミット前にchangelogへ追記する。

- 機能追加・挙動変更・UI/UX の変化
- ユーザーが観測できるバグ修正
- 破壊的変更・移行が必要な変更
- 公開 API / CLI の変更

次は追記しない。最終報告で「changelogスキップ」と理由を書く。

- テストのみ・内部リファクタ・CI・型だけ・コメントのみ
- docs-only（ユーザー向け文書の追加や実質的な利用者影響がある変更を除く）
- ユーザー影響のない依存更新
- 同一セッション内で追加して取り消した変更
- changelogファイルがリポジトリに存在しない

**ファイルの役割（リポジトリに両方ある場合）**

| ファイル | いつ書く | 何を書く |
|---|---|---|
| `CHANGELOG.md` | 上記のユーザー向け変更 | 開発用の1行履歴 |
| `docs/release_notes.md` など App Store「最新情報」用 | App Store 提出準備・明示依頼時のみ | ストア貼り付け用の丁寧な文面。毎回は書かない |

`CHANGELOG.md` が無いリポジトリでは、存在する changelog 相当に従う。changelog が無い場合だけスキップする。

**書き方（ハウススタイルに合わせる。不明なら確認して停止）**

1. 先頭の `## … Unreleased`（または同等）へ追記。無ければ既存の版番号から次の patch 版を確定できる場合に限り、`## X.Y.Z — Unreleased` を先頭に作る。確定できなければ既存形式に合わせるか、判断不能として停止する。
2. 分類があるリポジトリ（例: `### Added` / `### Changed` / `### Fixed`）では適切な見出しの下へ。無ければフラットな `-` リスト。
3. **1行・簡潔**。`Area: 何をしたか` を優先。長文・硬折り返し・「〜しました。」の冗長連発を避ける。
4. 影響順が慣習なら: 破壊的 → 機能 → 修正 → その他。
5. `#N` はコミットと同様に書かない（ルール2）。PR番号がリポジトリ慣習ならそれに従い、無ければ省略。
6. 重複エントリを作らない。既存 Unreleased に同旨があれば足さない。
7. changelog の差分も今セッションの変更として後続コミットに含める。

**App Store 最新情報（任意・提出時）**

ユーザーがリリース／提出準備を求めたときだけ、`CHANGELOG.md` の当該版から `docs/release_notes.md`（または同等）を更新する。日常の `/commit` では触らない。

**リリース直後**

バージョンを確定してリリースした場合、次の patch の `## X.Y.Z — Unreleased` を先頭に作り、空の分類見出しを置いてから終える。

### 4. ステージしてコミットする

関連ファイルを名指しで`git add`し、ステージ差分を再確認してからコミットする。ステージとコミットは直列に行う。

論理単位が複数ある場合は、単位ごとにステージ→コミットを繰り返す（例: 実装とchangelogを分ける、無関係なモジュールを分ける）。

```sh
git commit -m "$(cat <<'EOF'
<タイトル日本語>

<本文（任意）>

Co-authored-by: NAME <EMAIL>
EOF
)"
```

注: `NAME` と `EMAIL` は実行中エージェント自身のモデル名とメールに置き換える（例: `Cursor Grok 4.5` / `cursoragent@cursor.com`）。プレースホルダのままコミットしない。

複数コミットする場合も、各コミットに同じ`Co-authored-by`を付ける。コミットSHA（複数なら全部）を取得し、作業worktreeが期待どおりの状態なら完了。

### 5. worktreeなら即mainへマージする（rebase → ff-only、merge commit禁止）

`git worktree list --porcelain`で`refs/heads/main`のチェックアウト先を特定する。現在地がmainでなければ、コミット直後に次を行う。

1. mainチェックアウトで`git status --short --branch`を確認する。remoteがありmainが遅れていれば`git pull --ff-only`でローカルmainを最新化する（remoteが無い、または失敗した場合はローカルmainのままで進める）。
2. worktreeブランチ上で`git rebase main`を実行し、mainに追いつかせる。コンフリクトしたら解消して`git rebase --continue`する。rebaseすると先端SHAが変わる点に注意する。
3. mainの未コミット変更パスと今回のコミット群の変更パスを比較する。
4. パスが重ならなければ、mainチェックアウト側で`git merge --ff-only <rebase後の先端コミットSHA>`を実行する。mainの未コミット変更は保持したまま行う。
5. `--ff-only`が失敗する場合はrebaseが不足しているので、ステップ2へ戻って`git rebase main`からやり直す。`--no-ff`や通常の`git merge`は絶対に使わない。
6. `git merge-base --is-ancestor <rebase後の各コミットSHA> main`で反映を確認する。

mainがdirtyという理由だけでは停止しない。変更パスが重なる、未追跡ファイルを上書きする場合だけ停止し、mainの変更をstash・破棄・同梱しない。rebaseのコンフリクトを解消できない場合は`git rebase --abort`で元に戻してから停止する。

mainチェックアウトが存在しない場合は、新しいworktreeやブランチを作らず、rebase後のコミットSHAを報告して停止する。

### 6. mainをpushし、pullで確認する

worktreeでコミットした場合はmainチェックアウトから、mainで直接コミットした場合は現在地から`git push`する。upstream未設定なら`git push -u origin main`を使う。

push後:

1. `git pull --ff-only`（または同等のfast-forward同期）
2. `git status --short --branch`でmainとremoteの同期を確認する

push失敗時はforceせず、pullやrebaseが必要ならユーザーへ確認する。

## 失敗時

- autoreviewがcleanにならない: changelog・コミット・pushをせず、残件と停止理由を報告する。
- pre-commit hook失敗: 原因を直し、再ステージして新しいコミットを作る。amendしない。
- mainとのパス重複: worktreeのrebase後コミットSHAを報告して停止する。
- rebaseのコンフリクトを解消できない: `git rebase --abort`で元に戻し、状況とコミットSHAを報告して停止する。
- secret検出: ステージせず、ユーザーへ報告する。
- 無関係な差分: 含めず、最終報告で列挙する。
- changelogのUnreleased形式が不明: 既存スタイルを推測できない場合は追記せず、ユーザーへ確認する。

## 完了条件

- autoreviewがcleanである。
- 必要なchangelogが更新されている（またはスキップ理由が報告されている）。
- 日本語メッセージで今セッションの変更だけがコミットされ、各コミットにモデル名の`Co-authored-by`がある。
- worktreeの場合、コミットがmainの祖先になっている。
- mainがremoteへpushされ、pull後に同期しており、forceしていない。

## 最終報告

短くでよいが、次は必ず含める:

- コミットSHAとタイトル
- changelog: 追記内容、またはスキップ理由
- push / main 同期の結果
