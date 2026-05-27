# 共通設定を読み込む
if [ -f "$HOME/.shell_common" ]; then
  source "$HOME/.shell_common"
fi

# Zsh固有の設定

# 補完設定
autoload -Uz compinit && compinit
zstyle ':completion:*' matcher-list '' 'm:{a-zA-Z}={A-Za-z}'

# History設定
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS				# 重複を記録しない
setopt HIST_FIND_NO_DUPS				# 重複を表示しない
setopt hist_ignore_space                # スペース始まりのコマンドは記録しない
setopt hist_reduce_blanks               # 余分なスペース排除
setopt hist_verify                      # historyから実行時に確認
setopt share_history                    # 履歴ファイルを共有
setopt extended_history                 # zshの開始終了を記録

# DaVinci Resolve
export RESOLVE_SCRIPT_API="/Library/Application Support/Blackmagic Design/DaVinci Resolve/Developer/Scripting"
export RESOLVE_SCRIPT_LIB="/Applications/DaVinci Resolve/DaVinci Resolve.app/Contents/Libraries/Fusion/fusionscript.so"
export PYTHONPATH="$PYTHONPATH:$RESOLVE_SCRIPT_API/Modules/"

# kiro integration
if [[ "$TERM_PROGRAM" == "kiro" ]] && command -v kiro >/dev/null 2>&1; then
  . "$(kiro --locate-shell-integration-path zsh)"
fi

# Claude Code のタイトル上書きを無効化
export CLAUDE_CODE_DISABLE_TERMINAL_TITLE=1

# コマンド実行直前にウィンドウタイトルを「<cmd> <project|dir>」に設定
# 例: Brushpass で `claude` を叩くと "claude Brushpass" が出る
preexec() {
  local project
  project=$(git rev-parse --show-toplevel 2>/dev/null) && project="${project:t}" || project="${PWD:t}"
  local cmd="${1%% *}"
  print -Pn "\e]2;${cmd} ${project}\a"
}

# claude を抜けた後・通常のプロンプトでもディレクトリを出しておく
precmd() {
  local project
  project=$(git rev-parse --show-toplevel 2>/dev/null) && project="${project:t}" || project="${PWD:t}"
  print -Pn "\e]2;${project}\a"
}

# Ghostty シェル統合
if [ -n "$GHOSTTY_RESOURCES_DIR" ]; then
  builtin source "$GHOSTTY_RESOURCES_DIR/shell-integration/zsh/ghostty-integration"
fi
