# project-label — cwd から端末・セッション用の表示名を導出する deep module。
#
# Interface:
#   project_label [cwd]              → git トップレベル名、なければ cwd のベース名
#   title_with_project_label base label → label があれば "base · label"、なければ base
#
# bash / zsh 両対応。副作用なし（git 呼び出しのみ）。呼び出し側は薄い adapter。

project_label() {
  # 引数あり（空文字含む）はそのまま使う。省略時だけ PWD。空 cwd は空を返す（旧 session-title 互換）。
  local cwd
  if [ "$#" -ge 1 ]; then
    cwd="$1"
  else
    cwd="${PWD:-.}"
  fi
  if [ -z "$cwd" ]; then
    printf '%s\n' ""
    return 0
  fi
  local root=""
  root="$(git -C "$cwd" rev-parse --show-toplevel 2>/dev/null)" || root=""
  if [ -n "$root" ]; then
    printf '%s\n' "${root##*/}"
  else
    cwd="${cwd%/}"
    if [ -n "$cwd" ]; then
      printf '%s\n' "${cwd##*/}"
    else
      printf '%s\n' "/"
    fi
  fi
}

title_with_project_label() {
  local base="$1"
  local label="$2"
  if [ -n "$label" ]; then
    printf '%s · %s\n' "$base" "$label"
  else
    printf '%s\n' "$base"
  fi
}
