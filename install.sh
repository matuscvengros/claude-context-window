#!/usr/bin/env bash
set -euo pipefail

# install.sh — Configure claude-context-window status bar in Claude Code settings.
# Usage: ./install.sh [--force]
# Running without arguments installs immediately.
#
# Copies src/statusline.js to ~/.claude/statusline.js and updates
# ~/.claude/settings.json with the statusLine command.

MARKER="claude-context-window"

# Resolve the directory this script lives in (handles symlinks)
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
STATUSLINE_SRC="${SCRIPT_DIR}/src/statusline.js"
CLAUDE_DIR="${HOME}/.claude"
STATUSLINE_DEST="${CLAUDE_DIR}/statusline.js"
SETTINGS_FILE="${CLAUDE_DIR}/settings.json"

GREEN='\033[32m'
DIM='\033[2m'
RESET='\033[0m'

ensure_deps() {
  if ! command -v node >/dev/null 2>&1; then
    echo "Error: node is required but not found in PATH" >&2
    exit 1
  fi
  if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not found in PATH" >&2
    exit 1
  fi
}

read_settings() {
  if [ -f "$SETTINGS_FILE" ]; then
    cat "$SETTINGS_FILE"
  else
    echo '{}'
  fi
}

build_command() {
  local dest_path="$1"
  # Normalize to forward slashes (Windows compat)
  local normalized
  normalized="$(echo "$dest_path" | sed 's|\\|/|g')"
  echo "node \"${normalized}\" # claude-context-window"
}

install() {
  ensure_deps

  if [ ! -f "$STATUSLINE_SRC" ]; then
    echo "Error: statusline.js not found at ${STATUSLINE_SRC}" >&2
    exit 1
  fi

  mkdir -p "$CLAUDE_DIR"
  cp "$STATUSLINE_SRC" "$STATUSLINE_DEST"

  local settings
  settings="$(read_settings)"

  # Check for existing non-ours statusLine (skip with --force)
  if [ "${1:-}" != "--force" ]; then
    local existing_cmd
    existing_cmd="$(echo "$settings" | jq -r '.statusLine.command // ""')"
    if [ -n "$existing_cmd" ] && ! echo "$existing_cmd" | grep -q "$MARKER"; then
      echo "Warning: a statusLine is already configured by another tool." >&2
      echo "Existing command: ${existing_cmd}" >&2
      echo "Use --force to overwrite, or remove it manually from ${SETTINGS_FILE}" >&2
      rm -f "$STATUSLINE_DEST"
      exit 1
    fi
  fi

  local cmd
  cmd="$(build_command "$STATUSLINE_DEST")"
  local new_settings
  new_settings="$(echo "$settings" | jq \
    --arg cmd "$cmd" \
    '.statusLine = {"type": "command", "command": $cmd, "padding": 0}')"

  echo "$new_settings" > "$SETTINGS_FILE"

  printf "\n${GREEN}✓ claude-context-window installed${RESET}\n"
  printf "  Script: %s\n" "$STATUSLINE_DEST"
  printf "  Config: %s\n" "$SETTINGS_FILE"
  printf "\n${DIM}Restart Claude Code to activate.${RESET}\n\n"
}

case "${1:-}" in
  --force)   install "--force" ;;
  --help|-h)
    echo "Usage: $0 [--force]"
    echo "  --force    Overwrite existing statusLine from another tool"
    ;;
  "")        install ;;
  *)
    echo "Usage: $0 [--force]" >&2
    exit 1
    ;;
esac
