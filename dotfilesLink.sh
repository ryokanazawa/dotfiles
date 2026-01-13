#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

link() {
  local src="$1"
  local dst="$2"

  if [[ ! -e "$src" ]]; then
    echo "error: missing source: $src" >&2
    return 1
  fi

  mkdir -p "$(dirname -- "$dst")"
  ln -snf "$src" "$dst"
}

link "$repo_dir/.shell_common" "$HOME/.shell_common"
link "$repo_dir/.bash_profile" "$HOME/.bash_profile"
link "$repo_dir/.zshrc" "$HOME/.zshrc"
link "$repo_dir/.gitconfig" "$HOME/.gitconfig"
link "$repo_dir/.rubocop.yml" "$HOME/.rubocop.yml"
link "$repo_dir/.git-prompt.sh" "$HOME/.git-prompt.sh"
link "$repo_dir/.inputrc" "$HOME/.inputrc"
link "$repo_dir/.vimrc" "$HOME/.vimrc"

link "$repo_dir/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
link "$repo_dir/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
link "$repo_dir/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
link "$repo_dir/cursor/keybindings.json" "$HOME/Library/Application Support/Cursor/User/keybindings.json"
link "$repo_dir/karabiner.json" "$HOME/.config/karabiner/karabiner.json"
