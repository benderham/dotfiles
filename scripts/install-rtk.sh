#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

DOTFILES="$(dotfiles_root)"
agent=""
if [ "${1:-}" = "--agent" ] && [ -n "${2:-}" ]; then
	agent="$2"
	shift 2
fi
if [ "$#" -ne 0 ] || { [ -n "$agent" ] && [[ ! "$agent" =~ ^(cursor|claude-code|codex)$ ]]; }; then
	error "Usage: $0 [--agent cursor|claude-code|codex]"
	exit 2
fi

# rtk (Rust Token Killer) — token-optimizing CLI proxy for AI coding agents.
# This phase:
#   1. Symlinks the tracked global filters into rtk's config dir.
#   2. Wires rtk into Claude Code, Codex, or Cursor.
# Steps 2 and 3 are idempotent — `rtk init` no-ops anything already in place.

if ! command_exists rtk; then
	warn "rtk not found. Skipping rtk setup."
	warn "Pick 'rtk' in the Brewfile picker, then re-run this script${agent:+ --agent $agent}."
	exit 0
fi

# -- Global filters ------------------------------------------------------------
# rtk's config dir also holds runtime data (history.db), so we symlink only the
# tracked filters.toml rather than managing the whole dir via stow.

RTK_CONFIG_DIR="$HOME/Library/Application Support/rtk"
RTK_FILTERS_SRC="$DOTFILES/rtk/filters.toml"
RTK_FILTERS_DEST="$RTK_CONFIG_DIR/filters.toml"

mkdir -p "$RTK_CONFIG_DIR"

# Back up a pre-existing real file before replacing it with our symlink.
if [ -e "$RTK_FILTERS_DEST" ] && [ ! -L "$RTK_FILTERS_DEST" ]; then
	info "Backing up existing filters.toml -> filters.toml.bak"
	mv "$RTK_FILTERS_DEST" "$RTK_FILTERS_DEST.bak"
fi

ln -sfn "$RTK_FILTERS_SRC" "$RTK_FILTERS_DEST"
info "Linked global filters: $RTK_FILTERS_DEST -> $RTK_FILTERS_SRC"

# -- Claude Code ---------------------------------------------------------------
if { [ -z "$agent" ] && command_exists claude; } || [ "$agent" = "claude-code" ]; then
	info "Configuring rtk for Claude Code..."
	rtk init -g --auto-patch || warn "rtk Claude Code setup may have failed."
else
	info "Claude Code not installed — skipping rtk Claude Code wiring."
fi

# -- Codex ---------------------------------------------------------------------
if { [ -z "$agent" ] && command_exists codex; } || [ "$agent" = "codex" ]; then
	info "Configuring rtk for Codex..."
	rtk init -g --codex || warn "rtk Codex setup may have failed."
else
	info "Codex not installed — skipping rtk Codex wiring."
fi

# -- Cursor -------------------------------------------------------------------
if { [ -z "$agent" ] && command_exists cursor; } || [ "$agent" = "cursor" ]; then
	info "Configuring rtk for Cursor..."
	rtk init -g --agent cursor || warn "rtk Cursor setup may have failed."
fi

success "rtk setup complete."
