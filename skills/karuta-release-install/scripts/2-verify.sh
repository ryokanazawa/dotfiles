#!/usr/bin/env bash
set -uo pipefail
OUT="${TMPDIR:-/tmp}"
OUT="${OUT%/}/Karuta-Export"
APP="$OUT/書き出し/Karuta.app"
EXPECTED_BUNDLE_ID=jp.co.rigato.karuta
EXPECTED_TEAM=5SF8ZY3PT8
test -d "$APP" || { echo "書き出しが無い: $APP"; exit 1; }

# codesign は結果を stderr に出すので 2>&1 が必須。
codesign --verify --deep --strict --verbose=2 "$APP" 2>&1 \
  || { echo "書き出し版の署名検証に失敗"; exit 1; }
codesign -d --verbose=2 "$APP" 2>&1 \
  | grep -E '^(Identifier|Authority|TeamIdentifier)=' \
  | tee "$OUT/signature2.txt" \
  || { echo "書き出し版の署名情報を取得できない"; exit 1; }
grep -Fxq "Identifier=$EXPECTED_BUNDLE_ID" "$OUT/signature2.txt" \
  || { echo "Bundle ID が違う"; exit 1; }
grep -Eq '^Authority=Apple Development:' "$OUT/signature2.txt" \
  || { echo "Apple Development 署名でない"; exit 1; }
grep -Fxq "TeamIdentifier=$EXPECTED_TEAM" "$OUT/signature2.txt" \
  || { echo "Team ID が違う"; exit 1; }

archs=$(lipo -archs "$APP/Contents/MacOS/Karuta") \
  || { echo "アーキテクチャを取得できない"; exit 1; }
echo "archs=$archs"
case " $archs " in *' arm64 '*) ;; *) echo "arm64 が無い"; exit 1;; esac
case " $archs " in *' x86_64 '*) ;; *) echo "x86_64 が無い"; exit 1;; esac
ls -ld /Applications/Karuta.app 2>&1 || true
# 手順3 で終了させる対象の下見。/Applications 版が動いていなくても、
# DerivedData の Debug ビルドが同じ Bundle ID で動いていることがある。
pgrep -x Karuta | while read -r p; do echo "running pid=$p $(ps -p "$p" -o comm=)"; done
echo "検証終了"
