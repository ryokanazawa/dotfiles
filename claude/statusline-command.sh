#!/bin/sh
# ~/.claude/statusline-command.sh
# Claude Code statusLine コマンド
# モデル名 | Usage | git ブランチ名 [↑N] を表示する

input=$(cat)

# カレントディレクトリ (JSON 入力から取得。git コマンドはここを対象にする)
cwd=$(echo "$input" | jq -r '.cwd // empty')

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

# git ブランチ名 (git リポジトリでない場合は空)
if [ -n "$cwd" ]; then
  branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
else
  branch=""
fi

# upstream より ahead なコミット数 (upstream 未設定の場合は空)
ahead=""
if [ -n "$branch" ]; then
  ahead_count=$(git -C "$cwd" rev-list --count @{upstream}..HEAD 2>/dev/null)
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

printf '%s | %s%s' "$model" "$usage" "$git_part"
