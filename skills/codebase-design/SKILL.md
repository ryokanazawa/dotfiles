---
name: codebase-design
description: deep module を設計するための共有語彙。module の interface を設計・改善したいとき、deepening の機会を見つけたいとき、seam の位置を決めたいとき、コードをテストしやすく・AI が把握しやすくしたいとき、または他の skill に deep module の語彙が必要なときに使う。
---

# コードベース設計

**deep module** を設計する: 小さな interface の背後に大量の振る舞いを置き、clean な seam に配置し、その interface 経由でテストできるようにする。コードを設計・再構築するところはどこでも、この言葉遣いと原則を使う。狙いは、呼び出し側にとっての leverage、保守者にとっての locality、全員にとってのテスト容易性である。

## 用語集

これらの用語はそのまま使う — 「component」「service」「API」「boundary」で置き換えない。言葉の一貫性がこの語彙の目的そのものである。

**Module** — interface と implementation を持つものすべて。意図的にスケールに依存しない: 関数、クラス、パッケージ、層をまたぐ slice まで。_避ける_: unit, component, service。

**Interface** — 呼び出し側がその module を正しく使うために知らなければならないすべて: 型の signature だけでなく、不変条件、順序の制約、エラーの形態、必要な設定、性能特性も含む。_避ける_: API, signature（狭すぎる — 型レベルの表面しか指さない）。

**Implementation** — module の中身であり、コード本体。**Adapter** とは区別する: implementation が大きな小さな adapter（Postgres の repository）もあれば、implementation が小さな大きな adapter（インメモリの fake）もある。話題が seam のときは「adapter」を、それ以外は「implementation」を使う。

**Depth** — interface における leverage: 呼び出し側（またはテスト）が学ばなければならない interface 1単位あたりに引き出せる振る舞いの量。大量の振る舞いが小さな interface の背後にあれば module は **deep** であり、interface が implementation とほぼ同じくらい複雑なら **shallow** である。

**Seam** _（Michael Feathers）_ — その場所のコードを編集せずに振る舞いを変えられる場所。module の interface が存在する*位置*である。seam をどこに置くかは、その背後に何を置くかとは独立した設計判断である。_避ける_: boundary（DDD の bounded context と意味が重なる）。

**Adapter** — seam において interface を満たす具体的な存在。*役割*（どの slot を埋めるか）を表し、中身（何が入っているか）は表さない。

**Leverage** — depth から呼び出し側が得るもの: 学ぶ interface 1単位あたりの能力が増える。1つの implementation が N 箇所の呼び出しと M 個のテストにわたって効果を発揮する。

**Locality** — depth から保守者が得るもの: 変更、バグ、知識、検証が、呼び出し側全体へ散らばらず一箇所に集まる。一度直せば、どこでも直っている。

## deep と shallow

**deep module** = 小さな interface + 大量の implementation:

```
┌─────────────────────┐
│   Small Interface   │  ← Few methods, simple params
├─────────────────────┤
│                     │
│  Deep Implementation│  ← Complex logic hidden
│                     │
└─────────────────────┘
```

**shallow module** = 大きな interface + わずかな implementation（避ける）:

```
┌─────────────────────────────────┐
│       Large Interface           │  ← Many methods, complex params
├─────────────────────────────────┤
│  Thin Implementation            │  ← Just passes through
└─────────────────────────────────┘
```

interface を設計するときは、次のことを問う:

- メソッド数を減らせるか？
- parameter を簡素にできるか？
- より多くの複雑さを内部に隠せるか？

## 原則

- **depth は implementation ではなく interface の性質である。** deep module は、内部では小さく・mock 可能で・差し替え可能な部品で構成されていてよい — それらが interface の一部ではないというだけである。module は、interface にある **external seam** に加えて、**internal seam**（implementation にプライベートで、自前のテストが使う）を持てる。
- **削除テスト。** module を削除すると想像する。複雑さが消えるなら、それは単なる pass-through だったということである。複雑さが N 箇所の呼び出し側に再び現れるなら、それは存在する価値を果たしていた。
- **interface がテスト面である。** 呼び出し側とテストは同じ seam をまたぐ。interface の*向こう側*をテストしたいなら、module の形がおそらく間違っている。
- **adapter が1つなら仮想的な seam、2つなら本物の seam。** seam を越えて実際に変わるものがない限り、seam を導入しない。

## テストしやすい設計

良い interface はテストを自然にする:

1. **依存は受け取り、生成しない。**

   ```typescript
   // Testable
   function processOrder(order, paymentGateway) {}

   // Hard to test
   function processOrder(order) {
     const gateway = new StripeGateway();
   }
   ```

2. **結果を返し、副作用を起こさない。**

   ```typescript
   // Testable
   function calculateDiscount(cart): Discount {}

   // Hard to test
   function applyDiscount(cart): void {
     cart.total -= discount;
   }
   ```

3. **表面積を小さく。** メソッドが少ない = 必要なテストが少ない。parameter が少ない = テストの準備が簡単。

## 関係性

- **Module** は **Interface** をちょうど1つ持つ（呼び出し側とテストに提示する表面）。
- **Depth** は **Module** の性質であり、その **Interface** との関係で測る。
- **Seam** は **Module** の **Interface** が存在する場所である。
- **Adapter** は **Seam** に置かれ、**Interface** を満たす。
- **Depth** は呼び出し側に **Leverage** を、保守者に **Locality** を生む。

## 採用しなかった枠付け

- **implementation の行数と interface の行数の比としての depth**（Ousterhout）: implementation を水増しすると評価が高まってしまう。代わりに leverage としての depth を採用する。
- TypeScript の `interface` キーワードやクラスの public メソッドとしての「interface」: 狭すぎる — ここでの interface は、呼び出し側が知らなければならない事実をすべて含む。
- 「boundary」: DDD の bounded context と意味が重なる。**seam** か **interface** と呼ぶ。

## さらに深く

- **依存が与えられたときに cluster を deepening する** — [DEEPENING.md](DEEPENING.md) を参照: 依存の分類、seam の規律、layer せず replace するテスト。
- **代替 interface の検討** — [DESIGN-IT-TWICE.md](DESIGN-IT-TWICE.md) を参照: 並列のサブエージェントを起動して interface を根本的に異なる複数のやり方で設計し、depth・locality・seam の配置を比較する。
