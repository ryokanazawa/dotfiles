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

link_skill() {
  local skill_name="$1"
  local src="$DOTFILES_DIR/skills/$skill_name"

  link_file "$src" "$HOME/.claude/skills/$skill_name"
  link_file "$src" "$HOME/.codex/skills/$skill_name"
}

install_vim_plug() {
  local dest="$HOME/.vim/autoload/plug.vim"

  if [ -f "$dest" ]; then
    return
  fi

  curl --fail --location --output "$dest" --create-dirs --remove-on-error \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
}

# Shell
link_file "$DOTFILES_DIR/.bash_profile" "$HOME/.bash_profile"
link_file "$DOTFILES_DIR/.shell_common" "$HOME/.shell_common"
link_file "$DOTFILES_DIR/.zshrc" "$HOME/.zshrc"

# CLI tools
link_file "$DOTFILES_DIR/.inputrc" "$HOME/.inputrc"
link_file "$DOTFILES_DIR/.git-prompt.sh" "$HOME/.git-prompt.sh"
link_file "$DOTFILES_DIR/.gitconfig" "$HOME/.gitconfig"
link_file "$DOTFILES_DIR/.rubocop.yml" "$HOME/.rubocop.yml"
link_file "$DOTFILES_DIR/.vimrc" "$HOME/.vimrc"
install_vim_plug

# Apps
link_file "$DOTFILES_DIR/claude/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
link_file "$DOTFILES_DIR/claude/settings.json" "$HOME/.claude/settings.json"
link_file "$DOTFILES_DIR/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link_file "$DOTFILES_DIR/claude/hooks" "$HOME/.claude/hooks"
link_file "$DOTFILES_DIR/claude/rules" "$HOME/.claude/rules"
link_file "$DOTFILES_DIR/codex/AGENTS.md" "$HOME/.codex/AGENTS.md"
link_file "$DOTFILES_DIR/.codex/rules/default.rules" "$HOME/.codex/rules/default.rules"

# Skills (shared between Claude and Codex)
for skill_dir in "$DOTFILES_DIR"/skills/*/; do
  [ -d "$skill_dir" ] || continue
  link_skill "$(basename "$skill_dir")"
done

# エージェント共通のスキル標準配置
link_file "$DOTFILES_DIR/skills/autoreview" "$HOME/.agents/skills/autoreview"

link_file "$DOTFILES_DIR/cursor/settings.json" "$HOME/Library/Application Support/Cursor/User/settings.json"
link_file "$DOTFILES_DIR/ghostty/config" "$HOME/Library/Application Support/com.mitchellh.ghostty/config"
link_file "$DOTFILES_DIR/vscode/keybindings.json" "$HOME/Library/Application Support/Code/User/keybindings.json"
link_file "$DOTFILES_DIR/vscode/settings.json" "$HOME/Library/Application Support/Code/User/settings.json"
link_file "$DOTFILES_DIR/herdr/config.toml" "$HOME/.config/herdr/config.toml"
link_file "$DOTFILES_DIR/fresh/config.json" "$HOME/.config/fresh/config.json"
