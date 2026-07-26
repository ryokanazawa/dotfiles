#!/usr/bin/env bash
# where: dotfiles/claude/hooks (linked from ~/.claude/settings.json), UserPromptSubmit hook
# what:  送信した最新プロンプトの先頭にプロジェクト名を添えて、Claude のセッション名を
#        "<title> · <project>"、Ghostty のタブ名を "<title> · <project> · claude" に設定する。
# why:   会話一覧（/resume）でもターミナルのタブでも、何の話をどのプロジェクトでしているか
#        一目で分かるように。プロジェクト名は shell/project-label.sh の project_label。

# 失敗してもプロンプト送信をブロックしないよう、常に exit 0 で抜ける（set -e は使わない）。

_lib="${HOME}/.shell/project-label.sh"
[ -f "$_lib" ] || _lib="${HOME}/Developer/dotfiles/shell/project-label.sh"
# shellcheck source=/dev/null
. "$_lib"
unset _lib

input="$(cat)"

# 整形: 制御文字（改行・タブ・ESC・BEL・DEL 等）をスペース化し連続スペースを畳んで前後を trim。
# これで terminalSequence の allowlist 違反（制御文字混入による無視）も防ぐ。
clean="$(printf '%s' "$input" | jq -r \
  '(.prompt // "") | gsub("[[:cntrl:]]"; " ") | gsub(" +"; " ") | sub("^ +"; "") | sub(" +$"; "")' 2>/dev/null)"

# 短い指示（「続けて」「commit」など）はタイトルを上書きしない＝直前の長いタイトルを残す。
# trim 後のコードポイント数が MIN_LEN 未満なら、何も返さず exit 0（タイトル据え置き）。
MIN_LEN=10
clean_len="$(printf '%s' "$clean" | jq -sR 'length' 2>/dev/null)"
[ -n "$clean_len" ] && [ "$clean_len" -lt "$MIN_LEN" ] 2>/dev/null && exit 0

# タイトル: 先頭 TITLE_LEN 文字（コードポイント単位なので日本語も安全）。
TITLE_LEN=40
title="$(printf '%s' "$clean" | jq -sRr --argjson n "$TITLE_LEN" '.[0:$n]' 2>/dev/null)"

cwd="$(printf '%s' "$input" | jq -r '.cwd // ""' 2>/dev/null)"
session_title="$(titled_with_project "$title" "$(project_label "$cwd")")"

# Ghostty のタブ/ウィンドウタイトルを OSC 2 で設定する。
# フックは制御端末を持たない（v2.1.139+）ため /dev/tty へは書けない。代わりに
# terminalSequence フィールドで返し、Claude Code 本体に端末へ送ってもらう（v2.1.141+）。
# 許可シーケンスは OSC 0/1/2/9/99/777 と BEL のみ。ここは OSC 2 + BEL 終端。
# タブ名は "<title> · <project> · claude"。
seq="$(printf '\033]2;%s · claude\007' "$session_title")"

# Claude のセッション名（sessionTitle）とタブ名（terminalSequence）を同時に返す。
jq -n --arg t "$session_title" --arg seq "$seq" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}, terminalSequence: $seq}' 2>/dev/null

exit 0
