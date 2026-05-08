# shell/env.sh — POSIX, sourced by both bash & zsh
# Environment variables and PATH only. Keep idempotent; this file is sourced
# multiple times in some scenarios (login + interactive) without duplication.

# --- XDG ----------------------------------------------------------------------
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-$HOME/.cache}"
export XDG_DATA_HOME="${XDG_DATA_HOME:-$HOME/.local/share}"
export XDG_STATE_HOME="${XDG_STATE_HOME:-$HOME/.local/state}"

# --- Editor / pager -----------------------------------------------------------
command -v hx   >/dev/null 2>&1 && export EDITOR="hx"   || export EDITOR="nvim"
export VISUAL="$EDITOR"
export GIT_EDITOR="$EDITOR"
command -v bat  >/dev/null 2>&1 && export PAGER="bat --plain --paging=always" || export PAGER="less"
export LESS="-R --mouse --wheel-lines=3 -F -X"
export MANPAGER="sh -c 'col -bx | bat --language=man --plain --paging=always'"
export MANROFFOPT="-c"

# --- Locale / colors ----------------------------------------------------------
export LANG="${LANG:-en_US.UTF-8}"
export LC_ALL="${LC_ALL:-en_US.UTF-8}"
export CLICOLOR=1
export GREP_COLORS='mt=01;33'

# --- Tool-specific env --------------------------------------------------------
export FZF_DEFAULT_OPTS='--height=40% --layout=reverse --border=rounded --info=inline --preview-window=right:60%:wrap'
command -v fd >/dev/null 2>&1 && export FZF_DEFAULT_COMMAND='fd --type f --hidden --strict-glob --exclude .git'
export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
export FZF_ALT_C_COMMAND='fd --type d --hidden --exclude .git'
export FZF_CTRL_T_OPTS='--preview "bat --color=always --line-range=:200 {} 2>/dev/null || cat {}"'
export FZF_ALT_C_OPTS='--preview "eza --tree --color=always --level=2 {} 2>/dev/null || ls -la {}"'

export BAT_THEME="${BAT_THEME:-Dracula}"
export DELTA_PAGER="less -R --mouse"
export RIPGREP_CONFIG_PATH="$XDG_CONFIG_HOME/ripgrep/config"

# History (covers both bash & zsh; each shell extends in its own rc)
export HISTSIZE=100000
export SAVEHIST=100000
export HISTCONTROL=ignoreboth:erasedups   # bash
export HISTIGNORE='ls:ll:la:cd:pwd:exit:clear:history'

# Less / man niceties
export LESSHISTFILE="$XDG_STATE_HOME/less/history"

# --- PATH (deduplicated) ------------------------------------------------------
# Define a portable path-prepend that avoids duplicates.
__path_prepend() { case ":$PATH:" in *":$1:"*) ;; *) PATH="$1${PATH:+:$PATH}" ;; esac; }

__path_prepend "/usr/local/bin"
__path_prepend "$HOME/.local/bin"
__path_prepend "$HOME/.cargo/bin"
__path_prepend "$HOME/.bun/bin"
__path_prepend "$HOME/go/bin"
__path_prepend "$HOME/.local/share/mise/shims"
export PATH

# --- Runtime homes (must be set BEFORE shims) ---------------------------------
export CARGO_HOME="$HOME/.cargo"
export RUSTUP_HOME="$HOME/.rustup"
export GOPATH="$HOME/go"
export BUN_INSTALL="$HOME/.bun"
export DENO_INSTALL="$HOME/.deno"
export VOLTA_HOME="$HOME/.volta"

# Better Python defaults
export PYTHONDONTWRITEBYTECODE=1
export PIP_DISABLE_PIP_VERSION_CHECK=1
