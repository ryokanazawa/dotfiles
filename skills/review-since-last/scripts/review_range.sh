#!/usr/bin/env bash
# review-since-last — ローカルGit参照でレビュー済み基準点と未レビュー範囲を管理する。

set -euo pipefail

readonly REVIEW_REF="refs/review-since-last/last-reviewed"

command_name="${1:-}"
[[ -n "${command_name}" ]] || {
  printf '使い方: %s <inspect|mark> [--repo PATH] [COMMIT]\n' "$(basename "$0")" >&2
  exit 2
}
shift

repo="."
if [[ "${1:-}" == "--repo" ]]; then
  [[ -n "${2:-}" ]] || {
    printf '%s\n' '--repoにはパスが必要です。' >&2
    exit 2
  }
  repo="$2"
  shift 2
fi

git -C "${repo}" rev-parse --git-dir >/dev/null 2>&1 || {
  printf 'Gitリポジトリではありません: %s\n' "${repo}" >&2
  exit 2
}

case "${command_name}" in
  inspect)
    git -C "${repo}" show-ref --verify --quiet "${REVIEW_REF}" || {
      printf 'レビュー基準点が未設定です。開始commitを確認して mark <commit> を実行してください。\n' >&2
      exit 3
    }
    base="$(git -C "${repo}" rev-parse "${REVIEW_REF}^{commit}")"
    head="$(git -C "${repo}" rev-parse 'HEAD^{commit}')"
    count="$(git -C "${repo}" rev-list --count "${base}..${head}")"
    printf 'BASE=%s\nHEAD=%s\nRANGE=%s..%s\nCOUNT=%s\n' \
      "${base}" "${head}" "${base}" "${head}" "${count}"
    git -C "${repo}" rev-list --reverse "${base}..${head}" | while IFS= read -r commit; do
      printf 'COMMIT=%s\n' "${commit}"
    done
    ;;
  mark)
    commit="${1:-}"
    [[ -n "${commit}" ]] || {
      printf 'markにはレビュー済みcommitが必要です。\n' >&2
      exit 2
    }
    resolved_commit="$(git -C "${repo}" rev-parse --verify "${commit}^{commit}" 2>/dev/null)" || {
      printf 'commitを解決できません: %s\n' "${commit}" >&2
      exit 2
    }
    git -C "${repo}" merge-base --is-ancestor "${resolved_commit}" HEAD || {
      printf 'HEADの祖先ではないcommitは基準点にできません: %s\n' "${commit}" >&2
      exit 2
    }
    git -C "${repo}" update-ref "${REVIEW_REF}" "${resolved_commit}"
    printf 'レビュー基準点を更新しました: %s\n' "${resolved_commit}"
    ;;
  *)
    printf '不明な操作です: %s\n' "${command_name}" >&2
    exit 2
    ;;
esac
