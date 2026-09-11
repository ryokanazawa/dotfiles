#!/usr/bin/env bash
# 孤児 DerivedData を消す薄い adapter。判定は derived-data.sh に任せる。
#
#   prune-derived-data.sh              孤児を一覧するだけ（既定）
#   prune-derived-data.sh --delete     実際に消す
#   prune-derived-data.sh --allow-xcode-running
#
# worktree を消しても DerivedData は残るため、Xcode プロジェクトを worktree で
# 運用していると際限なく溜まる（Giga2 で 26 個・約 50 GiB に分裂した実績あり）。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=derived-data.sh
. "$ROOT/derived-data.sh"

delete=0
allow_xcode=0
for arg in "$@"; do
  case "$arg" in
    --delete) delete=1 ;;
    --dry-run) delete=0 ;;
    --allow-xcode-running) allow_xcode=1 ;;
    *) echo "不明な引数: $arg" >&2; exit 2 ;;
  esac
done

# 起動中の Xcode はビルド中に DerivedData を作り直す。判定と削除の間で状態がずれる。
if [ "$delete" -eq 1 ] && [ "$allow_xcode" -eq 0 ] && pgrep -x Xcode >/dev/null 2>&1; then
  echo "Xcode が起動中。終了してから実行するか --allow-xcode-running を付ける。" >&2
  exit 1
fi

orphans="$(derived_data_orphans)"
if [ -z "$orphans" ]; then
  echo "孤児 DerivedData なし。"
  exit 0
fi

# lsof は重い。DerivedData 配下を1回だけ読んで使用中の名前を集める。
in_use="$(lsof 2>/dev/null | grep -o 'DerivedData/[^/]*' | sort -u || true)"

free_kb() { df -k /System/Volumes/Data | tail -1 | awk '{print $4}'; }

before="$(free_kb)"
count=0
skipped=0

while IFS= read -r dir; do
  [ -n "$dir" ] || continue
  name="${dir##*/}"
  size="$(du -sk "$dir" 2>/dev/null | awk '{printf "%.2f", $1/1048576}')"

  if printf '%s\n' "$in_use" | grep -qxF "DerivedData/$name"; then
    echo "スキップ (使用中) ${size} GiB  $name"
    skipped=$((skipped + 1))
    continue
  fi

  if [ "$delete" -eq 1 ]; then
    rm -rf "$dir"
    echo "削除 ${size} GiB  $name"
  else
    echo "孤児 ${size} GiB  $name  → $(derived_data_workspace_dir "$dir" 2>/dev/null || echo '?')"
  fi
  count=$((count + 1))
done <<EOF
$orphans
EOF

if [ "$delete" -eq 1 ]; then
  after="$(free_kb)"
  # 実解放量は df の前後差分でのみ確定する。du は APFS のクローンで過大に出る。
  awk -v b="$before" -v a="$after" -v n="$count" -v s="$skipped" \
    'BEGIN { printf "%d 件削除（スキップ %d 件）。実解放量 %.2f GiB\n", n, s, (a-b)/1048576 }'
else
  echo "--- $count 件が孤児（スキップ $skipped 件）。消すには --delete を付ける。"
fi
