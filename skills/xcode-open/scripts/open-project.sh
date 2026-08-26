#!/bin/bash
# open-project.sh — 今いる git worktree の Xcode プロジェクトを Xcode.app で開く。
#
# 失敗時の対処:
#   .xcworkspace / .xcodeproj がない → ルート直下しか見ない。サブディレクトリ構成なら
#                                      パスを直接 open -a Xcode する（他 worktree 誤爆防止のため深掘りしない）
#   xcode-select が CommandLineTools → 選択中 Xcode を特定できないので既定の Xcode.app へ倒す
#   Xcode が既に別 worktree の同名プロジェクトを開いている
#                                    → 見分けがつかないので、出力の worktree/branch を必ず読む

set -uo pipefail

ROOT=$(git rev-parse --show-toplevel) || exit 1

# --- コンテナ: workspace > xcodeproj > Package.swift、ルート直下のみ ---
# 深掘りすると Foo.xcodeproj/project.xcworkspace や .claude/worktrees/*/Foo.xcodeproj を
# 拾ってしまい、意図しない worktree を開く。depth 1 に固定しておけば両方とも起きない。
CONTAINER=$(find "$ROOT" -maxdepth 1 -name "*.xcworkspace" | head -1)
[ -z "$CONTAINER" ] && CONTAINER=$(find "$ROOT" -maxdepth 1 -name "*.xcodeproj" | head -1)
[ -z "$CONTAINER" ] && [ -f "$ROOT/Package.swift" ] && CONTAINER="$ROOT/Package.swift"
[ -z "$CONTAINER" ] && { echo "error: ルート直下に .xcworkspace / .xcodeproj / Package.swift がない ($ROOT)" >&2; exit 1; }

# --- 開く Xcode: xcode-select の選択を尊重する（beta 併用や複数バージョン対策）---
# 継承した DEVELOPER_DIR をそのまま返してくるので、汚染値を持ち込まないよう外して聞く。
DEVDIR=$(env -u DEVELOPER_DIR xcode-select -p 2>/dev/null)
case "$DEVDIR" in
  */Contents/Developer) APP=("-a" "${DEVDIR%/Contents/Developer}") ;;
  *)                    APP=("-a" "Xcode") ;;   # CommandLineTools 選択中など
esac

open "${APP[@]}" "$CONTAINER" || exit 1

# detached HEAD では --show-current が「空文字 + exit 0」なので、|| では拾えない
BRANCH=$(git branch --show-current)
echo "worktree: $ROOT"
echo "branch:   ${BRANCH:-(detached HEAD)}"
echo "opened:   $CONTAINER"
echo "xcode:    ${APP[1]}"
