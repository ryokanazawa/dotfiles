# Skillの仕組み

[`writing-for-agents`](SKILL.md)の、skillに特有の **branch**（分岐）。文書がskillのとき何が変わるか — frontmatter、呼び出し方法の選択、router skills。書き方のそれ以外は、すべて`SKILL.md`の汎用リファレンスどおりである。

## 呼び出し

二つの選択があり、二つの負荷をトレードする。

- **model-invoked**（モデル呼び出し）のskillは`description`を保つ。そのためエージェントが自律的に発火でき、他のskillからも到達できる。名前をタイプして使うこともできる。model-invocationは常にユーザーからの到達を _含む_。descriptionはエージェントによる発見を加えるだけで、人間からの到達を決して奪わない。descriptionはそのskillの最上位のcontext pointerであり、常に読み込まれたままになる。発見性と引き換えの、恒久的なcontext loadである。中身がすべてreferenceのmodel-invoked skillは、共有referenceの置き場所にもなる。他のskillがそれを呼び出せるので、複数のskillが必要とするreferenceが一箇所にまとまる。仕組み: `disable-model-invocation`を省略し、triggerのbranch群を載せたモデル向けdescriptionを書く（`SKILL.md`のポインタ作成ルールがすべて適用される）。
- **user-invoked**（ユーザー呼び出し）のskillは、descriptionをエージェントの到達圏から外す。名前をタイプした人間だけが呼び出せ、他のskillからは呼び出せない。context loadはゼロだが、cognitive loadを消費する。それが存在することを覚えていなければならないあなたが、索引である。仕組み: `disable-model-invocation: true`を設定する。`description`は人間向けになり、一行の要約で、triggerの列挙は取り除く。

model-invocationを選ぶのは、エージェント自身がそのskillに到達する必要があるか、他のskillから到達する必要があるときだけである。手動でしか発火しないなら、user-invokedにしてcontext loadを支払わない。

二つのuser-invoked skillの両方が必要とする共有referenceは、そのどちらにも置けない。descriptionが無ければ、どちらからも他方を発火できないからである。skillシステムの外にあるただのファイルへ押し出す。どのskillからも指せる外部referenceにする。

## 呼び出しでの分割

分割のうち、呼び出しによる切り口（sequenceによる切り口は`SKILL.md`にある）。独立したleading wordがあり、それ単独でtriggerになるべきときは、model-invoked skillとして切り出す — 実際にプロンプトで使っているtriggerの単語である。あるいは、他のskillから到達する必要があるときも同じである。新たに常に読み込まれるdescriptionの分のcontext loadを支払うので、その独立した到達は見合う必要がある。

## Router skills

user-invoked skillが増えて覚えきれなくなったら、積み上がったcognitive loadは **router skill**（ルータースキル）で解消する。一つのuser-invoked skillが、他のskillの名前と、それぞれにいつ到達するかを列挙する。人間が覚えるskillが複数ではなく一つで済む。できるのは示唆だけで、発火は決してできない。user-invoked skillにはdescriptionが無いので、人間以外からは到達できない。
