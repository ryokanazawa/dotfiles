#!/usr/bin/env bash
# prompt_to_title_part / hook_jq の interface テスト。
set -euo pipefail

LIB="$(cd "$(dirname "$0")" && pwd)"
# shellcheck source=/dev/null
. "$LIB/json.sh"
# shellcheck source=/dev/null
. "$LIB/prompt-title.sh"

fail=0
assert_eq() {
  local got="$1" want="$2" label="$3"
  if [ "$got" != "$want" ]; then
    printf 'FAIL %s: got %q want %q\n' "$label" "$got" "$want" >&2
    fail=1
  fi
}

assert_eq "$(hook_jq '{"cwd":"/tmp/x"}' '.cwd // empty')" "/tmp/x" "hook_jq cwd"
assert_eq "$(hook_jq '{}' '.cwd // empty')" "" "hook_jq missing cwd"

assert_eq "$(prompt_to_title_part "short")" "" "too short"
assert_eq "$(prompt_to_title_part "this is long enough for a title")" "this is long enough for a title" "long enough"

got="$(prompt_to_title_part "$(printf 'hello\tworld and more text here')")"
assert_eq "$got" "hello world and more text here" "control chars"

got="$(prompt_to_title_part "$(printf 'line one\nline two and enough')")"
assert_eq "$got" "line one line two and enough" "multiline newlines collapsed"

long="$(printf 'あ%.0s' {1..50})"
got="$(prompt_to_title_part "$long")"
got_len="$(printf '%s' "$got" | jq -sR 'length')"
assert_eq "$got_len" "40" "truncate to 40 code points"

if [ "$fail" -ne 0 ]; then
  echo "prompt-title tests failed" >&2
  exit 1
fi
echo "prompt-title tests ok"
