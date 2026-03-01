#!/usr/bin/env bash
set -euo pipefail

repo_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

link_file() {
  local src="$1"
  local dest="$2"
  local ts
  ts="$(date +%Y%m%d%H%M%S)"

  mkdir -p "$(dirname "$dest")"
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    printf 'already linked %s -> %s\n' "$dest" "$src"
    return 0
  fi
  if [[ -e "$dest" || -L "$dest" ]]; then
    local backup="${dest}.bak-${ts}"
    mv "$dest" "$backup"
    printf 'moved existing %s to %s\n' "$dest" "$backup"
  fi
  ln -sfn "$src" "$dest"
  printf 'linked %s -> %s\n' "$dest" "$src"
}

link_file "$repo_dir/config.fish" "$HOME/.config/fish/config.fish"
link_file "$repo_dir/kitty.conf" "$HOME/.config/kitty/kitty.conf"
link_file "$repo_dir/gruvbox_dark.conf" "$HOME/.config/kitty/gruvbox_dark.conf"
link_file "$repo_dir/starship.toml" "$HOME/.config/starship.toml"
