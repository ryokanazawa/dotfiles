---
name: find-skills
description: 「Xはどうやるの」「X用のskillを探して」「〜できるskillはある？」といった質問や、機能拡張への関心に対して、agent skillの発見とインストールを助ける。ユーザーがインストール可能なskillとして存在しうる機能を探しているときに使う。
---

# skillを探す

このskillは、open agent skillsエコシステムからskillを発見してインストールするのを助ける。

## このskillを使うとき

次の場合にこのskillを使う:

- 「Xはどうやるの」と聞き、Xが既存skillがありそうな一般的なタスクのとき
- 「X用のskillを探して」「Xのskillはある？」と言ったとき
- 「Xはできる？」と聞き、Xが特殊な機能のとき
- agentの機能拡張に関心を示したとき
- ツール・テンプレート・workflowを探したいとき
- 特定の分野（design、testing、deploymentなど）の助けが欲しいと言ったとき

## Skills CLIとは

Skills CLI（`npx skills`）はopen agent skillsエコシステムのpackage managerである。skillは、専門知識・workflow・ツールによってagentの機能を拡張するモジュール式のパッケージである。

**主要コマンド:**

- `npx skills find [query]` - skillを対話式またはキーワードで検索する
- `npx skills add <package>` - GitHubなどのソースからskillをインストールする
- `npx skills check` - skillの更新を確認する
- `npx skills update` - インストール済みskillをすべて更新する

**skillの閲覧:** https://skills.sh/

## ユーザーのskill探しを助ける手順

### ステップ1: ニーズを理解する

ユーザーが何かの助けを求めたとき、次を見極める:

1. 分野（例: React、testing、design、deployment）
2. 具体的なタスク（例: テストを書く、アニメーションを作る、PRをレビューする）
3. skillが存在しそうなほど一般的なタスクかどうか

### ステップ2: まずleaderboardを確認する

CLI検索を実行する前に、[skills.shのleaderboard](https://skills.sh/)でその分野に有名なskillがすでにないか確認する。leaderboardは総インストール数でskillを順位付けしており、最も人気があり実戦で鍛えられた選択肢が分かる。

例: web開発の上位skill:
- `vercel-labs/agent-skills` — React、Next.js、web design（各100K+インストール）
- `anthropics/skills` — フロントエンドdesign、ドキュメント処理（100K+インストール）

### ステップ3: skillを検索する

leaderboardがユーザーのニーズをカバーしていない場合は、findコマンドを実行する:

```bash
npx skills find [query]
```

例:

- ユーザーが「Reactアプリを速くしたい」と言った場合 → `npx skills find react performance`
- ユーザーが「PRレビューを手伝って」と言った場合 → `npx skills find pr review`
- ユーザーが「changelogを作りたい」と言った場合 → `npx skills find changelog`

### ステップ4: 推奨前に品質を確認する

**検索結果だけでskillを推奨しない。** 必ず次を確認する:

1. **インストール数** — 1K+インストールのskillを優先する。100未満は慎重に扱う。
2. **ソースの信頼性** — 公式ソース（`vercel-labs`、`anthropics`、`microsoft`）は出所不明の作者より信頼できる。
3. **GitHub stars** — ソースリポジトリを確認する。starsが100未満のリポジトリのskillは懐疑的に扱う。

### ステップ5: 選択肢をユーザーに提示する

関連するskillが見つかったら、次を添えてユーザーに提示する:

1. skill名と機能
2. インストール数とソース
3. 実行できるインストールコマンド
4. skills.shで詳しく分かるリンク

応答例:

```
役に立ちそうなskillを見つけました。「react-best-practices」は、Vercel Engineeringによる
ReactとNext.jsのパフォーマンス最適化ガイドラインを提供するskillです。
（185Kインストール）

インストールするには:
npx skills add vercel-labs/agent-skills@react-best-practices

詳細: https://skills.sh/vercel-labs/agent-skills/react-best-practices
```

### ステップ6: インストールを提案する

ユーザーが進めたい場合は、代わりにskillをインストールできる:

```bash
npx skills add <owner/repo@skill> -g -y
```

`-g`フラグはグローバル（ユーザーレベル）にインストールし、`-y`は確認プロンプトをスキップする。

## よくあるskillカテゴリ

検索時は次の一般的なカテゴリを検討する:

| カテゴリ | クエリ例 |
| --------------- | ---------------------------------------- |
| web開発 | react, nextjs, typescript, css, tailwind |
| テスト | testing, jest, playwright, e2e |
| DevOps | deploy, docker, kubernetes, ci-cd |
| ドキュメント | docs, readme, changelog, api-docs |
| コード品質 | review, lint, refactor, best-practices |
| デザイン | ui, ux, design-system, accessibility |
| 生産性 | workflow, automation, git |

## 効果的な検索のコツ

1. **具体的なキーワードを使う**: 「testing」だけより「react testing」の方が良い
2. **別の表現も試す**: 「deploy」で見つからなければ「deployment」や「ci-cd」を試す
3. **人気ソースを確認する**: 多くのskillは`vercel-labs/agent-skills`や`ComposioHQ/awesome-claude-skills`から来ている

## skillが見つからないとき

関連するskillが存在しない場合:

1. 既存のskillが見つからなかったことを伝える
2. 一般的な能力でタスクを直接手伝うことを提案する
3. `npx skills init`で自分のskillを作れることを提案する

例:

```
「xyz」に関連するskillを探しましたが、見つかりませんでした。
このタスクは一般的な能力のまま直接お手伝いできます。このまま進めますか？

よくやる作業なら、自分のskillを作ることもできます:
npx skills init my-xyz-skill
```
