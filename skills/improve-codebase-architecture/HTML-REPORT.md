# HTMLレポートの形式

アーキテクチャレビューは、OSの一時ディレクトリに置かれた一つの自己完結HTMLファイルとして描画する。TailwindとMermaidはいずれもCDNから読む。Mermaidはグラフ形の図を確実に扱える。手作りのdivとinline SVGは、より編集的なビジュアル（mass diagram、断面図）を受け持つ。両方を混ぜる。すべてをMermaidに頼ると、見た目が画一的になってくる。

## Scaffold

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <title>Architecture review — {{repo name}}</title>
    <script src="https://cdn.tailwindcss.com"></script>
    <script type="module">
      import mermaid from "https://cdn.jsdelivr.net/npm/mermaid@11/dist/mermaid.esm.min.mjs";
      mermaid.initialize({ startOnLoad: true, theme: "neutral", securityLevel: "loose" });
    </script>
    <style>
      /* small custom layer for things Tailwind doesn't cover cleanly:
         dashed seam lines, hand-drawn-feeling arrow heads, etc. */
      .seam { stroke-dasharray: 4 4; }
      .leak { stroke: #dc2626; }
      .deep { background: linear-gradient(135deg, #0f172a, #1e293b); }
    </style>
  </head>
  <body class="bg-stone-50 text-slate-900 font-sans">
    <main class="max-w-5xl mx-auto px-6 py-12 space-y-12">
      <header>...</header>
      <section id="candidates" class="space-y-10">...</section>
      <section id="top-recommendation">...</section>
    </main>
  </body>
</html>
```

## ヘッダー

リポジトリ名、日付、コンパクトな凡例: 塗りつぶしの箱＝module、破線＝seam、赤い矢印＝漏れ、濃い太線の箱＝深いmodule。導入の段落は書かない。いきなり候補に入る。

## 候補カード

図が主役である。文章は少なく平易に、用語集（`/codebase-design` skill由来）の語を気取らずに使う。

各候補は一つの`<article>`である。

- **タイトル** — 短く、深化に名前を付ける（例: 「Order intake pipelineをcollapseする」）。
- **バッジ行** — recommendation strength（`Strong`＝emerald、`Worth exploring`＝amber、`Speculative`＝slate）に加え、依存カテゴリのタグ（`in-process`、`local-substitutable`、`ports & adapters`、`mock`）。
- **Files** — monospaceのリスト、`font-mono text-sm`。
- **Before / After の図** — 目玉。二つのカラムを並べる。パターンは下記を参照。
- **Problem** — 一文で。何が痛いか。
- **Solution** — 一文で。何が変わるか。
- **Wins** — bulletで、各項目6語以内。例: 「テストは一つのinterfaceを叩く」「Pricingロジックの漏れが止まる」「浅いwrapperを4つ削除」。
- **ADR callout**（該当時のみ）— amber系の箱に一行。

説明文の段落は書かない。図を理解させるのに一段落が必要なら、図を描き直す。

## 図のパターン

候補に合うパターンを選ぶ。混ぜる。すべての図を同じ見た目にしない。バリエーション自体が狙いの一部である。

### Mermaid graph（依存・call flowの主力）

言いたいことが「XがYを呼び、YがZを呼ぶ、この散らかりようを見ろ」のときは、Mermaidの`flowchart`または`graph`を使う。突然放り込まれた印象にならないよう、Tailwindで整えたカードで包む。classDefでスタイリングし、漏れのedgeを赤に、深いmoduleを濃い色にする。sequence diagramは「before: 6回の往復、after: 1回」によく効く。

```html
<div class="rounded-lg border border-slate-200 bg-white p-4">
  <pre class="mermaid">
    flowchart LR
      A[OrderHandler] --> B[OrderValidator]
      B --> C[OrderRepo]
      C -.leak.-> D[PricingClient]
      classDef leak stroke:#dc2626,stroke-width:2px;
      class C,D leak
  </pre>
</div>
```

### 手作りの箱と矢印（Mermaidのレイアウトが思うようにいかないとき）

moduleは枠線とラベル付きの`<div>`にする。矢印はinline SVGの`<line>`または`<path>`要素で、relativeなコンテナの上にabsolute配置する。「after」の図を、内部をグレイアウトした一つの太枠の深いmoduleとして感じさせたいときは、これに手を伸ばす。Mermaidではあの重みが出ない。

### 断面図（層になった浅さに合う）

横方向のバンド（`h-12 border-l-4`）を積み重ね、callが通過する層を見せる。Before: 何もしていない薄い層が6つ。After: 統合した責務のラベルを付けた、厚いバンドが1つ。

### mass diagram（「実装と同じくらい広いinterface」に合う）

moduleごとに二つの長方形 — interfaceの表面積を表すものと、implementationを表すもの。Before: interfaceの長方形がimplementationの長方形とほぼ同じ高さ（浅い）。After: interfaceの長方形は低く、implementationの長方形は高い（深い）。

### call graphのcollapse

Before: 関数呼び出しのツリーをネストした箱で描く。After: 同じツリーを一つの箱にcollapseし、内部化した呼び出しはその中でフェード表示する。

## スタイルの指針

- 企業ダッシュボードではなく編集寄りに。余白はたっぷりと。見出しのserifは任意（`font-serif`はstone/slateと相性が良い）。
- 色は慎む: アクセント一つ（emeraldかindigo）に加え、漏れ用の赤と警告用のamber。
- 図は高さ320px程度に収め、before/afterをスクロールなしで無理なく並べる。
- 図の中のmoduleラベルには`text-xs uppercase tracking-wider`を使う。UIではなく模式図として読まれるべきである。
- scriptはTailwind CDNとMermaidのESM importだけ。レポートはそれ以外すべて静的である。アプリのコードは載せず、Mermaid自身の描画を超えるinteractivityも載せない。

## Top recommendationのセクション

一つ大きなカードを置く。候補の名前、理由を一文、そのカードへのアンカーリンク。以上である。

## トーン

平易で簡潔に。ただしアーキテクチャの名詞と動詞は`/codebase-design` skillからそのまま持ってくる。簡潔さは用語の漂移の言い訳にならない。

**正確に使う:** module, interface, implementation, depth, deep, shallow, seam, adapter, leverage, locality.

**絶対に置き換えない:** component, service, unit（moduleの代わりに） · API, signature（interfaceの代わりに） · boundary（seamの代わりに） · layer, wrapper（moduleを意味するときのmoduleの代わりに）。

**このスタイルに合う言い回し:**

- 「Order intake moduleは浅い — interfaceは実装とほぼ同じ。」
- 「Pricingはseamを越えて漏れる。」
- 「深化させる: interfaceは一つ、テストする場所も一つ。」
- 「二つのadapterがseamを正当化する: 本番はHTTP、テストはin-memory。」

**Winsのbullet** は、得られる利得を用語集の語で名指す: *"locality: バグは一つのmoduleに集中する"*、*"leverage: interfaceは一つ、呼び出し側はN箇所"*、*"interfaceは縮み、implementationがwrapperを吸収する"*。*"maintainしやすい"* や *"きれいなコード"* とは書かない。これらの語は用語集に無く、居場所を得られない。

歯切れを悪くしない。前置きをしない。「注目すべきは…」と書かない。文がbulletにできるならbulletにする。bulletを削れるなら削る。ある用語が`/codebase-design`の用語集に無ければ、新しい語を作る前に、用語集にある語に手を伸ばす。
