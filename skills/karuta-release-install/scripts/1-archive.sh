#!/usr/bin/env bash
set -uo pipefail
ROOT=/Users/ryo/Developer/Karuta
# ~/Desktop は iCloud の file provider ドメイン配下で、バンドル直下に
# com.apple.FinderInfo が数秒で再付与され codesign --strict が弾く。
# xattr -c しても勝てない。OS の一時領域 (/var/folders/.../T) は file provider
# ドメインではないのでこの問題が起きず、作業ツリーやデスクトップも汚さない。
# TMPDIR は末尾スラッシュ付きなので剥がしてから連結する。
OUT="${TMPDIR:-/tmp}"
OUT="${OUT%/}/Karuta-Export"
if [ -d "$OUT/旧版" ]; then
  echo "前回の旧版を削除する: $OUT/旧版/Karuta.app"
fi
rm -rf "$OUT" || { echo "書き出し先を消せない: $OUT"; exit 1; }
mkdir -p "$OUT" || { echo "書き出し先を作れない: $OUT"; exit 1; }
echo "OUT=$OUT"
git -C "$ROOT" status -sb | tee "$OUT/status1.txt" || exit 1
git -C "$ROOT" rev-parse HEAD | tee "$OUT/head1.txt" || exit 1
git -C "$ROOT" status --porcelain=v1 --untracked-files=all > "$OUT/worktree1.txt" || exit 1
if [ -s "$OUT/worktree1.txt" ]; then
  echo "作業ツリーが clean でないため、現在の HEAD と同一の成果物を保証できない"
  cat "$OUT/worktree1.txt"
  exit 1
fi
git -C "$ROOT" log -1 --oneline --decorate
security find-identity -v -p codesigning
# 手順2 の完了条件が arm64 + x86_64 の両方なので、既定でユニバーサルを作る。
# destination で arch を絞ると ARCHS がその 1 つになり、手順2 が必ず落ちて
# 数分のアーカイブをやり直すことになる。別の組み合わせは ARCHS_OVERRIDE で指定する。
dest=(-destination 'platform=macOS' "ARCHS=${ARCHS_OVERRIDE:-arm64 x86_64}")
xcodebuild -project "$ROOT/Karuta.xcodeproj" -scheme Karuta -configuration Release \
  "${dest[@]}" \
  -archivePath "$OUT/Karuta.xcarchive" archive >"$OUT/archive.log" 2>&1
build_exit=$?
echo "build_exit=$build_exit"
# 素の 'error:' は Swift シグネチャ (value: T?, error: AXError) に誤ヒットするため ': error:' で絞る。
# xcodebuild の実エラーは「ファイル:行:桁: error:」形式なので取りこぼさない。
grep -E '\*\* ARCHIVE (SUCCEEDED|FAILED) \*\*|: error:' "$OUT/archive.log" | tail -40
printf 'warning_count='; grep -c 'warning:' "$OUT/archive.log" || true
test "$build_exit" -eq 0 || exit 1
mkdir -p "$OUT/書き出し"
ditto "$OUT/Karuta.xcarchive/Products/Applications/Karuta.app" "$OUT/書き出し/Karuta.app"
ls -d "$OUT/書き出し/Karuta.app"
