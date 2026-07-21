#!/usr/bin/env bash
# Snapshot installed packages + copied configs into the repo, then commit & push.
# Symlinked configs (zshrc, gitconfig, starship, bat) track themselves.
# Run manually or via the dotfiles-sync systemd user timer.
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")/.." && pwd)"
cd "$DOTFILES"

mkdir -p packages

dnf repoquery --userinstalled --qf '%{name}\n' 2>/dev/null | sort -u > packages/dnf.txt
flatpak list --app --columns=application 2>/dev/null | sort > packages/flatpak.txt
cargo install --list 2>/dev/null | awk '/^[a-zA-Z0-9_-]+ v[0-9]/ {print $1}' | sort > packages/cargo.txt
pipx list --short 2>/dev/null | awk '{print $1}' | sort > packages/pipx.txt
uv tool list 2>/dev/null | awk '/^[a-zA-Z]/ {print $1}' | sort > packages/uv-tools.txt
npm ls -g --depth=0 --parseable 2>/dev/null | sed -n 's|.*/node_modules/||p' | sort > packages/npm-global.txt
bun pm ls -g 2>/dev/null | sed -nE 's/^[^a-zA-Z@]*([a-zA-Z@][^ ]*)@[0-9].*/\1/p' | sort > packages/bun-global.txt
gnome-extensions list 2>/dev/null | sort > packages/gnome-extensions.txt
code --list-extensions 2>/dev/null | sort > vscode/extensions.txt

# Sync copied (non-symlinked) configs: only files the repo already tracks.
git ls-files alacritty hypr niri noctalia cava dgop | while read -r f; do
  src="$HOME/.config/$f"
  [ -f "$src" ] && cp "$src" "$f"
done
cp "$HOME/.config/Code/User/settings.json" vscode/settings.json
cp "$HOME/.config/Code/User/mcp.json" vscode/mcp.json

git add -A
if git diff --cached --quiet; then
  echo "dotfiles: nothing to sync"
  exit 0
fi
# ponytail: gpgsign off here, headless run has no ssh-agent for the signing key
git -c commit.gpgsign=false commit -m "chore: sync configs and package manifests ($(date +%F))"
git push
