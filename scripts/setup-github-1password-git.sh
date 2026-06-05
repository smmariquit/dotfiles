#!/usr/bin/env bash
# One-time (or repeat) setup: GitHub CLI + Git HTTPS via 1Password.
# Requires: op in PATH, gh installed, 1Password app unlocked + CLI integration.

set -euo pipefail

export PATH="${HOME}/.local/bin:${PATH}"

command -v op >/dev/null || {
  echo "Install 1Password CLI first (op not in PATH)." >&2
  exit 1
}
command -v gh >/dev/null || {
  echo "Install GitHub CLI: sudo dnf install gh" >&2
  exit 1
}

echo "== Step 1: GitHub shell plugin (interactive) =="
echo "    Pick your PAT item and default scope when prompted."
op plugin init gh

PLUGIN_SH="${XDG_CONFIG_HOME:-${HOME}/.config}/op/plugins.sh"
if [[ -r "${PLUGIN_SH}" ]]; then
  # shellcheck source=/dev/null
  source "${PLUGIN_SH}"
  echo "== Sourced ${PLUGIN_SH} for this session =="
else
  echo "Warning: ${PLUGIN_SH} not found yet. Open a new terminal after op finishes," >&2
  echo "or add the 'source .../plugins.sh' line op printed into ~/.zshrc" >&2
fi

echo "== Step 2: Make git use gh for github.com =="
gh auth setup-git

echo "== Step 3: Verify =="
gh auth status

echo ""
echo "Done. If gh failed, open a new terminal (so plugins load) and run: gh auth setup-git"
