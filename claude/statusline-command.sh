#!/bin/sh
# ~/.claude/statusline-command.sh
# Claude Code statusLine コマンド
# [ホスト名 ユーザー名: パス] モデル名 | Usage | git ブランチ名 [↑N] を表示する
# 先頭の [ホスト名 ユーザー名: パス] (緑色) は旧シェル PS1 由来のプレフィックス

input=$(cat)

# カレントディレクトリ (JSON 入力から取得。git コマンドはここを対象にする)
cwd=$(echo "$input" | jq -r '.cwd // empty')

# --- PS1 由来のプレフィックス [ホスト名 ユーザー名: パス] (緑色) ---
green='\033[32m'
reset='\033[0m'
host_short=$(hostname -s 2>/dev/null)
user_name=$(whoami 2>/dev/null)
# ホームディレクトリを ~ に短縮表示
display_path=$(printf '%s' "$cwd" | sed "s|^$HOME|~|")
prefix=$(printf '%b[%s %s: %s]%b' "$green" "$host_short" "$user_name" "$display_path" "$reset")

# モデル表示名 (例: "Claude Sonnet 4.6")
model=$(echo "$input" | jq -r '.model.display_name // "Unknown"')

# コンテキスト使用率 (0-100 の数値。メッセージ未送信時は null)
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')

# 累積入力トークン (キャッシュ読み込み分を含む)
total_in=$(echo "$input" | jq -r '.context_window.total_input_tokens // 0')

# Usage 表示を組み立てる
if [ -n "$used_pct" ]; then
  # トークン数を k 単位に変換 (小数1桁)
  tokens_k=$(echo "$total_in" | awk '{printf "%.1fk", $1/1000}')
  usage="${tokens_k} / $(printf '%.0f' "$used_pct")%"
else
  usage="--"
fi

# git ブランチ名 (git リポジトリでない場合は空。--no-optional-locks で index lock を回避)
if [ -n "$cwd" ]; then
  branch=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
else
  branch=""
fi

# upstream より ahead なコミット数 (upstream 未設定の場合は空)
ahead=""
if [ -n "$branch" ]; then
  ahead_count=$(git --no-optional-locks -C "$cwd" rev-list --count @{upstream}..HEAD 2>/dev/null)
  if [ -n "$ahead_count" ] && [ "$ahead_count" -gt 0 ] 2>/dev/null; then
    ahead=" ↑${ahead_count}"
  fi
fi

# git 部分を組み立てる (ブランチが取得できた場合のみ表示)
if [ -n "$branch" ]; then
  git_part=" | ${branch}${ahead}"
else
  git_part=""
fi

printf '%b %s | %s%s' "$prefix" "$model" "$usage" "$git_part"
