#!/usr/bin/env bash
# oops installer — works as a local script or via `curl -fsSL ... | bash`.
# https://github.com/TheSolyboy/oops
set -eo pipefail

OOPS_REPO="${OOPS_REPO:-TheSolyboy/oops}"
OOPS_BRANCH="${OOPS_BRANCH:-main}"
RAW_BASE="https://raw.githubusercontent.com/${OOPS_REPO}/${OOPS_BRANCH}"

DATA_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/oops"
INTEGRATION="$DATA_DIR/oops.sh"

say() { printf '%s\n' "$*"; }

say ""
say "  oops — fix your last shell command with AI"
say "  ------------------------------------------"
say ""

mkdir -p "$DATA_DIR"

# 1. Install the shell integration: copy it from a local checkout if we have
#    one, otherwise download it from the repo.
script_dir=""
if [ -n "${BASH_SOURCE:-}" ]; then
  script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd) || script_dir=""
fi

if [ -n "$script_dir" ] && [ -f "$script_dir/oops.sh" ]; then
  cp "$script_dir/oops.sh" "$INTEGRATION"
  say "Installed shell integration from local checkout."
else
  say "Downloading shell integration..."
  if command -v curl >/dev/null 2>&1; then
    curl -fsSL "$RAW_BASE/oops.sh" -o "$INTEGRATION"
  elif command -v wget >/dev/null 2>&1; then
    wget -qO "$INTEGRATION" "$RAW_BASE/oops.sh"
  else
    say "error: curl or wget is required to download oops." >&2
    exit 1
  fi
fi
say "  -> $INTEGRATION"

# 2. Source the integration from the right shell rc file (idempotent).
add_source_line() {
  local rc="$1"
  [ -f "$rc" ] || touch "$rc"
  if grep -Fq "$INTEGRATION" "$rc" 2>/dev/null; then
    say "Already sourced in $rc"
  else
    {
      printf '\n# oops shell assistant\n'
      printf '[ -f "%s" ] && . "%s"\n' "$INTEGRATION" "$INTEGRATION"
    } >> "$rc"
    say "Added source line to $rc"
  fi
}

added=0
case "${SHELL:-}" in
  *zsh)  add_source_line "${ZDOTDIR:-$HOME}/.zshrc"; added=1 ;;
  *bash) add_source_line "$HOME/.bashrc"; added=1 ;;
esac
if [ "$added" -eq 0 ]; then
  [ -f "$HOME/.bashrc" ] && { add_source_line "$HOME/.bashrc"; added=1; }
  [ -f "$HOME/.zshrc" ]  && { add_source_line "$HOME/.zshrc";  added=1; }
fi
[ "$added" -eq 0 ] && add_source_line "$HOME/.bashrc"

# 3. Run the interactive setup (provider, key, model) from the integration.
# shellcheck disable=SC1090
. "$INTEGRATION"
set +e
_oops_setup
set -e

# 4. Friendly nudges about optional helpers.
command -v curl >/dev/null 2>&1 || say "note: install 'curl' — oops needs it to call the API."
command -v jq   >/dev/null 2>&1 || say "tip:  install 'jq' for the most reliable response parsing."
if ! command -v xclip >/dev/null 2>&1 \
  && ! command -v xsel >/dev/null 2>&1 \
  && ! command -v wl-copy >/dev/null 2>&1 \
  && ! command -v pbcopy >/dev/null 2>&1; then
  say "tip:  install 'xclip', 'xsel', or 'wl-clipboard' to auto-copy fixes."
fi

say ""
say "  Done! Restart your shell or run:"
say "      source \"$INTEGRATION\""
say ""
say "  Then run a command that fails and type:  oops"
say ""
