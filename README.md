# dotfiles

Personal configuration files for my Fedora 43 + Wayland power-dev setup.

## Quick install

```sh
git clone https://github.com/smmariquit/dotfiles.git ~/dotfiles
cd ~/dotfiles
sudo bash install/packages.sh   # ~5–15 min: dnf + cargo + flatpak + tldr cache
bash install/bootstrap.sh       # symlinks configs into $HOME (existing files backed up)
exec zsh                        # reload shell
```

`install/packages.sh` is idempotent — re-run it anytime to pick up new tools.

## Tooling installed by `install/packages.sh`

| Category | Tools |
|---|---|
| **Modern CLIs** | `fzf` `fd` `bat` `eza` `zoxide` `delta` `atuin` `starship` `direnv` `yazi` `btop` `ncdu` `duf` `dust` `procs` `hyperfine` `tokei` `tldr` `glow` `gum` `yq` `xh` `gping` `bandwhich` `sd` `entr` `watchexec` `sccache` `git-absorb` |
| **Editors** | `helix` `neovim` `lazygit` |
| **Languages / VMs** | `mise` (universal version manager), `uv` `pipx` (Python), `rustup`/`cargo`, `go`, `pnpm` `bun` (already), `deno` (via mise) |
| **Containers / Cloud** | `podman` `kubectl` `helm` `k9s` `lazydocker` `podman-compose` |
| **Build / Task** | `just` `make` `cmake` |
| **Network** | `httpie` `nmap` `mtr` `iperf3` `aria2` `bind-utils` |
| **Misc** | `p7zip` `moreutils` `pv` `tmux` `ripgrep` `jq` |
| **Shell plugins** | `zsh-autosuggestions` `zsh-syntax-highlighting` |
| **Flatpaks** | Flatseal, Meld, DBeaver, Insomnia |

## Repo layout

```
dotfiles/
├── install/
│   ├── packages.sh     # idempotent installer (dnf + cargo + flatpak)
│   └── bootstrap.sh    # symlink configs into $HOME (backs up existing)
├── shell/
│   ├── zshrc           # entry; sources common/* then zsh extras
│   ├── bashrc          # entry; sources common/* then bash extras
│   ├── bash_profile    # login shell
│   ├── bash_logout
│   ├── env.sh          # PATH + exports (POSIX, sourced by both shells)
│   ├── aliases.sh      # POSIX aliases
│   ├── functions.sh    # mkcd, extract, fcd, fe, fkill, fbr, ...
│   └── tools.sh        # init starship, zoxide, mise, atuin, fzf, direnv
├── starship/starship.toml
├── bat/config
├── git/gitconfig       # delta-powered diffs, sane defaults, aliases
├── alacritty/          # GPU terminal theme (Dank Material)
├── hypr/               # Hyprland (dynamic tiling Wayland)
├── niri/               # Niri (scrollable tiling Wayland)
├── noctalia/           # Desktop shell
├── dgop/               # System monitor
├── gtk/                # GTK 3 & 4 Material You overrides
├── cava/               # Audio visualizer shaders
└── vscode/             # Editor settings + MCP
```

## Shell layering

The `shell/` directory is intentionally modular so the same logic works in
both bash and zsh without duplication:

```
zshrc / bashrc       <- thin shell-specific entry point
   │
   ├─> env.sh        <- PATH, XDG, EDITOR, FZF_*, BAT_THEME, language homes
   ├─> aliases.sh    <- ls→eza, cat→bat, top→btop, git shortcuts, etc.
   ├─> functions.sh  <- mkcd, extract, fzf-powered fcd / fe / fkill / fbr
   └─> tools.sh      <- starship, zoxide, mise, atuin, fzf, direnv hooks
```

Tool initialisers are gated with `command -v` so a missing binary never breaks
your shell.

## Highlighted bindings

| Keys | Action |
|---|---|
| `Ctrl-R` | `atuin` full-text shell history search |
| `Ctrl-T` | `fzf` file search → insert path |
| `Alt-C`  | `fzf` directory search → cd |
| `cd <fragment>` | `zoxide` smart jump |
| `cdi` | `zoxide` interactive |
| `lg` | lazygit |
| `k`  | kubectl |
| `v` / `e` | nvim / helix |

## Manual one-time setup steps

These are NOT in `install/packages.sh` because they're one-shot or interactive:

```sh
# 1Password CLI (gh plugin)
op plugin init gh

# GitHub auth
gh auth login

# Mise: bigger toolchain (optional)
mise use -g node@lts python@3.13 rust@stable go@latest
```

## Environment

- **OS:** Fedora 43 (Workstation)
- **Display:** Wayland (GNOME default; Niri / Hyprland alternate)
- **Shell:** Zsh (with bash kept fully functional)
- **Terminal:** Alacritty
- **Theme:** Dank Material (Material You dark via Matugen)

## Color palette

| Role | Hex |
|------|-----|
| Primary | `#d0bcff` |
| On Primary | `#381e72` |
| Secondary | `#ccc2dc` |
| Surface | `#141218` |
| Surface Container | `#211f24` |
| On Surface | `#e6e0e9` |
| Error | `#f2b8b5` |

## License

These are my personal configs. Feel free to take whatever is useful.

## 📊 Current State of the Code
- **Tech Stack:** Static / Basic Scripts
- **Repository Size:** 43 tracked files
- **Latest Update:** `ffca8f1 chore: add stale issue and PR validators`


---
*☕ If you found this project useful, you can support my work at [kape.stimmie.dev](https://kape.stimmie.dev)!*