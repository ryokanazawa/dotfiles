# Deepening

与えられた依存のもとで、shallow module の cluster を安全に deepening する方法。[SKILL.md](SKILL.md) の語彙 — **module**、**interface**、**seam**、**adapter** — を前提とする。

## 依存の分類

deepening の候補を評価するときは、その依存を分類する。分類によって、deepening した module を seam の向こう側でどうテストするかが決まる。

### 1. In-process

純粋な計算、メモリ内の状態、I/O なし。常に deepening できる — module を統合し、新しい interface 越しに直接テストする。adapter は不要。

### 2. Local-substitutable

ローカルのテスト代替物を持つ依存（Postgres に対する PGLite、インメモリファイルシステム）。代替物が存在すれば deepening できる。deepening した module は、テストスイート内で代替物を動かしてテストする。seam は内部にあり、module の external interface に port は出さない。

### 3. Remote but owned (Ports & Adapters)

ネットワーク境界の向こうにある自前のサービス（マイクロサービス、社内 API）。seam に **port**（interface）を定義する。deep module がロジックを持ち、transport は **adapter** として注入する。テストはインメモリの adapter を使い、本番は HTTP/gRPC/queue の adapter を使う。

提案の形: *"seam に port を定義し、本番用の HTTP adapter とテスト用のインメモリ adapter を実装する。これで、ネットワーク越しにデプロイされていても、ロジックは1つの deep module に置かれる。"*

### 4. True external (Mock)

管理していないサードパーティサービス（Stripe、Twilio など）。deepening した module は外部依存を注入された port として受け取り、テストは mock の adapter を提供する。

## seam の規律

- **adapter が1つなら仮想的な seam、2つなら本物の seam。** 少なくとも2つの adapter が正当化されるのでなければ（通常は本番 + テスト）、port を導入しない。adapter が1つしかない seam は単なる回り道である。
- **internal seam と external seam。** deep module は、interface にある external seam に加えて、internal seam（implementation にプライベートで、自前のテストが使う）を持てる。テストが使うという理由だけで internal seam を interface から露出させない。

## テスト戦略: replace, don't layer

- shallow module に対する古い単体テストは、deepening した module の interface でのテストが存在すれば無駄になる — 削除する。
- 新しいテストは deepening した module の interface に書く。**interface がテスト面である**。
- テストは内部状態ではなく、interface 越しの観測可能な結果を表明する。
- テストは内部のリファクタリングを生き延びるべきである — テストが記述するのは振る舞いであり、implementation ではない。implementation が変わるとテストも変えなければならないなら、それは interface の向こう側をテストしている。
