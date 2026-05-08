#!/usr/bin/env bash
# Idempotent package installer for power-dev toolset.
# Usage:
#   sudo bash packages.sh        # full install (dnf needs root)
# Cargo & user-level installs run as the original user.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "This script needs root for dnf. Run with: sudo bash $0" >&2
  exit 1
fi

# Resolve the calling user (so cargo/mise/etc. install for them, not root)
TARGET_USER="${SUDO_USER:-$(logname 2>/dev/null || echo "$USER")}"
TARGET_HOME="$(getent passwd "$TARGET_USER" | cut -d: -f6)"

log()  { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
warn() { printf '\033[1;33m!! %s\033[0m\n' "$*" >&2; }

#####################################
# 1. Enable repos / Terra (terra.fyi)
#####################################
log "Ensuring useful repos are enabled"
# Terra is RPM-Fusion-adjacent and provides modern dev tooling (mise, helix, etc.)
if ! dnf repolist --enabled 2>/dev/null | grep -q '^terra\b'; then
  dnf install -y --skip-unavailable \
    'dnf-command(config-manager)' || true
  dnf install -y --nogpgcheck --repofrompath \
    'terra,https://repos.fyralabs.com/terra$releasever' \
    terra-release || warn "Could not enable Terra; continuing anyway"
fi

#####################################
# 2. dnf packages — the big list
#####################################
log "Installing system packages via dnf"
DNF_PKGS=(
  # Modern CLI replacements (Rust)
  fzf fd-find bat eza zoxide git-delta atuin starship direnv
  yazi btop ncdu duf dust procs hyperfine tokei tealdeer
  glow gum yq gping bandwhich entr sccache git-absorb
  # Note: xh / sd / watchexec / lazydocker are NOT in Fedora repos →
  # they're handled in the cargo / go fallback block below.

  # Editors
  helix neovim

  # Languages / runtimes / version managers
  mise uv pipx rust cargo golang pnpm clang-devel
  # clang-devel is for `bindgen` / Rust crates that ship C bindings (e.g. ouch).

  # Build / task
  just

  # Containers / cloud
  kubectl helm k9s podman-compose

  # Network / debugging
  httpie nmap mtr iperf3 aria2 bind-utils traceroute

  # General utilities
  p7zip p7zip-plugins moreutils pv tmux ripgrep jq

  # Shell plugins
  zsh-autosuggestions zsh-syntax-highlighting

  # Build essentials (CUDA/native deps need these)
  gcc gcc-c++ make cmake pkgconf-pkg-config kernel-devel kernel-headers
)

# --skip-unavailable lets the install proceed even if a package was renamed/dropped
dnf install -y --skip-unavailable "${DNF_PKGS[@]}" || warn "Some packages failed; continuing"

#####################################
# 3. Cargo fallback for missing tools
#####################################
log "Installing Rust-based tools that aren't in dnf (as $TARGET_USER)"
# Anything dnf didn't provide gets covered here. cargo-binstall fetches prebuilt
# binaries when possible (much faster than compiling from source).
sudo -u "$TARGET_USER" -H bash <<'USERSH'
set -euo pipefail
export PATH="$HOME/.cargo/bin:$PATH"

if ! command -v cargo >/dev/null; then
  echo "cargo not in PATH; skipping user cargo installs"
  exit 0
fi

if ! command -v cargo-binstall >/dev/null; then
  cargo install cargo-binstall || true
fi

CARGO_INSTALL() {
  local bin="$1" crate="${2:-$1}"
  if ! command -v "$bin" >/dev/null; then
    cargo binstall -y "$crate" 2>/dev/null \
      || cargo install --locked "$crate" || true
  fi
}

# Tools that aren't in Fedora repos — pull pre-built binaries via cargo-binstall.
CARGO_INSTALL xh                                       # Rust HTTPie
CARGO_INSTALL sd                                       # sed replacement
CARGO_INSTALL watchexec        watchexec-cli           # smarter file watcher
CARGO_INSTALL btm              bottom                  # alt resource monitor
CARGO_INSTALL choose                                   # cut/awk replacement
CARGO_INSTALL fnm                                      # fast node manager
CARGO_INSTALL ouch                                     # universal archive tool

# Go tools (lazydocker is no longer published to Fedora repos as of F43).
if command -v go >/dev/null && ! command -v lazydocker >/dev/null; then
  go install github.com/jesseduffield/lazydocker@latest || true
fi
USERSH

#####################################
# 4. Mise: bootstrap a few global runtimes (no-op if already present)
#####################################
log "Bootstrapping mise (universal version manager)"
sudo -u "$TARGET_USER" -H bash <<'USERSH'
set -euo pipefail
export PATH="$HOME/.local/bin:$PATH"
if command -v mise >/dev/null; then
  # Don't override system rust/go if user wants them; only set defaults if unset.
  mise use -g node@lts   2>/dev/null || true
  mise use -g python@3.13 2>/dev/null || true
  # mise use -g go@latest  # uncomment if you want mise-managed go
fi
USERSH

#####################################
# 5. Flatpaks (optional power-dev apps)
#####################################
if command -v flatpak >/dev/null; then
  log "Installing select flatpak apps (skipped if already present)"
  FLATPAKS=(
    com.github.tchx84.Flatseal       # flatpak permissions GUI
    org.gnome.meld                   # diff/merge tool
    io.dbeaver.DBeaverCommunity      # universal DB GUI
    rest.insomnia.Insomnia           # API client
  )
  for app in "${FLATPAKS[@]}"; do
    flatpak install -y --noninteractive flathub "$app" 2>/dev/null || true
  done
fi

#####################################
# 6. tldr cache prime
#####################################
log "Priming tldr cache"
sudo -u "$TARGET_USER" -H tldr --update >/dev/null 2>&1 || true

log "Package install complete."
echo "Next: run 'install/bootstrap.sh' (no sudo) to symlink configs."
