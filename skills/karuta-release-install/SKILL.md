---
name: karuta-release-install
description: Karuta の現在HEADを Release でアーカイブし、署名・アーキテクチャ・ハッシュを検証して /Applications/Karuta.app を置き換え、起動まで行う。Karuta の書き出し、ローカル実機へのインストール、Release ビルドの差し替え、最新版の再インストールを依頼されたときに使う。Developer ID 署名・公証・配布は対象外。
disable-model-invocation: true
---

# Karuta を書き出してインストールする

`/Users/ryo/Developer/Karuta` の現在の `HEAD` を Release でアーカイブし、署名を検証して `/Applications/Karuta.app` に置き換え、起動する。ソース・Git 履歴・作業ツリーは変更しない。

手順は決まりきっている。advisor は呼ばない。各段階の判断はスクリプトの終了コードと出力で足りる。3 本のスクリプトを順に実行し、途中で完了条件を落としたらそこで止める。

`$OUT` はシェルをまたいで残らないため、手順1が退避先を `/private/tmp/Karuta-Export.latest` に書き、手順2・3 がそれを読む。スクリプトを書き換える必要はない。

## 手順1: アーカイブと書き出し

権限付き実行・バックグラウンドで実行し、完了通知を待って出力ファイルを読む（数分かかる）。

```sh
set -uo pipefail
ROOT=/Users/ryo/Developer/Karuta
OUT=$(mktemp -d /private/tmp/Karuta-Export.XXXXXX)
printf '%s\n' "$OUT" > /private/tmp/Karuta-Export.latest
echo "OUT=$OUT"
git -C "$ROOT" status -sb
git -C "$ROOT" log -1 --oneline --decorate
security find-identity -v -p codesigning
xcodebuild -project "$ROOT/Karuta.xcodeproj" -scheme Karuta -configuration Release \
  -destination 'platform=macOS,arch=arm64' \
  -archivePath "$OUT/Karuta.xcarchive" archive >"$OUT/archive.log" 2>&1
build_exit=$?
echo "build_exit=$build_exit"
grep -E '\*\* ARCHIVE (SUCCEEDED|FAILED) \*\*|: error:' "$OUT/archive.log" | tail -40
printf 'warning_count='; grep -c 'warning:' "$OUT/archive.log" || true
test "$build_exit" -eq 0 || exit 1
mkdir -p "$OUT/書き出し"
ditto "$OUT/Karuta.xcarchive/Products/Applications/Karuta.app" "$OUT/書き出し/Karuta.app"
ls -d "$OUT/書き出し/Karuta.app"
```

完了条件: `build_exit=0`、`** ARCHIVE SUCCEEDED **`、`$OUT/書き出し/Karuta.app` の `ls` が出る。

署名 identity は `security find-identity` の実測値で呼ぶ。`Apple Development` を `Developer ID Application` と呼ばない。`warning_count` は成功結果とは別に報告する。`git status -sb` の出力は手順3 の比較用に控える。

`: error:` で絞るのは、Swift の関数シグネチャ（`(value: T?, error: AXError)` など）が素の `error:` に誤ヒットするため。xcodebuild の実エラーは `ファイル:行:桁: error:` 形式なので取りこぼさない。

## 手順2: 検証

通常実行。

```sh
set -uo pipefail
OUT=$(cat /private/tmp/Karuta-Export.latest)
codesign --verify --deep --strict --verbose=2 "$OUT/書き出し/Karuta.app" 2>&1
codesign -d --verbose=2 "$OUT/書き出し/Karuta.app" 2>&1 | grep -E '^(Identifier|Authority|TeamIdentifier)='
lipo -archs "$OUT/書き出し/Karuta.app/Contents/MacOS/Karuta"
ls -ld /Applications/Karuta.app 2>&1 || true
pgrep -x Karuta | while read -r p; do echo "running pid=$p $(ps -p "$p" -o comm=)"; done
echo "検証終了"
```

完了条件: `valid on disk` と `satisfies its Designated Requirement` の両方、`Identifier=jp.co.rigato.karuta`、`x86_64 arm64`。

`codesign` は結果を stderr に出すので `2>&1` を外さない。アーキテクチャが `arm64` だけなら完了条件未達。取り繕わずに報告し、`-destination` の arch 指定を外すか `ARCHS="arm64 x86_64"` で再アーカイブする。

`pgrep` の行は手順3 で終了させる対象の下見。`/Applications` 版が動いていなくても、DerivedData の Debug ビルドが同じ Bundle ID で動いていることがある。

## 手順3: 置換と起動

権限付き実行。終了・退避・配置・再検証・起動・確認を 1 本で行う。失敗時は旧版に戻る。

```sh
set -uo pipefail
ROOT=/Users/ryo/Developer/Karuta
OUT=$(cat /private/tmp/Karuta-Export.latest)
NEW="$OUT/書き出し/Karuta.app"
test -d "$NEW" || { echo "書き出しが無い"; exit 1; }

wait_gone() {
  local n=0
  while pgrep -x Karuta >/dev/null; do
    n=$((n + 1)); [ "$n" -ge 24 ] && return 1
    sleep 0.5
  done
  return 0
}
signal_all() {
  local sig="$1" p
  local pids=($(pgrep -x Karuta))
  for p in "${pids[@]}"; do
    ps -p "$p" -o comm= | grep -q '/Karuta\.app/Contents/MacOS/Karuta$' \
      || { echo "想定外のプロセス pid=$p"; return 1; }
    echo "$sig pid=$p ($(ps -p "$p" -o comm=))"
    kill -"$sig" "$p"
  done
  return 0
}

osascript -e 'tell application id "jp.co.rigato.karuta" to quit' >/dev/null 2>&1 || true
if ! wait_gone; then
  signal_all TERM || exit 1
  if ! wait_gone; then
    signal_all KILL || exit 1
    wait_gone || { echo "終了できない: $(pgrep -x Karuta)"; exit 1; }
  fi
fi
echo "プロセス終了確認"

mkdir -p "$OUT/旧版"
if [ -d /Applications/Karuta.app ]; then
  mv /Applications/Karuta.app "$OUT/旧版/Karuta.app" || exit 1
fi
if ! ditto "$NEW" /Applications/Karuta.app; then
  rm -rf /Applications/Karuta.app
  [ -d "$OUT/旧版/Karuta.app" ] && mv "$OUT/旧版/Karuta.app" /Applications/Karuta.app
  echo "配置失敗・旧版を復元した"; exit 1
fi

codesign --verify --deep --strict --verbose=2 /Applications/Karuta.app 2>&1 || exit 1
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/Karuta.app
open /Applications/Karuta.app || exit 1
for i in 1 2 3 4 5 6 7 8 9 10; do pgrep -x Karuta >/dev/null && break; sleep 0.5; done

pgrep -x Karuta | while read -r p; do echo "起動 pid=$p $(ps -p "$p" -o comm=)"; done
shasum -a 256 "$NEW/Contents/MacOS/Karuta" /Applications/Karuta.app/Contents/MacOS/Karuta
git -C "$ROOT" status -sb
echo "旧版退避先: $OUT/旧版/Karuta.app"
```

完了条件: 起動 PID の実行ファイルが `/Applications/Karuta.app/Contents/MacOS/Karuta`、インストール版も署名検証成功、両バイナリの SHA-256 が一致、`git status -sb` が手順1と同じ。

終了は AppleScript の quit → `TERM` → `KILL` の順に上げ、各段階で最大12秒待つ。TERM に数秒かかることがあるので、待ちを詰めない。`KILL` は最終手段だが省略しない。省略すると置換前に止まり、`/Applications` 版だけ quit された状態が残る。

`/Applications` 版以外（DerivedData の Debug ビルド）を終了させた場合は、ユーザーの開発中インスタンスを落としたことになる。手順から外れた措置として報告に明記する。

## 境界

- `Apple Development` 署名はローカル実機確認用。配布用 Developer ID 署名・公証・公開は別依頼。Gatekeeper や公証の確認は範囲外。
- 旧版退避先は報告に残す。一時ディレクトリごと消さない。
- 署名、終了、置換、起動、ハッシュ確認のどれかが未達なら完了と報告しない。
