## list
alias ls='ls -F'
alias ll='ls -Fla'

## anyenv
if [ -d $HOME/.anyenv ] ; then
    export PATH="$HOME/.anyenv/bin:$PATH"
    eval "$(anyenv init - zsh)"
fi

export EDITOR=vim

## image magick 6
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/avr-gcc@7/bin:$PATH"

## Keyboard
export PATH="/usr/local/opt/avr-gcc@7/bin:$PATH"

stty stop undef

PROMPT='%n: %F{green}%c%f $ '

# zsh補完
autoload -Uz compinit
compinit
zstyle ':completion::complete:*' use-cache true
zstyle ':completion:*:default' menu select=1
#大文字、小文字を区別せず補完する
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# タイプミスの補完
setopt correct
# 履歴ファイルの保存先
HISTFILE=~/.zhistory
# メモリに保存される履歴の件数
HISTSIZE=1000
# 履歴ファイルに保存される履歴の件数
SAVEHIST=100000
# 重複を記録しない
setopt hist_ignore_dups
# 開始と終了を記録
setopt EXTENDED_HISTORY
# historyを共有
setopt share_history
# ヒストリに追加されるコマンド行が古いものと同じなら古いものを削除
setopt hist_ignore_all_dups
# スペースで始まるコマンド行はヒストリリストから削除
setopt hist_ignore_space
# ヒストリを呼び出してから実行する間に一旦編集可能
setopt hist_verify
# 余分な空白は詰めて記録
setopt hist_reduce_blanks
# 古いコマンドと同じものは無視
setopt hist_save_no_dups
# historyコマンドは履歴に登録しない
setopt hist_no_store
# 補完時にヒストリを自動的に展開
setopt hist_expand
# 履歴をインクリメンタルに追加
setopt inc_append_history
# インクリメンタルからの検索
bindkey "^R" history-incremental-search-backward
bindkey "^S" history-incremental-search-forward

# Ctrl+Dでログアウトしてしまうことを防ぐ
setopt IGNOREEOF