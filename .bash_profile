## list
alias ls='ls -F'
alias ll='ls -Fla'

## 写真を日付のフォルダに整理する
function rename() {
  exiftool '-FileName < CreateDate' -d %Y%m%d_%H%M%S%%-c.%%e *
  exiftool '-Directory < CreateDate' -d %Y%m%d *
}

## color
# export PS1="\[\033[32m\]\t \u: \W\[\033[0m\] $ "
export PS1='\[\033[32m\][\h \u: \w]\n\$\[\033[0m\] '
export CLICOLOR=1

## anyenv
export PATH="$HOME/.anyenv/bin:$PATH"
if command -v anyenv >/dev/null 2>&1; then
  eval "$(anyenv init -)"
fi

## ruby
export PATH="$HOME/.anyenv/envs/rbenv/shims:$PATH"
export RBENV_ROOT="$HOME/.anyenv/envs/rbenv"
export PATH="$RBENV_ROOT/bin:$PATH"
if command -v rbenv >/dev/null 2>&1; then
  eval "$(rbenv init -)"
fi

## go
export GOENV_ROOT="$HOME/.anyenv/envs/goenv"
export PATH="$GOENV_ROOT/bin:$PATH"
if command -v goenv >/dev/null 2>&1; then
  eval "$(goenv init -)"
fi
# GOROOTとGOPATHはgoenv init後に設定
if [ -n "$GOROOT" ]; then
  export PATH="$GOROOT/bin:$PATH"
fi
if [ -n "$GOPATH" ]; then
  export PATH="$GOPATH/bin:$PATH"
fi

## git
# source /usr/local/etc/bash_completion.d/git-prompt.sh
# source /usr/local/etc/bash_completion.d/git-completion.bash

export EDITOR=vim

## image magick 6
export PATH="/usr/local/opt/imagemagick@6/bin:$PATH"
export PATH="/usr/local/opt/avr-gcc@7/bin:$PATH"

# bash-completion
# how to install - $ brew install bash-completion
[ -f /usr/local/etc/bash_completion ] && . /usr/local/etc/bash_completion

# 端末かどうかをテストしてから実行
if [ -t 0 ]
then
  stty stop undef
fi


HISTFILESIZE=10000
HISTCONTROL=ignoreboth

eval "$(/opt/homebrew/bin/brew shellenv)"

export RUBY_CFLAGS="-w -Wno-error=implicit-function-declaration -DUSE_FFI_CLOSURE_ALLOC"

export PATH="/opt/homebrew/opt/openssl@1.1/bin:$PATH"
export LDFLAGS="-L/opt/homebrew/opt/openssl@1.1/lib"
export CPPFLAGS="-I/opt/homebrew/opt/openssl@1.1/include"
export PKG_CONFIG_PATH="/opt/homebrew/opt/openssl@1.1/lib/pkgconfig"
export RUBY_CONFIGURE_OPTS="--with-openssl-dir=/opt/homebrew/opt/openssl@1.1"

# Added by Windsurf
export PATH="/Users/ryo/.codeium/windsurf/bin:$PATH"
