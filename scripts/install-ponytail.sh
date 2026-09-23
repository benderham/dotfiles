#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Install the ponytail plugin (https://github.com/DietrichGebert/ponytail) for
# whichever agents are present on this machine. ponytail is a hook-driven plugin
# (always-on activation, statusline, /ponytail commands), so it can't live in the
# skills lockfile — it's installed per-agent via each agent's plugin CLI.
#
# ponytail's lifecycle hooks need `node` on PATH; mise provides it. Run this after
# the Brewfile/mise phases.

MARKETPLACE="DietrichGebert/ponytail"
PLUGIN="ponytail@ponytail"

installed_any=false

if command_exists claude; then
	info "Installing ponytail for Claude Code..."
	claude plugin marketplace add "$MARKETPLACE" || warn "Adding marketplace for Claude Code may have failed (already added?)."
	claude plugin install "$PLUGIN" || warn "Installing ponytail for Claude Code may need manual trust: run '/plugin install $PLUGIN' in Claude Code."
	installed_any=true
fi

if command_exists codex; then
	info "Installing ponytail for Codex..."
	codex plugin marketplace add "$MARKETPLACE" || warn "Adding marketplace for Codex may have failed (already added?)."
	codex plugin add "$PLUGIN" || warn "Installing ponytail for Codex may have failed."
	info "In Codex, run '/hooks' to review and trust ponytail's lifecycle hooks, then start a new thread."
	installed_any=true
fi

if [ "$installed_any" = false ]; then
	warn "Neither claude nor codex found on PATH. Skipping ponytail."
	warn "Install an agent, then re-run: ~/.dotfiles/scripts/install-ponytail.sh"
	exit 0
fi

success "ponytail setup complete."
