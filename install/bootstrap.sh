#!/usr/bin/env bash
# Symlink dotfiles into the right places. Idempotent.
# Run as your user (NOT root). Existing files get backed up to ~/.dotfiles-backup-<timestamp>.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Don't run this as root." >&2
  exit 1
fi

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
BACKUP="$HOME/.dotfiles-backup-$(date +%Y%m%d-%H%M%S)"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

mkdir -p "$BACKUP"

# link <src-relative-to-DOTFILES> <dst-absolute>
link() {
  local src="$DOTFILES/$1"
  local dst="$2"
  if [[ ! -e "$src" ]]; then warn "missing src: $src"; return; fi
  mkdir -p "$(dirname "$dst")"
  if [[ -L "$dst" ]]; then
    rm "$dst"
  elif [[ -e "$dst" ]]; then
    mv "$dst" "$BACKUP/"
    echo "  backed up $dst -> $BACKUP/"
  fi
  ln -s "$src" "$dst"
  echo "  linked $dst -> $src"
}

log "Linking shell configs"
link shell/zshrc        "$HOME/.zshrc"
link shell/bashrc       "$HOME/.bashrc"
link shell/bash_profile "$HOME/.bash_profile"
link shell/bash_logout  "$HOME/.bash_logout"

log "Linking starship"
link starship/starship.toml "$HOME/.config/starship.toml"

log "Linking bat"
link bat/config "$HOME/.config/bat/config"

log "Linking git"
link git/gitconfig "$HOME/.gitconfig"

# Pre-existing layouts (alacritty/hypr/niri/etc.) are not relinked here;
# they have their own setup steps in the README and don't need re-running.

log "Done. Restart your shell:  exec zsh"
echo "Backups (if any) at: $BACKUP"
