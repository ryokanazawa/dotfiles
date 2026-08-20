#!/usr/bin/env bash
set -uo pipefail
ROOT=/Users/ryo/Developer/Karuta
OUT="$HOME/Desktop/Karuta-Export"
EXPECTED_BUNDLE_ID=jp.co.rigato.karuta
EXPECTED_TEAM=5SF8ZY3PT8
NEW="$OUT/書き出し/Karuta.app"
OLD="$OUT/旧版/Karuta.app"
test -d "$NEW" || { echo "書き出しが無い"; exit 1; }
test -s "$OUT/status1.txt" || { echo "手順1の status1.txt が無い/空: $OUT"; exit 1; }
test -s "$OUT/head1.txt" || { echo "手順1の head1.txt が無い/空: $OUT"; exit 1; }
test -s "$OUT/signature2.txt" || { echo "手順2の signature2.txt が無い/空: $OUT"; exit 1; }
[ -e "$OLD" ] && { echo "旧版が既にある。手順1からやり直す: $OUT"; exit 1; }

# 全角記号に隣接する変数展開は bash 3.2 が変数名を誤読するため ${} を使う。
fail() {
  if [ -d "$OLD" ]; then
    echo "${1}（旧版: ${OLD}）"
  else
    echo "${1}（旧版なし・新規インストール。書き出し先: ${OUT}）"
  fi
  exit 1
}

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

# 終了は quit → TERM → KILL の順に上げ、各段階で最大12秒待つ（TERM は数秒かかることがある）。
# KILL は最終手段だが、置換前に確実に止めるため省略しない。
osascript -e 'tell application id "jp.co.rigato.karuta" to quit' >/dev/null 2>&1 || true
if ! wait_gone; then
  signal_all TERM || exit 1
  if ! wait_gone; then
    signal_all KILL || exit 1
    wait_gone || { echo "終了できない: $(pgrep -x Karuta)"; exit 1; }
  fi
fi
echo "プロセス終了確認"

if [ -d /Applications/Karuta.app ]; then
  mkdir -p "$OUT/旧版"
  mv /Applications/Karuta.app "$OLD" || exit 1
fi
# 自動復元は ditto による配置失敗のときだけ。それ以降の失敗は旧版を $OLD に残して停止し、復元は手動。
if ! ditto "$NEW" /Applications/Karuta.app; then
  rm -rf /Applications/Karuta.app
  [ -d "$OLD" ] && mv "$OLD" /Applications/Karuta.app
  echo "配置失敗・旧版を復元した"; exit 1
fi

# iCloud 属性の付与と xattr の注意は 2-verify.sh と同じ（xattr -cr で一括消去）。
xattr -cr /Applications/Karuta.app 2>/dev/null || true
codesign --verify --deep --strict --verbose=2 /Applications/Karuta.app 2>&1 \
  || fail "インストール版の署名検証に失敗"
codesign -d --verbose=2 /Applications/Karuta.app 2>&1 \
  | grep -E '^(Identifier|Authority|TeamIdentifier)=' \
  | tee "$OUT/signature3.txt" \
  || fail "インストール版の署名情報を取得できない"
grep -Fxq "Identifier=$EXPECTED_BUNDLE_ID" "$OUT/signature3.txt" \
  || fail "インストール版の Bundle ID が違う"
grep -Eq '^Authority=Apple Development:' "$OUT/signature3.txt" \
  || fail "インストール版が Apple Development 署名でない"
grep -Fxq "TeamIdentifier=$EXPECTED_TEAM" "$OUT/signature3.txt" \
  || fail "インストール版の Team ID が違う"
diff -q "$OUT/signature2.txt" "$OUT/signature3.txt" >/dev/null \
  || fail "書き出し版とインストール版の署名情報が違う"
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister \
  -f /Applications/Karuta.app \
  || fail "Launch Services への登録に失敗"
open /Applications/Karuta.app || fail "open に失敗"

n=0
until pgrep -x Karuta >/dev/null; do
  n=$((n + 1)); [ "$n" -ge 24 ] && fail "起動しない"
  sleep 0.5
done
pid=$(pgrep -x Karuta | head -1)
[ -n "$pid" ] || fail "起動直後に終了"
echo "起動 pid=$pid ($(ps -p "$pid" -o comm=))"
ps -p "$pid" -o comm= | grep -q '/Applications/Karuta\.app/Contents/MacOS/Karuta$' \
  || fail "起動したのが /Applications 版でない"

sum_new=$(shasum -a 256 "$NEW/Contents/MacOS/Karuta" | cut -d' ' -f1) \
  || fail "書き出し版の SHA-256 計算に失敗"
sum_installed=$(shasum -a 256 /Applications/Karuta.app/Contents/MacOS/Karuta | cut -d' ' -f1) \
  || fail "インストール版の SHA-256 計算に失敗"
[ -n "$sum_new" ] || fail "書き出し版の SHA-256 が空"
[ -n "$sum_installed" ] || fail "インストール版の SHA-256 が空"
echo "sha256=$sum_new"
[ "$sum_new" = "$sum_installed" ] || fail "SHA-256 不一致 $sum_new / $sum_installed"

git -C "$ROOT" status -sb | tee "$OUT/status3.txt" \
  || fail "最終 git status の取得に失敗"
git -C "$ROOT" rev-parse HEAD | tee "$OUT/head3.txt" \
  || fail "最終 HEAD の取得に失敗"
diff -q "$OUT/status1.txt" "$OUT/status3.txt" >/dev/null \
  || fail "git status が手順1と違う"
diff -q "$OUT/head1.txt" "$OUT/head3.txt" >/dev/null \
  || fail "HEAD が手順1と違う"

if [ -d "$OLD" ]; then
  echo "旧版の保持先: ${OLD}（次の手順1実行時に自動削除される）"
fi
echo "書き出し先: $NEW"
echo "完了"
