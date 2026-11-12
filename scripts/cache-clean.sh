#!/usr/bin/env bash
# cache-clean.sh: clear rebuildable caches. Never touches projects, ~/Downloads or node_modules.
#
#   cache-clean.sh            weekly mode: prune what the tools consider unused
#   cache-clean.sh --deep     also wipe whole caches (uv, npm, bun, huggingface)
#   cache-clean.sh --dry-run  print sizes and what would run, change nothing
#
# Log: ~/.local/state/cache-clean.log. Warns on the desktop when / has under 30 GB free.
set -u
MODE=weekly; DRY=0
for a in "$@"; do case "$a" in --deep) MODE=deep ;; --dry-run) DRY=1 ;; *) echo "unknown option: $a" >&2; exit 2 ;; esac; done
LOG="${XDG_STATE_HOME:-$HOME/.local/state}/cache-clean.log"
mkdir -p "$(dirname "$LOG")"
free_gb() { echo $(( $(df --output=avail -k / | tail -1) / 1048576 )); }
say() { echo "$*"; [ "$DRY" = 1 ] || echo "$*" >> "$LOG"; }

# step <label> <dir to size, or -> <command...>
step() {
  local label="$1" dir="$2"; shift 2
  local size="-"
  [ "$dir" != "-" ] && [ -e "$dir" ] && size="$(du -sh "$dir" 2>/dev/null | cut -f1)"
  command -v "$1" >/dev/null 2>&1 || { say "- $label ($size): skipped, $1 not found"; return; }
  if [ "$DRY" = 1 ]; then say "- $label ($size): would run: $*"; return; fi
  # 15 minute cap per step, so a stuck tool never blocks the rest
  if timeout 900 "$@" >/dev/null 2>&1; then say "- $label ($size): cleared"; else say "- $label ($size): FAILED, left as is"; fi
}
# uv waits forever for its cache lock while any uv-run tool (for example an MCP server started with uvx) is alive
uv_step() {
  if pgrep -x uv >/dev/null 2>&1 || pgrep -f '\.cache/uv/archive' >/dev/null 2>&1; then
    say "- $1: skipped, the uv cache is in use by a running tool"
  else step "$@"; fi
}

before="$(free_gb)"
say "## $(date '+%F %T') mode=$MODE free=${before} GB"
if [ "$MODE" = deep ]; then
  uv_step "uv cache" "$HOME/.cache/uv" uv cache clean
  step "npm cache" "$HOME/.npm" npm cache clean --force
  step "bun install cache" "$HOME/.bun/install/cache" bun pm cache rm
  step "huggingface models" "$HOME/.cache/huggingface" rm -rf "$HOME/.cache/huggingface"
else
  uv_step "uv cache (unused entries)" "$HOME/.cache/uv" uv cache prune
  step "npm cache (verify and compact)" "$HOME/.npm" npm cache verify
fi
step "pnpm store (unreferenced packages)" "$HOME/.local/share/pnpm" pnpm store prune
step "thumbnails" "$HOME/.cache/thumbnails" rm -rf "$HOME/.cache/thumbnails"
step "podman stopped containers and dangling images" - podman system prune -f
step "empty Claude sessions (to trash)" - "$HOME/.local/bin/cs" --prune --yes
after="$(free_gb)"
say "free after: ${after} GB (freed about $(( after - before )) GB)"

if [ "$DRY" = 0 ] && [ "$after" -lt 30 ] && command -v notify-send >/dev/null 2>&1; then
  notify-send -u critical "Disk space low" "Only ${after} GB free on /. Btrfs slows down below about 40 GB." || true
fi
