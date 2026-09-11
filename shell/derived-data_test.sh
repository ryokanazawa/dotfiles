#!/usr/bin/env bash
# derived_data_orphans / derived_data_workspace_dir の interface テスト。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=derived-data.sh
. "$ROOT/shell/derived-data.sh"

fail=0
assert_eq() {
  local got="$1" want="$2" label="$3"
  if [ "$got" != "$want" ]; then
    printf 'FAIL %s: got %q want %q\n' "$label" "$got" "$want" >&2
    fail=1
  fi
}

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/derived-data-test.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

# DerivedData の1エントリを作る。workspace は .xcodeproj までのフルパス。
make_entry() {
  local name="$1" workspace="$2"
  mkdir -p "$tmpdir/dd/$name"
  plutil -create xml1 "$tmpdir/dd/$name/info.plist"
  plutil -insert WorkspacePath -string "$workspace" "$tmpdir/dd/$name/info.plist"
}

# 生きている worktree
mkdir -p "$tmpdir/live/Giga2.xcodeproj"
make_entry "Giga2-live" "$tmpdir/live/Giga2.xcodeproj"

# 消えた worktree（孤児）
make_entry "Giga2-orphan" "$tmpdir/gone/Giga2.xcodeproj"

# 親は在るがプロジェクトファイルだけ無い → 孤児ではない（生成物・gitignore 対策）
mkdir -p "$tmpdir/generated"
make_entry "Giga2-generated" "$tmpdir/generated/Giga2.xcodeproj"

# info.plist なし = 共有キャッシュ。対象外。
mkdir -p "$tmpdir/dd/ModuleCache.noindex"

assert_eq "$(derived_data_orphans "$tmpdir/dd")" "$tmpdir/dd/Giga2-orphan" "孤児だけを返す"

assert_eq "$(derived_data_workspace_dir "$tmpdir/dd/Giga2-live")" "$tmpdir/live" "workspace の親を返す"
assert_eq "$(derived_data_workspace_dir "$tmpdir/dd/ModuleCache.noindex" || echo "")" "" "info.plist なしは失敗"
assert_eq "$(derived_data_workspace_dir "" || echo "")" "" "空引数は失敗"

# 存在しない root は空（エラーにしない）
assert_eq "$(derived_data_orphans "$tmpdir/nope")" "" "root なしは空"

# 空の root も空
mkdir -p "$tmpdir/empty"
assert_eq "$(derived_data_orphans "$tmpdir/empty")" "" "空 root は空"

if [ "$fail" -ne 0 ]; then
  echo "derived-data tests failed" >&2
  exit 1
fi
echo "derived-data tests ok"
