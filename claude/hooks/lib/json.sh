# Claude hook stdin JSON harness。
# Interface:
#   hook_jq <json> <expr>   → jq -r。失敗時は空（フックを落とさない）
# POSIX sh 対応（statusline が #!/bin/sh）。

hook_jq() {
  printf '%s' "$1" | jq -r "$2" 2>/dev/null || true
}
