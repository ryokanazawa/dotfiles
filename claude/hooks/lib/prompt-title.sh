# UserPromptSubmit 用: 生プロンプト文字列 → セッションタイトル断片。
# Interface:
#   prompt_to_title_part <text>  → 短すぎれば空、それ以外は先頭 PROMPT_TITLE_LEN コードポイント
#
# 制御文字除去・長さ判定はここが正本。session-title.sh は adapter。

PROMPT_TITLE_MIN_LEN=10
PROMPT_TITLE_LEN=40

prompt_to_title_part() {
  local raw="$1"
  local clean clean_len
  # -s で複数行も1文字列化し、改行など制御文字をスペースへ（OSC allowlist 対策）
  clean="$(printf '%s' "$raw" | jq -Rsr \
    'gsub("[[:cntrl:]]"; " ") | gsub(" +"; " ") | sub("^ +"; "") | sub(" +$"; "")' 2>/dev/null)" || clean=""
  clean_len="$(printf '%s' "$clean" | jq -sR 'length' 2>/dev/null)" || clean_len=0
  if [ -z "$clean_len" ] || [ "$clean_len" -lt "$PROMPT_TITLE_MIN_LEN" ] 2>/dev/null; then
    printf '%s\n' ""
    return 0
  fi
  printf '%s' "$clean" | jq -sRr --argjson n "$PROMPT_TITLE_LEN" '.[0:$n]' 2>/dev/null
  printf '\n'
}
