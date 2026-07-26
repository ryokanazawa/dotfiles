#!/usr/bin/env bash
# project_label / title_with_project_label の interface テスト。
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
# shellcheck source=project-label.sh
. "$ROOT/shell/project-label.sh"

fail=0
assert_eq() {
  local got="$1" want="$2" label="$3"
  if [ "$got" != "$want" ]; then
    printf 'FAIL %s: got %q want %q\n' "$label" "$got" "$want" >&2
    fail=1
  fi
}

tmpdir="$(mktemp -d "${TMPDIR:-/tmp}/project-label-test.XXXXXX")"
trap 'rm -rf "$tmpdir"' EXIT

# 非 git: cwd のベース名
assert_eq "$(project_label "$tmpdir/myproj")" "myproj" "non-git basename"
mkdir -p "$tmpdir/myproj"
assert_eq "$(project_label "$tmpdir/myproj")" "myproj" "non-git existing dir"

# git: トップレベル名（深いサブディレクトリからでも）
gitrepo="$tmpdir/Brushpass"
mkdir -p "$gitrepo/src/app"
git -C "$gitrepo" init -q
assert_eq "$(project_label "$gitrepo")" "Brushpass" "git toplevel"
assert_eq "$(project_label "$gitrepo/src/app")" "Brushpass" "git nested cwd"

# 末尾スラッシュ
assert_eq "$(project_label "$tmpdir/myproj/")" "myproj" "trailing slash"
assert_eq "$(project_label "/")" "/" "filesystem root"

# title_with_project_label
assert_eq "$(title_with_project_label "hello world" "Brushpass")" "hello world · Brushpass" "join"
assert_eq "$(title_with_project_label "hello world" "")" "hello world" "join empty label"

# 空 cwd は空（session-title で .cwd 欠落時に PWD へ落ちない）
assert_eq "$(project_label "")" "" "empty cwd arg"

# 引数省略は PWD
assert_eq "$(cd "$tmpdir/myproj" && project_label)" "myproj" "omitted cwd uses PWD"

if [ "$fail" -ne 0 ]; then
  echo "project-label tests failed" >&2
  exit 1
fi
echo "project-label tests ok"
