# shell/tools.sh — initialise interactive-only tools.
# Sourced by both bash & zsh; the per-shell logic uses $0 / $ZSH_VERSION / $BASH_VERSION.
# Anything heavy or non-deterministic should live here, not in env.sh.

# --- Detect current shell -----------------------------------------------------
__SHELL_NAME="bash"
[ -n "${ZSH_VERSION:-}" ] && __SHELL_NAME="zsh"

# --- Starship prompt ----------------------------------------------------------
if command -v starship >/dev/null 2>&1; then
  eval "$(starship init "$__SHELL_NAME")"
fi

# --- zoxide (smart cd) --------------------------------------------------------
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init "$__SHELL_NAME" --cmd cd)"   # `cd` becomes z; `cdi` is interactive
fi

# --- direnv -------------------------------------------------------------------
if command -v direnv >/dev/null 2>&1; then
  eval "$(direnv hook "$__SHELL_NAME")"
fi

# --- mise (universal version manager) ----------------------------------------
if command -v mise >/dev/null 2>&1; then
  eval "$(mise activate "$__SHELL_NAME")"
fi

# --- fzf key bindings & completion -------------------------------------------
if command -v fzf >/dev/null 2>&1; then
  if [ "$__SHELL_NAME" = "zsh" ]; then
    [ -r /usr/share/fzf/shell/key-bindings.zsh ] && . /usr/share/fzf/shell/key-bindings.zsh
    [ -r /usr/share/zsh/site-functions/_fzf ]    && fpath+=(/usr/share/zsh/site-functions)
    # Fedora 43 alternate paths
    [ -r /usr/share/fzf/key-bindings.zsh ]       && . /usr/share/fzf/key-bindings.zsh
    [ -r /usr/share/fzf/completion.zsh ]         && . /usr/share/fzf/completion.zsh
  else
    [ -r /usr/share/fzf/shell/key-bindings.bash ] && . /usr/share/fzf/shell/key-bindings.bash
    [ -r /usr/share/fzf/key-bindings.bash ]       && . /usr/share/fzf/key-bindings.bash
    [ -r /usr/share/fzf/completion.bash ]         && . /usr/share/fzf/completion.bash
  fi
fi

# --- atuin (sqlite-backed shell history; replaces Ctrl-R) --------------------
if command -v atuin >/dev/null 2>&1; then
  # --disable-up-arrow keeps muscle memory: Up/Down still walks file history;
  # Ctrl-R opens atuin's full-text search across all sessions.
  eval "$(atuin init "$__SHELL_NAME" --disable-up-arrow)"
fi

# --- Bun completions ----------------------------------------------------------
[ -s "$HOME/.bun/_bun" ] && [ "$__SHELL_NAME" = "zsh" ] && . "$HOME/.bun/_bun"

# --- 1Password shell plugins (preserved) -------------------------------------
[ -r "${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh" ] && . "${XDG_CONFIG_HOME:-$HOME/.config}/op/plugins.sh"

unset __SHELL_NAME
