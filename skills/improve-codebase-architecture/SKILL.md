---
name: improve-codebase-architecture
description: コードベースをスキャンしてdeepening opportunities（深化の機会）を探し、視覚的なHTMLレポートとして提示する。選んだ候補をgrillingで徹底検討する。
disable-model-invocation: true
---

# コードベースのアーキテクチャ改善

アーキテクチャの摩擦を明らかにし、**deepening opportunity**（深化の機会）を提案する。浅いmoduleを深いmoduleに変えるリファクタリングである。狙いはテストのしやすさと、AIにとっての動きやすさである。

このコマンドは、プロジェクトのドメインモデルに _裏付けられ_、共有の設計語彙の上に成り立つ。

- `/codebase-design` skillを実行し、アーキテクチャの語彙（**module**、**interface**、**depth**、**seam**、**adapter**、**leverage**、**locality**）とその原則（deletion test、「interfaceがテスト面である」「adapter1つ＝仮説上のseam、2つ＝本物」）を得る。あらゆる提案でこれらの語を正確に使い、「component」「service」「API」「boundary」へ流れない。
- `CONTEXT.md`のドメイン言語は、良いseamに名前を与える。`docs/adr/`のADRは、このコマンドが蒸し返すべきでない決定を記録している。

## 手順

### 1. 探索

**スキャンの前に範囲を決める — YAGNI。** moduleを深化させる見返りは、将来そこへ加える変更を楽にすることである。だから最近変更のあったコードベースの部分に重みを置く。見る前に、*どこ*を見るかを決める。

- ユーザーが方向性を示した場合は — module、サブシステム、痛点 — それを受け取り、以下の推論を省く。
- そうでなければ、commit履歴（`git log --oneline`）を適度な長さ遡り、コードベースのホットスポット — 繰り返し現れるファイルや領域 — を見つけ、まずそのパスに注意を引かせる。変更が散らばっていて明確なホットスポットがなければ、網を広げる。

まずプロジェクトのドメイン用語集（`CONTEXT.md`）と、触る領域に関するADRを読む。

次にAgentツールを`subagent_type=Explore`で使い、コードベースを歩く。固定的なヒューリスティックに従わず、有機的に探索して、摩擦を感じた箇所を記録する。

- どこで、一つの概念を理解するのに多くの小さなmoduleを行き来しなければならないか。
- どこでmoduleが **shallow**（浅い）か — interfaceが実装とほぼ同じくらい複雑になっていないか。
- どこで、テストのためだけに純粋関数が抽出され、実際のバグはその呼び出し方に隠れているか（**locality**が無い）。
- どこで、強く結合したmoduleがseamを越えて漏れているか。
- コードベースのどこが未テストか、または現在のinterface越しではテストしにくいか。

浅いと疑ったものには **deletion test** を適用する。それを消すと複雑さは集中するか、ただ移動するだけか。「はい、集中します」が求めるシグナルである。

### 2. 候補をHTMLレポートとして提示

リポジトリに何も置かないよう、自己完結したHTMLファイルをOSの一時ディレクトリへ書き出す。一時ディレクトリは`$TMPDIR`から解決し、フォールバックは`/tmp`（Windowsでは`%TEMP%`）。`<tmpdir>/architecture-review-<timestamp>.html`へ書き、実行ごとに新しいファイルにする。ユーザーのために開く — Linuxでは`xdg-open <path>`、macOSでは`open <path>`、Windowsでは`start <path>` — そして絶対パスを伝える。

レポートはレイアウトとスタイリングに **CDN経由のTailwind** を使い、グラフ・フロー・シーケンスで構造が確実に伝わる図には **CDN経由のMermaid** を使う。Mermaidと手作りのCSS/SVGビジュアルを混ぜる。関係がグラフの形のとき（call graph、依存、sequence）はMermaidを使い、より編集的なもの（mass diagram、断面図、collapseのアニメーション）が欲しいときは手作りのdiv/SVGを使う。各候補には **before/afterのビジュアル** を付ける。ビジュアルであれ。

各候補について、次を含むカードを描く。

- **Files** — 関係するファイル・module
- **Problem** — なぜ今のアーキテクチャが摩擦を起こしているか
- **Solution** — 何が変わるかの平易な説明
- **Benefits** — localityとleverageの観点で、テストがどう改善するか
- **Before / After の図** — 並べて、手作りで、浅さと深化を示す
- **Recommendation strength** — `Strong`、`Worth exploring`、`Speculative`のいずれかで、バッジとして描画

レポートの最後を **Top recommendation** のセクションで締める。どの候補に最初に取り組むかと、その理由である。

**ドメインには`CONTEXT.md`の語彙を、アーキテクチャには`/codebase-design`の語彙を使う。** `CONTEXT.md`が「Order」と定義しているなら、「the Order intake module」と語る。「the FooBarHandler」でも「the Order service」でもない。

**ADRとの衝突**: 候補が既存のADRと矛盾する場合、その摩擦がADRを見直すに足るほど本物のときだけ表面化させる。カードに明示する（例: 警告のcallout: _「ADR-0007と矛盾する — しかし〜のため再考する価値がある」_）。ADRが禁じる理論上のリファクタリングをすべて列挙しない。

完全なHTMLのscaffold、図のパターン、スタイリングの指針は [HTML-REPORT.md](HTML-REPORT.md) を参照。

interfaceはまだ提案しない。ファイルを書いた後、ユーザーに「この中でどれを検討しますか」と尋ねる。

### 3. Grillingのループ

ユーザーが候補を選んだら、`/grilling` skillを実行し、決定木を一緒にたどる。制約、依存、深化したmoduleの形、seamの裏に置くもの、生き残るテストである。

決定が固まるにつれ、副作用はinlineで起きる。`/domain-modeling` skillを実行して、ドメインモデルを最新に保つ。

- **深化したmoduleに、`CONTEXT.md`に無い概念から名前を付ける？** その用語を`CONTEXT.md`に加える。ファイルが無ければ遅延生成する。
- **会話の中で曖昧な用語を研いだ？** その場で`CONTEXT.md`を更新する。
- **ユーザーが、重みのある理由で候補を却下した？** ADRを提案する。こう切り出す。_「将来のアーキテクチャレビューが同じものを再提案しないよう、これをADRとして記録しますか」_ その理由が将来の探索者に本当に同じ再提案を避けるために必要になるときだけ提案する。一時的な理由（「今やるほどの価値は無い」）や自明な理由は省く。
- **深化したmoduleの別のinterfaceを検討したい？** `/codebase-design` skillを実行し、design-it-twiceの並列サブエージェントパターンを使う。
