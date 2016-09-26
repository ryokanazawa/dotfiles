## list
alias ls='ls -F'
alias ll='ls -Fla'

## color
export PS1="\[\033[32m\]\t \u: \W\[\033[0m\] $ "
export CLICOLOR=1

## anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)"

## npm modules
export PATH="$HOME/.anyenv/envs/ndenv/shims/npm:$PATH"
export PATH="./node_modules/.bin:$PATH"

## git 補完
source /usr/local/etc/bash_completion.d/git-prompt.sh
source /usr/local/etc/bash_completion.d/git-completion.bash
