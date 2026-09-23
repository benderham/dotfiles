#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Install hook-driven / marketplace plugins for whichever agents are present.
# These can't live in the skills lockfile: they ship SessionStart hooks,
# statuslines, and slash commands that a bare SKILL.md install would drop.
# Each entry is "marketplace_source|plugin@marketplace".

PLUGINS=(
	"DietrichGebert/ponytail|ponytail@ponytail"                       # always-on minimalism
	"JuliusBrussee/caveman|caveman@caveman"                           # always-on terse prose
	"anthropics/claude-plugins-official|mattpocock-skills@claude-plugins-official"  # engineering/productivity skills
)

# install_for <agent-cmd> <install-subcommand>
install_for() {
	local agent="$1" sub="$2" entry mkt plugin
	for entry in "${PLUGINS[@]}"; do
		mkt="${entry%%|*}"
		plugin="${entry##*|}"
		info "[$agent] $plugin"
		"$agent" plugin marketplace add "$mkt" || warn "[$agent] adding marketplace $mkt may have failed (already added?)."
		"$agent" plugin "$sub" "$plugin" || warn "[$agent] installing $plugin may need manual trust, or isn't supported for this agent."
	done
}

installed_any=false

if command_exists claude; then
	info "Installing plugins for Claude Code..."
	install_for claude install
	installed_any=true
fi

if command_exists codex; then
	info "Installing plugins for Codex..."
	install_for codex add
	info "In Codex, run '/hooks' to review and trust plugin lifecycle hooks, then start a new thread."
	installed_any=true
fi

if [ "$installed_any" = false ]; then
	warn "Neither claude nor codex found on PATH. Skipping plugins."
	warn "Install an agent, then re-run: ~/.dotfiles/scripts/install-plugins.sh"
	exit 0
fi

success "Plugin setup complete."
