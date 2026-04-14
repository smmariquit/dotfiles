# dotfiles

Personal configuration files for my Fedora 43 + Wayland setup.

## Overview

| Component | Config Path | Description |
|-----------|------------|-------------|
| **Shell** | `shell/` | Bash and Zsh configs with NVM, Bun, 1Password CLI |
| **Git** | `git/` | Global gitconfig with GitHub credential helper via `gh` |
| **Niri** | `niri/` | Scrollable tiling Wayland compositor (KDL config + DMS theme overrides) |
| **Hyprland** | `hypr/` | Dynamic tiling Wayland compositor with dwindle layout |
| **Alacritty** | `alacritty/` | GPU-accelerated terminal color theme (Dank Material dark) |
| **Cava** | `cava/` | Audio visualizer GLSL shaders |
| **GTK** | `gtk/` | GTK 3 & 4 color overrides generated with Matugen (Material You) |
| **Noctalia** | `noctalia/` | Desktop shell (bar, dock, control center, notifications) |
| **dgop** | `dgop/` | Dashboard/system monitor color scheme |
| **VS Code** | `vscode/` | Editor settings and MCP config |

## Installation

Clone the repo and symlink configs to their expected locations:

```sh
git clone https://github.com/smmariquit/dotfiles.git ~/dotfiles
cd ~/dotfiles

# Shell
ln -sf ~/dotfiles/shell/bashrc       ~/.bashrc
ln -sf ~/dotfiles/shell/bash_profile  ~/.bash_profile
ln -sf ~/dotfiles/shell/bash_logout   ~/.bash_logout
ln -sf ~/dotfiles/shell/zshrc         ~/.zshrc

# Git
ln -sf ~/dotfiles/git/gitconfig       ~/.gitconfig

# Niri
mkdir -p ~/.config/niri/dms
ln -sf ~/dotfiles/niri/config.kdl     ~/.config/niri/config.kdl
for f in ~/dotfiles/niri/dms/*.kdl; do
  ln -sf "$f" ~/.config/niri/dms/
done

# Hyprland
mkdir -p ~/.config/hypr
ln -sf ~/dotfiles/hypr/hyprland.conf  ~/.config/hypr/hyprland.conf

# Alacritty
mkdir -p ~/.config/alacritty
ln -sf ~/dotfiles/alacritty/dank-theme.toml ~/.config/alacritty/dank-theme.toml

# Cava
mkdir -p ~/.config/cava/shaders
ln -sf ~/dotfiles/cava/shaders/*.frag ~/.config/cava/shaders/
ln -sf ~/dotfiles/cava/shaders/*.vert ~/.config/cava/shaders/

# GTK themes
mkdir -p ~/.config/gtk-3.0 ~/.config/gtk-4.0
ln -sf ~/dotfiles/gtk/gtk-3.0/dank-colors.css ~/.config/gtk-3.0/dank-colors.css
ln -sf ~/dotfiles/gtk/gtk-4.0/dank-colors.css ~/.config/gtk-4.0/dank-colors.css

# Noctalia shell
mkdir -p ~/.config/noctalia
ln -sf ~/dotfiles/noctalia/settings.json ~/.config/noctalia/settings.json
ln -sf ~/dotfiles/noctalia/plugins.json  ~/.config/noctalia/plugins.json
ln -sf ~/dotfiles/noctalia/colors.json   ~/.config/noctalia/colors.json

# dgop
mkdir -p ~/.config/dgop
ln -sf ~/dotfiles/dgop/colors.json ~/.config/dgop/colors.json

# VS Code
mkdir -p ~/.config/Code/User
ln -sf ~/dotfiles/vscode/settings.json ~/.config/Code/User/settings.json
ln -sf ~/dotfiles/vscode/mcp.json      ~/.config/Code/User/mcp.json
```

## Environment

- **OS:** Fedora 43 (Workstation)
- **Display:** Wayland
- **Desktop:** GNOME (with Niri / Hyprland as alternate compositors)
- **Shell:** Zsh (+ Bash)
- **Terminal:** Alacritty
- **Theme:** Dank Material (Material You dark palette via Matugen)

## Color Palette

The theme is built around a Material You dark palette generated with [Matugen](https://github.com/InioX/matugen). Key colors:

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
