#!/usr/bin/env bash
# where: dotfiles/claude/hooks (linked from ~/.claude/settings.json), UserPromptSubmit hook
# what:  送信した最新プロンプトの先頭に project label を添えて、Claude のセッション名を
#        "<title> · <project label>"、Ghostty のタブ名を "<title> · <project label> · claude" に設定する。
# why:   会話一覧（/resume）でもターミナルのタブでも、何の話をどのプロジェクトでしているか
#        一目で分かるように。タイトル断片は lib/prompt-title.sh、project label は project-label。

# 失敗してもプロンプト送信をブロックしないよう、常に exit 0 で抜ける（set -e は使わない）。

_HOOK_LIB="$(cd "$(dirname "$0")" && pwd)/lib"
# shellcheck source=/dev/null
. "$_HOOK_LIB/json.sh"
# shellcheck source=/dev/null
. "$_HOOK_LIB/prompt-title.sh"
unset _HOOK_LIB

_lib="${HOME}/.shell/project-label.sh"
# Link install 未適用の既存環境では、標準 checkout を移行経路として使う。
[ -f "$_lib" ] || _lib="${HOME}/Developer/dotfiles/shell/project-label.sh"
# shellcheck source=/dev/null
. "$_lib"
unset _lib

input="$(cat)"
title="$(prompt_to_title_part "$(hook_jq "$input" '.prompt // ""')")"
[ -n "$title" ] || exit 0

cwd="$(hook_jq "$input" '.cwd // ""')"
session_title="$(title_with_project_label "$title" "$(project_label "$cwd")")"

# Ghostty のタブ/ウィンドウタイトルを OSC 2 で設定する。
# フックは制御端末を持たない（v2.1.139+）ため /dev/tty へは書けない。代わりに
# terminalSequence フィールドで返し、Claude Code 本体に端末へ送ってもらう（v2.1.141+）。
# 許可シーケンスは OSC 0/1/2/9/99/777 と BEL のみ。ここは OSC 2 + BEL 終端。
seq="$(printf '\033]2;%s · claude\007' "$session_title")"

jq -n --arg t "$session_title" --arg seq "$seq" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}, terminalSequence: $seq}' 2>/dev/null

exit 0
