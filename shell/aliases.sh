# shell/aliases.sh — POSIX-compatible aliases (both bash & zsh).
# Tools are gated with `command -v` so a missing binary doesn't break anything.

# --- File listing -------------------------------------------------------------
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --group-directories-first --icons=auto'
  alias l='eza -lh --group-directories-first --icons=auto --git'
  alias ll='eza -lah --group-directories-first --icons=auto --git'
  alias la='eza -a --group-directories-first --icons=auto'
  alias lt='eza --tree --level=2 --icons=auto'
  alias ltt='eza --tree --level=3 --icons=auto'
else
  alias ll='ls -lah'
  alias la='ls -A'
  alias l='ls -lh'
fi

# --- cat / find ---------------------------------------------------------------
command -v bat       >/dev/null 2>&1 && alias cat='bat --paging=never'
command -v fd        >/dev/null 2>&1 || alias fd='fdfind' # Debian-ish naming, just in case
command -v rg        >/dev/null 2>&1 && alias grep='rg'

# --- Disk / mem / proc -------------------------------------------------------
command -v dust  >/dev/null 2>&1 && alias du='dust'
command -v duf   >/dev/null 2>&1 && alias df='duf'
command -v procs >/dev/null 2>&1 && alias ps='procs'
command -v btop  >/dev/null 2>&1 && alias top='btop'

# --- Git ----------------------------------------------------------------------
alias g='git'
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit -v'
alias gca='git commit -av'
alias gcm='git commit -m'
alias gco='git checkout'
alias gsw='git switch'
alias gd='git diff'
alias gds='git diff --staged'
alias gl='git log --oneline --graph --decorate -20'
alias gla='git log --oneline --graph --decorate --all -40'
alias gp='git push'
alias gpl='git pull --rebase --autostash'
alias gst='git stash'
alias gstp='git stash pop'
command -v lazygit >/dev/null 2>&1 && alias lg='lazygit'

# --- System -------------------------------------------------------------------
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias mkdir='mkdir -p'
alias path='echo "$PATH" | tr ":" "\n"'
alias ports='ss -tulanp'
alias myip='curl -fsS https://ifconfig.me; echo'
alias serve='python3 -m http.server'
alias reload='exec "$SHELL"'
alias h='history'
alias j='jobs -l'

# --- Editors ------------------------------------------------------------------
command -v hx   >/dev/null 2>&1 && alias e='hx'
command -v nvim >/dev/null 2>&1 && alias v='nvim' && alias vi='nvim' && alias vim='nvim'

# --- Containers ---------------------------------------------------------------
command -v podman >/dev/null 2>&1 && alias docker='podman'
command -v lazydocker >/dev/null 2>&1 && alias ld='lazydocker'
command -v kubectl >/dev/null 2>&1 && alias k='kubectl'

# --- Fedora package shortcuts -------------------------------------------------
alias dnfu='sudo dnf upgrade --refresh'
alias dnfi='sudo dnf install'
alias dnfr='sudo dnf remove'
alias dnfs='dnf search'
alias dnfq='dnf info'

# --- Safety nets --------------------------------------------------------------
alias rm='rm -i'
alias mv='mv -i'
alias cp='cp -i'

# --- Spyder (preserved from prior config) -------------------------------------
[ -x "$HOME/.local/spyder-6/envs/spyder-runtime/bin/spyder" ] && \
  alias spyder="$HOME/.local/spyder-6/envs/spyder-runtime/bin/spyder"
[ -x "$HOME/.local/spyder-6/uninstall-spyder.sh" ] && \
  alias uninstall-spyder="$HOME/.local/spyder-6/uninstall-spyder.sh"

# --- Claude Code ----------------------------------------------------------------
# ccc: a session on Sonnet, for click-heavy work (inbox checks, forms, chat reading) that does not need the top model.
alias ccc='claude --model sonnet'

# --- Agents get the standard tools --------------------------------------------
# Claude Code sets CLAUDECODE=1 in the shells it runs. The aliases above that replace a
# standard command break its flags there (du -sh, ps aux, grep -c), and rm/mv/cp -i wait
# for an answer nobody types. Real terminals keep every alias.
if [ -n "${CLAUDECODE:-}" ]; then
  for __a in ls cat grep du df ps top rm mv cp; do unalias "$__a" 2>/dev/null; done
  unset __a
fi
