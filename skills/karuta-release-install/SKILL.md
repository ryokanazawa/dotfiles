---
name: karuta-release-install
description: Karuta の現在 HEAD を Release でアーカイブし、署名を検証して /Applications/Karuta.app を置き換え、起動する。
disable-model-invocation: true
---

# Karuta を書き出してインストールする

`/Users/ryo/Developer/Karuta` の現在の `HEAD` を Release でアーカイブし、署名を検証して `/Applications/Karuta.app` に置き換え、起動する。ソース・Git 履歴・作業ツリーは変更しない。

スクリプトはこのスキルのベースディレクトリ直下の `scripts/` にある。`bash` で絶対パス実行し、3 本を順に実行して、途中で完了条件を落としたらそこで止める。advisor は呼ばない。スクリプトの終了コードと出力で判断は足りる。書き出し先は `~/Desktop/Karuta-Export`（`$OUT`）に固定で、成功時も失敗時も消さない。旧版は `$OUT/旧版/Karuta.app` に保持され、次回の手順1で確認なしに自動削除される。同時に2つ走らせない。

## 手順1: アーカイブ

`scripts/1-archive.sh` を権限付き実行・バックグラウンドで実行し、完了通知を待って出力を読む（数分かかる）。

完了条件: 作業ツリーが clean、`build_exit=0`、`** ARCHIVE SUCCEEDED **`、`$OUT/書き出し/Karuta.app` の `ls` が出る。

署名 identity は `security find-identity` の実測値で報告する。`warning_count` は成功結果とは別に報告する。

## 手順2: 検証

`scripts/2-verify.sh` を通常実行する。

完了条件: 終了コード 0 と `検証終了`、`valid on disk`、`satisfies its Designated Requirement`、`Identifier=jp.co.rigato.karuta`、`Authority=Apple Development: ...`、`TeamIdentifier=5SF8ZY3PT8`、`archs` に `x86_64` と `arm64` の両方。

手順1 は既定でユニバーサル (`arm64 x86_64`) を作る。それでも `arm64` だけなら完了条件未達。同じ手順を繰り返しても変わらないので、取り繕わずそこで報告して止める。

`ARCHS_OVERRIDE` は意図して別の arch 構成を作りたいときだけ手順1へ渡す（例: `ARCHS_OVERRIDE=arm64`）。`2-verify.sh` の archs 判定は両 arch 固定なのでその場合は終了コード 1 で止まる。想定どおりであることを報告し、手順3 へ進めてよいかをユーザーに確認する。

## 手順3: 置換と起動

`scripts/3-install.sh` を権限付き実行する。終了・退避・配置・再検証・起動・確認を 1 本で行う。

完了条件: `完了` が出る。起動 PID の実行ファイルが `/Applications/Karuta.app/Contents/MacOS/Karuta`、インストール版が書き出し版と同じ Bundle ID・Apple Development Authority・Team ID で署名検証成功、両バイナリの SHA-256 が一致、`HEAD` と `git status -sb` が手順1と同じ。

自動復元は `ditto` による配置失敗のときだけ。それ以降の失敗は旧版を `$OUT/旧版/Karuta.app` に残して停止し、復元は手動（`fail` がパスを出す。新規インストールで旧版が無い場合は「旧版なし」）。`/Applications` 版以外（DerivedData の Debug ビルドなど）を終了させた場合は、開発中インスタンスを落としたことを報告に明記する。

## 境界

- `Apple Development` 署名はローカル実機確認用。Developer ID 署名・公証・配布・Gatekeeper 確認は別依頼。
- 作業ツリーが clean でない場合は手順1で停止する。未コミット変更のインストールは別依頼。
- 失敗したあと手順3 だけを再実行しない。スクリプトが `旧版が既にある` で止まるので、やり直すなら手順1 から。
