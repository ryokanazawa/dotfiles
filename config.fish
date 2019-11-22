set -x PATH $HOME/.anyenv/bin $PATH

set -x GOENV_ROOT $HOME/.anyenv/envs/goenv
set -x PATH $HOME/.anyenv/envs/goenv/bin $PATH
set -x PATH $HOME/.anyenv/envs/goenv/shims $PATH

set -x RBENV_ROOT $HOME/.anyenv/envs/rbenv
set -x PATH $HOME/.anyenv/envs/rbenv/bin $PATH
set -x PATH $HOME/.anyenv/envs/rbenv/shims $PATH

set -x PYENV_ROOT $HOME/.anyenv/envs/pyenv
set -x PATH $PYENV_ROOT/bin $PATH

set -x PATH /usr/local/opt/imagemagick@6/bin/ $PATH
