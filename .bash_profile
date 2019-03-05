## list
alias ls='ls -F'
alias ll='ls -Fla'

## color
# export PS1="\[\033[32m\]\t \u: \W\[\033[0m\] $ "
export PS1='\[\033[32m\][\h \u: \w]\n\$\[\033[0m\] '
export CLICOLOR=1

## anyenv
export PATH="$HOME/.anyenv/bin:$PATH"

## npm modules
export PATH="$HOME/.anyenv/envs/ndenv/shims:$PATH"
export PATH="./node_modules/.bin:$PATH"

## ruby
export PATH="$HOME/.anyenv/envs/rbenv/shims:$PATH"
export RBENV_ROOT="$HOME/.anyenv/envs/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
eval "$(rbenv init -)"

## git
# source /usr/local/etc/bash_completion.d/git-prompt.sh
# source /usr/local/etc/bash_completion.d/git-completion.bash

export EDITOR=atom

# image magick 6
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/avr-gcc@7/bin:$PATH"

# Keyboard
export PATH="/usr/local/opt/avr-gcc@7/bin:$PATH"

# bash-completion
# how to install - $ brew install bash-completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion
