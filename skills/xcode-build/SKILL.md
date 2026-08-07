---
name: xcode-build
description: Open the Xcode project of the current git worktree in Xcode and build it from the command line, reporting errors verbatim. Use when the user asks to open Xcode, build the current worktree, or check that the app still compiles.
---

# xcode-build — 作業中worktreeをXcodeで開いてビルドする

いま作業している worktree の Xcode プロジェクトを `xed` で開き、続けて `xcodebuild` でビルドして結果を報告する。GUI は開くだけ、ビルドの実行と成否判定は CLI 側で行う（エージェントは Xcode へキー入力できないので Cmd+B は押せない）。

ビルドは **read-only**。ソースには触らず、エラーは原文で報告して止まる。修正は別の依頼として扱う。

## 手順

### 1. worktree のルートとリポジトリ規約を確認する

```sh
git rev-parse --show-toplevel   # 以降 $ROOT
```

main チェックアウトでも linked worktree でも同じように効くので、「今作業している worktree」に特別扱いは要らない。

続けてリポジトリの `CLAUDE.md` / `AGENTS.md` / `README.md` にビルドコマンドの規約がないか確認する。**規約があればそれを最優先で使う**。以下はプロジェクト側に指定がない場合の既定。

### 2. ビルドコンテナを特定する

worktree ルート直下だけを見る。深く掘るとサブモジュール・`Pods/`・`*.playground` の中身を拾うので、既定は `-maxdepth 1`。

```sh
find "$ROOT" -maxdepth 1 \( -name "*.xcworkspace" -o -name "*.xcodeproj" -o -name "Package.swift" \) | sort
```

優先順は次のとおり。

1. `*.xcworkspace`（CocoaPods や複数プロジェクト構成では workspace が正）
2. `*.xcodeproj`
3. `Package.swift`（Swift Package 単体）

ルート直下が 0 件のときだけ 1 階層下まで広げ、`Pods/`・`Carthage/`・`.build/`・`*.playground/` 配下は除外する。それでも候補が複数残るならユーザーに確認する。

### 3. Xcode で開く

```sh
xed "$CONTAINER"          # .xcworkspace / .xcodeproj
xed "$ROOT"               # Package.swift だけの場合はディレクトリごと開く
```

同じコンテナが既に開いていれば、そのウィンドウが前面に来る。先に開いておくと、ビルドを待つあいだユーザーが Xcode を触れる。

### 4. スキームを決める

```sh
xcodebuild -list -json -workspace "$CONTAINER"   # workspace の場合
xcodebuild -list -json -project "$CONTAINER"     # xcodeproj の場合
xcodebuild -list -json                           # Package.swift のあるディレクトリで
```

- 1 つならそれを使う。
- 複数ならリポジトリ名・プロダクト名に一致するアプリ本体を選ぶ（例: `Karuta` リポジトリなら `Karuta`。`*Tests` / `*UITests` / `*Watch App` はアプリ本体ではない）。
- 一致で決まらなければユーザーに選ばせる。
- `schemes` が空なら共有スキームが未設定で、`xcodebuild` からは選べない。Xcode の Manage Schemes で Shared を有効化してもらう必要があることを報告して停止する。スキームファイルを自分で作らない。

### 5. destination を候補から選ぶ

**プロジェクト名から推測せず、候補を出してから決める。** 例えば `Karuta` は名前からは iOS アプリに見えるが実際は macOS アプリで、`generic/platform=iOS Simulator` を渡すと `error: Unable to find a destination matching...` で落ちる。

```sh
# -workspace / -project / 省略 の使い分けは手順 4 と同じ
xcodebuild -showdestinations -project "$CONTAINER" -scheme "$SCHEME" 2>&1 | tail -20
```

出た `platform:` を見て選ぶ。

| 候補にあるもの | 指定 |
|---|---|
| `platform:macOS` のみ | destination を省略する |
| `platform:iOS Simulator` | `-destination 'generic/platform=iOS Simulator'` |
| `platform:watchOS Simulator` | `-destination 'generic/platform=watchOS Simulator'` |
| Swift Package（`Package.swift`） | 省略 |

シミュレータの generic destination はコード署名なしでビルドできる。実機向け（`generic/platform=iOS`）は署名が要るので、ユーザーが明示的に求めたときだけ使う。iOS と macOS の両方が出るマルチプラットフォーム構成では、ユーザーが対象を言っていなければアプリの主プラットフォームを選び、選んだ理由を報告に書く。

### 6. ビルドする

出力が長いのでログをファイルへ落とし、成否は終了コードで判定する。

```sh
# -workspace/-project と destination は手順2・5で決めたものに置き換える
xcodebuild build \
  -workspace "$CONTAINER" \
  -scheme "$SCHEME" \
  -destination 'generic/platform=iOS Simulator' \
  > "/tmp/xcodebuild-$SCHEME.log" 2>&1; echo "exit=$?"
```

- `-derivedDataPath` は付けない。DerivedData はコンテナのパスでハッシュ分割されるので worktree ごとに既に分かれており、既定のままなら GUI 側のビルドと同じキャッシュが温まる。
- `clean` はユーザーがクリーンビルドを求めたときだけ付ける。

ログからは次を抜き出して読む。警告を同じ grep に混ぜるとエラー行が押し流されるので、エラーを先に取り、警告は件数で見る。

```sh
grep -n -E "error:|BUILD (SUCCEEDED|FAILED)|The following build commands failed" "/tmp/xcodebuild-$SCHEME.log" | head -40
grep -c "warning:" "/tmp/xcodebuild-$SCHEME.log"
```

終了コード 0 かつ `** BUILD SUCCEEDED **` なら成功。

### 7. 報告する

- 開いたコンテナのパス、使ったスキームと destination
- ビルドの成否
- 失敗ならエラー行を原文のまま（`ファイル:行:列` とメッセージ）。要約に丸めない
- 警告があれば件数と代表例

## 失敗時

- **Swift Package の解決で止まる / lock エラー**: Xcode の GUI が同時にパッケージを解決している。数十秒待って 1 回だけ再実行し、それでも駄目なら Xcode 側の解決完了を待つようユーザーへ伝える。
- **`Unable to find a destination matching...`**: 手順 5 に戻って候補から選び直す。
- **コード署名エラー**: 実機向け destination になっている。シミュレータの generic destination へ切り替える。
- **ビルドエラー**: 原文で報告して停止する。依頼が「ビルドを通して」まで含む場合だけ修正へ進む。
- **Xcode プロジェクトが見つからない**: この worktree は Xcode プロジェクトではないと伝える。`Package.swift` だけなら `swift build` を提案する。

## 完了条件

- Xcode に対象コンテナが開いている。
- `xcodebuild` が終了コード 0 と `BUILD SUCCEEDED` を返している。または、失敗内容がエラー原文つきで報告されている。
- ソースは手つかずである。
