#!/usr/bin/env bash

set -euo pipefail

DOTFILES_DIR="$HOME/Developer/dotfiles"

link_file() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname "$dest")"

  if [ -L "$dest" ] && [ "$(readlink "$dest")" = "$src" ]; then
    return
  fi

  if [ -e "$dest" ] || [ -L "$dest" ]; then
    mv "$dest" "${dest}.backup.$(date +%Y%m%d%H%M%S)"
  fi

  ln -s "$src" "$dest"
}

link_file "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"
link_file "$DOTFILES_DIR/.shell_common" "$HOME/.shell_common"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.rubocop.yml" "$HOME/.rubocop.yml"
link_file "$DOTFILES_DIR/.git-prompt.sh" "$HOME/.git-prompt.sh"
link_file "$DOTFILES_DIR/.inputrc" "$HOME/.inputrc"
link_file "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
link_file "$DOTFILES_DIR/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
