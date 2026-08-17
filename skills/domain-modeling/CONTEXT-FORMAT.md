# CONTEXT.md フォーマット

## 構成

```md
# {Context Name}

{One or two sentence description of what this context is and why it exists.}

## 言語

**Order**:
{A one or two sentence description of the term}
_避ける_: Purchase, transaction

**Invoice**:
納品後に顧客へ送る支払い請求。
_避ける_: Bill, payment request

**Customer**:
注文を行う個人または組織。
_避ける_: Client, buyer, account
```

## ルール

- **意見を持つ。** 同じ概念に複数の語があるなら、最良の1つを選び、残りは `_避ける_` の下に並べる。
- **定義は短く。** 最大1〜2文。それが何であるかを書き、何をするかは書かない。
- **このプロジェクトの context に固有の用語だけを含める。** 一般的なプログラミング概念（タイムアウト、エラー型、ユーティリティパターン）は、プロジェクトで多用していても含めない。用語を追加する前に問う: これはこの context に固有の概念か、一般的なプログラミング概念か。前者だけが対象である。
- **自然なまとまりが出てきたら、用語を見出しの下にグループ化する。** すべての用語が1つのまとまった領域に属するなら、フラットなリストでよい。

## 単一 context と複数 context のリポジトリ

**単一 context（ほとんどのリポジトリ）:** リポジトリのルートに `CONTEXT.md` が1つ。

**複数 context:** リポジトリのルートの `CONTEXT-MAP.md` が、context の一覧、所在、相互関係を載せる:

```md
# Context Map

## Context 一覧

- [Ordering](./src/ordering/CONTEXT.md) — 顧客の注文を受け付けて追跡する
- [Billing](./src/billing/CONTEXT.md) — 請求書を発行して支払いを処理する
- [Fulfillment](./src/fulfillment/CONTEXT.md) — 倉庫のピッキングと出荷を管理する

## 関係

- **Ordering → Fulfillment**: Ordering は `OrderPlaced` イベントを発行し、Fulfillment がそれを消費してピッキングを開始する
- **Fulfillment → Billing**: Fulfillment は `ShipmentDispatched` イベントを発行し、Billing がそれを消費して請求書を発行する
- **Ordering ↔ Billing**: `CustomerId` と `Money` の共有型
```

この skill はどちらの構成が当てはまるか推測する:

- `CONTEXT-MAP.md` があれば、それを読んで context を探す
- ルートの `CONTEXT.md` だけがあれば、単一 context
- どちらもなければ、最初の用語が確定したときにルートの `CONTEXT.md` を遅延して作る

複数の context がある場合は、現在のトピックがどれに関係するか推測する。不明なら確認する。
