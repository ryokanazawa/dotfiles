#!/usr/bin/env bash
# review-since-last — 公開コマンドの基準点管理を一時Gitリポジトリで検証する自己テスト。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REVIEW_RANGE="${SCRIPT_DIR}/review_range.sh"
TEMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/review-since-last-test.XXXXXX")"
trap 'rm -rf "${TEMP_DIR}"' EXIT

fail() {
  printf '失敗: %s\n' "$1" >&2
  exit 1
}

git -C "${TEMP_DIR}" init -q
git -C "${TEMP_DIR}" config user.name "テスト"
git -C "${TEMP_DIR}" config user.email "test@example.com"
printf '最初\n' > "${TEMP_DIR}/sample.txt"
git -C "${TEMP_DIR}" add sample.txt
git -C "${TEMP_DIR}" commit -qm '最初'

set +e
missing_output="$(${REVIEW_RANGE} inspect --repo "${TEMP_DIR}" 2>&1)"
missing_status=$?
set -e

[[ "${missing_status}" -eq 3 ]] || fail "基準点未設定は終了コード3であること"
[[ "${missing_output}" == *"レビュー基準点が未設定です"* ]] \
  || fail "基準点未設定の解決方法を表示すること"

first_commit="$(git -C "${TEMP_DIR}" rev-parse HEAD)"
"${REVIEW_RANGE}" mark --repo "${TEMP_DIR}" "${first_commit}" >/dev/null

printf '二番目\n' >> "${TEMP_DIR}/sample.txt"
git -C "${TEMP_DIR}" add sample.txt
git -C "${TEMP_DIR}" commit -qm '二番目'
second_commit="$(git -C "${TEMP_DIR}" rev-parse HEAD)"

printf '三番目\n' >> "${TEMP_DIR}/sample.txt"
git -C "${TEMP_DIR}" add sample.txt
git -C "${TEMP_DIR}" commit -qm '三番目'
third_commit="$(git -C "${TEMP_DIR}" rev-parse HEAD)"

inspect_output="$("${REVIEW_RANGE}" inspect --repo "${TEMP_DIR}")"
[[ "${inspect_output}" == *"BASE=${first_commit}"* ]] || fail "保存した基準点を表示すること"
[[ "${inspect_output}" == *"HEAD=${third_commit}"* ]] || fail "現在のHEADを表示すること"
[[ "${inspect_output}" == *"RANGE=${first_commit}..${third_commit}"* ]] \
  || fail "結合差分に使う範囲を表示すること"
[[ "${inspect_output}" == *"COUNT=2"* ]] || fail "未レビューcommit数を表示すること"
commit_lines="$(printf '%s\n' "${inspect_output}" | sed -n 's/^COMMIT=//p')"
expected_lines="$(printf '%s\n%s\n' "${second_commit}" "${third_commit}")"
[[ "${commit_lines}" == "${expected_lines}" ]] || fail "commitを古い順に列挙すること"

set +e
"${REVIEW_RANGE}" mark --repo "${TEMP_DIR}" 存在しないcommit >/dev/null 2>&1
invalid_mark_status=$?
set -e
[[ "${invalid_mark_status}" -eq 2 ]] || fail "無効なcommitを拒否すること"
saved_after_failure="$(git -C "${TEMP_DIR}" rev-parse refs/review-since-last/last-reviewed)"
[[ "${saved_after_failure}" == "${first_commit}" ]] || fail "mark失敗時は基準点を動かさないこと"

"${REVIEW_RANGE}" mark --repo "${TEMP_DIR}" "${third_commit}" >/dev/null
reviewed_output="$("${REVIEW_RANGE}" inspect --repo "${TEMP_DIR}")"
[[ "${reviewed_output}" == *"COUNT=0"* ]] || fail "HEADまでレビュー済みなら0件を返すこと"

printf 'review_range self-test passed.\n'
