#!/usr/bin/env bash
# where: dotfiles/claude/hooks (linked from ~/.claude/settings.json), UserPromptSubmit hook
# what:  送信した最新プロンプトの先頭を Claude のセッション名にし、同じ内容で
#        Ghostty のタブ名を "<title> · claude" に設定する
# why:   会話一覧（/resume）でもターミナルのタブでも、今どの話をしているか一目で分かるように。
#        cwd は Ghostty の window-subtitle=working-directory で別枠表示されるため含めない。

# 失敗してもプロンプト送信をブロックしないよう、常に exit 0 で抜ける（set -e は使わない）。

input="$(cat)"

# タイトル: プロンプト先頭 TITLE_LEN 文字（コードポイント単位なので日本語も安全）。
# 制御文字（改行・タブ・ESC・BEL・DEL 等）はスペース化して連続スペースを畳み前後を trim する。
# これで terminalSequence の allowlist 違反（制御文字混入による無視）も防ぐ。
TITLE_LEN=40
title="$(printf '%s' "$input" | jq -r --argjson n "$TITLE_LEN" \
  '(.prompt // "") | gsub("[[:cntrl:]]"; " ") | gsub(" +"; " ") | sub("^ +"; "") | sub(" +$"; "") | .[0:$n]' 2>/dev/null)"

# Ghostty のタブ/ウィンドウタイトルを OSC 2 で設定する。
# フックは制御端末を持たない（v2.1.139+）ため /dev/tty へは書けない。代わりに
# terminalSequence フィールドで返し、Claude Code 本体に端末へ送ってもらう（v2.1.141+）。
# 許可シーケンスは OSC 0/1/2/9/99/777 と BEL のみ。ここは OSC 2 + BEL 終端。
# cwd は Ghostty の window-subtitle=working-directory で別枠表示するため含めない。
seq="$(printf '\033]2;%s · claude\007' "$title")"

# Claude のセッション名（sessionTitle）とタブ名（terminalSequence）を同時に返す。
jq -n --arg t "$title" --arg seq "$seq" \
  '{hookSpecificOutput: {hookEventName: "UserPromptSubmit", sessionTitle: $t}, terminalSequence: $seq}' 2>/dev/null

exit 0
