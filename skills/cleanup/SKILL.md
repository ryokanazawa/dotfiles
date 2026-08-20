---
name: cleanup
description: 開発・クリエイティブ系のキャッシュを棚卸しし、計測・分類・承認を経て削除する。ディスクの空き容量が足りない、キャッシュを掃除したい、何が容量を食っているか調べたいと言われたときに使う。
---

# キャッシュの棚卸しと削除

**計測は自由、削除は承認制。** 計測とアプリの起動確認は断りなく進めてよい。削除は、対象と推定容量を提示してユーザーの承認を得てから実行する。承認は提示した枠にだけ及ぶ。

## 1. 計測する

`df -k /System/Volumes/Data` を最初に記録する。これが実解放量の基準値になる。

`du -sk` で候補を測り、サイズ降順に並べる。定番の候補:

- Xcode: `~/Library/Developer/Xcode/DerivedData`、`~/Library/Developer/XCTestDevices`、`~/Library/Developer/XCPGDevices`、`~/Library/Developer/Xcode/iOS DeviceSupport`（OS別に内訳）、`~/Library/Developer/CoreSimulator/Devices`、`~/Library/Caches/com.apple.dt.Xcode`
- シミュレータランタイム: `/Library/Developer/CoreSimulator/Volumes`（`xcrun simctl list runtimes` と `list devices` を突き合わせ、割り当てデバイス0台のランタイムを未使用として挙げる）
- CLI: `~/.codex/log`、`~/Library/Caches/Codex`、`~/Library/Caches/claude-cli-nodejs`、`~/.claude/shell-snapshots`、`~/Library/Caches/org.swift.swiftpm`、`~/Library/Caches/Homebrew`
- Adobe: `~/Library/Caches/Adobe/*`、`~/Library/Application Support/Adobe/Common/Media Cache Files`、`~/Library/Application Support/Adobe/CameraRaw/ModelZoo`
- DaVinci Resolve: `~/Movies/CacheClip`、`~/Movies/ProxyMedia`
- その他: `~/Library/Caches` 上位10件、`~/Library/Containers` 上位10件、`Docker.raw`、`~/Library/Application Support/MobileSync`
- Time Machine: `tmutil listlocalsnapshots /`（`diskutil apfs list` に出るシステムボリュームの sealed snapshot は対象外）

**du の値は APFS のクローンで大きく過大に出る。** シミュレータのデバイスはランタイムからのコピーオンライトなので、du 合計 313GiB が実解放 22GiB だった実績がある。報告では「du ベースの推定、実解放量は df の前後差分で確定」と添え、解放量を約束しない。ローカルスナップショットは du に現れないまま解放を押し止めるので、乖離が大きいときは件数を再確認する。

TCC で読めないディレクトリ（`MobileSync` など）は `Operation not permitted` になる。フルディスクアクセスの付与は提案にとどめ、スキップとして報告する。

完了条件: 候補をすべて測り終え、存在しなかったもの・権限で測れなかったものも「なし」「権限スキップ」として表に載っている。

## 2. 分類する

- **【安全】** 再生成されるだけ。ビルド中間物、CLIキャッシュ、アップデータの残骸、テスト用シミュレータ。
- **【要確認】** 再レンダリング・再ダウンロード・データ喪失が起きる。iOS DeviceSupport（実機接続時に数分）、CoreSimulator/Devices（名前付きの独自デバイスを含むなら一括削除は避ける）、未使用ランタイム、Resolve のプロキシ／最適化メディア、Media Cache、CameraRaw の AI モデル、ブラウザキャッシュ、ローカルスナップショット。**`Docker.raw`** は VM ディスク1本にイメージも volume の永続データも同居するので、丸ごと消さず `docker system prune` などコンテナ側の機構を使う。**`~/Library/Containers`** はサンドボックスアプリの実データ置き場で、パスワードマネージャや連絡先を含む。個別に中身を確認してから聞く。
- **【削除禁止】** Photoshop の AutoRecover、Resolve の `~/Movies/.gallery`（Gallery / PowerGrade）と `~/Movies/Resolve Project Backups`、`~/Library/Developer/Xcode/Archives`、`~/.claude/projects`、`~/.codex/sessions`、`~/Library/Application Support/MobileSync`（実機バックアップ。再取得できず数十GBになる）。これらは計測して表に載せ、削除対象からは外す。

## 3. 承認を得る

【安全】枠をまとめてコマンド案として提示する。【要確認】は再生成コストを添えて個別に聞く。単体で効きの大きいものから順に出す。

承認の範囲は、直前に提示した枠に限る。「削除していいよ」が【安全】枠への返答なら、【要確認】はまだ承認されていない。

## 4. 実行前に確認する

対象アプリ（Xcode / Simulator / Photoshop / Illustrator / Resolve）の起動を `pgrep -lf` で確認し、起動していればユーザーに終了を依頼する。

**プロセスは生かしたまま、対象から外す。** Xcode 終了後も、デバッグ実行していたアプリが DerivedData 内のバイナリから動き続けることがある。`pgrep -lf "DerivedData/.*\.app/Contents/MacOS"` で見つける。DerivedData のディレクトリ名は `Karuta-cjtmqoqoilnvaueqyplxirbuaylr` のようにハッシュ接尾辞を持つので、**プロジェクト名ではなく pgrep が返したパスからディレクトリ名をそのまま採る**。

```bash
find ~/Library/Developer/Xcode/DerivedData -mindepth 1 -maxdepth 1 \
  -not -name '<pgrepが返したディレクトリ名>' -exec rm -rf {} +
```

## 5. 削除する

**シミュレータのデバイスセットは simctl 経由で消す。** `XCTestDevices` と `XCPGDevices` は CoreSimulatorService の管理下にあり、`rm -rf` はサービスの状態と食い違う。

```bash
xcrun simctl --set ~/Library/Developer/XCTestDevices delete all
xcrun simctl --set ~/Library/Developer/XCPGDevices delete all
```

`delete all` の後に空のディレクトリと `device.plist` だけが残ることがある。これは孤児なので `rm -rf` で片付けてよい。

既定セット `~/Library/Developer/CoreSimulator/Devices` にも同じ原則が及ぶ。`xcrun simctl delete unavailable` で現行 SDK が対応しないデバイスを消し、個別に消すときは UDID を指定した `xcrun simctl delete <UDID>` を使う。

**ランタイムは `xcrun simctl runtime delete <ID>` で消す。** `/Library/Developer/CoreSimulator/Volumes` 配下は sealed かつ read-only のマウントで、`sudo` を付けても `rm` は通らない。

**ローカルスナップショットは `tmutil deletelocalsnapshots <日付>` で消す。** du に現れないのに空き容量を押し止めるので、削除しても df が増えないときはこれを疑う。

**zsh の glob は1つでもマッチしないとコマンド全体が失敗する。** 中身が隠しディレクトリだけのキャッシュ（Adobe の `typequest` など）で `rm -rf dir/*` が空振りし、同じ行の他の対象まで消し損ねる。キャッシュディレクトリは `dir/*` ではなくディレクトリごと消し、アプリに作り直させる。

**空白を含むパスは必ずクォートする**（`iOS DeviceSupport`、`Media Cache Files` など）。未クォートだと単語分割され、存在しないパスへの `rm -rf` は終了コード0を返すため、消せていないのに成功に見える。

`~/.claude/shell-snapshots` は実行中のセッション自身が毎コマンド source している。最新のファイルを残し、古いものだけ消す。

Homebrew は `brew cleanup --prune=all` を使う。

削除のたびに `du -sk` で結果を確認しながら進める。

完了条件: 承認された枠のすべての対象について、削除の実行と `du -sk` による再計測が済み、消せなかったものは理由が分かっている。

## 6. 報告する

- `df` の前後差分による**実解放量**、および空き容量と使用率の変化
- アプリ別の内訳（du 推定と実解放が乖離した場合はその理由）
- スキップした対象と理由（権限、実行中のプロセス）
- 削除しなかった【要確認】の一覧と、次の判断を仰ぐ質問

有意なキャッシュが無ければ、一行で完了を報告する。
