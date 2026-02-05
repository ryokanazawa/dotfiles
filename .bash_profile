# login shell 用：bashrcを読むだけにする
if [ -f "$HOME/.bashrc" ]; then
  . "$HOME/.bashrc"
fi

# 共通設定
if [ -f "$HOME/.shellrc" ]; then
  . "$HOME/.shellrc"
fi

# Bash固有の設定

# ターミナルにコピペした時に00　01が入らないようにする
PS1='\e[?2004l\h:\W \u\$ '

## color
# export PS1="\[\033[32m\]\t \u: \W\[\033[0m\] $ "
export PS1='\[\033[32m\][\h \u: \w]\n\$\[\033[0m\] '

## git
# source /usr/local/etc/bash_completion.d/git-prompt.sh
# source /usr/local/etc/bash_completion.d/git-completion.bash

# bash-completion
# how to install - $ brew install bash-completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

HISTFILESIZE=10000
HISTCONTROL=ignoreboth
