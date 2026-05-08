# shell/functions.sh — POSIX/bash-zsh portable functions.

# Make a directory and cd into it
mkcd() { mkdir -p -- "$1" && cd -- "$1" || return; }

# Universal extractor
extract() {
  if [ -z "$1" ] || [ ! -f "$1" ]; then
    echo "usage: extract <archive>"; return 1
  fi
  case "$1" in
    *.tar.bz2|*.tbz2) tar xjvf "$1"   ;;
    *.tar.gz|*.tgz)   tar xzvf "$1"   ;;
    *.tar.xz)         tar xJvf "$1"   ;;
    *.tar.zst)        tar --zstd -xvf "$1" ;;
    *.tar)            tar xvf  "$1"   ;;
    *.bz2)            bunzip2  "$1"   ;;
    *.gz)             gunzip   "$1"   ;;
    *.zip)            unzip    "$1"   ;;
    *.7z)             7z x     "$1"   ;;
    *.rar)            unrar x  "$1"   ;;
    *.Z)              uncompress "$1" ;;
    *) echo "extract: unsupported format '$1'" ; return 1 ;;
  esac
}

# fzf-powered cd into any directory under HOME
fcd() {
  local dir
  dir="$(fd --type d --hidden --exclude .git . "${1:-$HOME}" | fzf +m)" || return
  cd -- "$dir" || return
}

# fzf-powered file open in $EDITOR
fe() {
  local file
  file="$(fd --type f --hidden --exclude .git . "${1:-.}" | fzf +m --preview 'bat --color=always --line-range=:200 {}')" || return
  ${EDITOR:-nvim} "$file"
}

# Kill a process via fzf
fkill() {
  local pid
  pid="$(ps -ef | sed 1d | fzf -m | awk '{print $2}')" || return
  [ -n "$pid" ] && echo "$pid" | xargs kill -"${1:-15}"
}

# Git: fuzzy branch switch
fbr() {
  local branch
  branch="$(git --no-pager branch --all --sort=-committerdate | grep -v HEAD \
            | sed 's/.* //' | sed 's#remotes/[^/]*/##' | awk '!seen[$0]++' \
            | fzf --preview 'git log --oneline --color=always {1} -20')" || return
  git switch "$branch" 2>/dev/null || git switch -c "$branch"
}

# Quick HTTPie-style request via xh / curl
api() { command -v xh >/dev/null 2>&1 && xh "$@" || curl -sS "$@"; }

# Generate / reuse SSH key for new host
sshgen() {
  local host="${1:?usage: sshgen <host-alias>}"
  local key="$HOME/.ssh/id_ed25519_${host}"
  [ -f "$key" ] || ssh-keygen -t ed25519 -C "${USER}@${host}" -f "$key"
  cat "${key}.pub"
}

# Quick scratch project (uses today's date)
scratch() {
  local name="${1:-scratch}"
  local dir="$HOME/scratch/$(date +%Y-%m-%d)-${name}"
  mkdir -p "$dir" && cd "$dir" || return
  echo "scratch: $dir"
}

# Show top 10 largest files in CWD
biggest() { du -ah . 2>/dev/null | sort -rh | head -n "${1:-10}"; }

# tldr or man fallback
help() { tldr "$1" 2>/dev/null || man "$1" 2>/dev/null || "$1" --help 2>/dev/null; }
