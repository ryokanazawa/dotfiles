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
