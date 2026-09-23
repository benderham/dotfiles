#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

# Install hook-driven / marketplace plugins for whichever agents are present.
# These can't live in the skills lockfile: they ship SessionStart hooks,
# statuslines, and slash commands that a bare SKILL.md install would drop.
#
# Install paths differ per agent and per plugin:
#   - Claude Code: native marketplace plugins for all three.
#   - Codex: ponytail has a native plugin; caveman and mattpocock have no native
#     Codex plugin yet, so they go in via the cross-agent skills registry
#     (`npx skills add <repo> -a codex`).

# -- Claude Code --------------------------------------------------------------
# "marketplace_source|plugin@marketplace"
CLAUDE_PLUGINS=(
	"DietrichGebert/ponytail|ponytail@ponytail"
	"JuliusBrussee/caveman|caveman@caveman"
	"anthropics/claude-plugins-official|mattpocock-skills@claude-plugins-official"
)

installed_any=false

if command_exists claude; then
	info "Installing plugins for Claude Code..."
	for entry in "${CLAUDE_PLUGINS[@]}"; do
		mkt="${entry%%|*}"
		plugin="${entry##*|}"
		info "[claude] $plugin"
		claude plugin marketplace add "$mkt" || warn "[claude] adding marketplace $mkt may have failed (already added?)."
		claude plugin install "$plugin" || warn "[claude] installing $plugin may need manual trust: run '/plugin install $plugin' in Claude Code."
	done
	installed_any=true
fi

# -- Codex --------------------------------------------------------------------
if command_exists codex; then
	info "Installing plugins for Codex..."

	# ponytail ships a native Codex plugin.
	info "[codex] ponytail@ponytail"
	codex plugin marketplace add DietrichGebert/ponytail || warn "[codex] adding ponytail marketplace may have failed (already added?)."
	codex plugin add ponytail@ponytail || warn "[codex] installing ponytail may have failed."

	# caveman and mattpocock have no native Codex plugin — use the skills registry.
	if command_exists npx; then
		info "[codex] caveman (via skills registry)"
		npx --yes skills add JuliusBrussee/caveman -a codex || warn "[codex] caveman install may have failed."
		info "[codex] mattpocock (via skills registry)"
		npx --yes skills add mattpocock/skills -a codex || warn "[codex] mattpocock install may have failed."
	else
		warn "[codex] npx not on PATH — skipping caveman/mattpocock. Ensure node (mise) is active and re-run."
	fi

	info "In Codex, run '/hooks' to review and trust plugin lifecycle hooks, then start a new thread."
	installed_any=true
fi

if [ "$installed_any" = false ]; then
	warn "Neither claude nor codex found on PATH. Skipping plugins."
	warn "Install an agent, then re-run: ~/.dotfiles/scripts/install-plugins.sh"
	exit 0
fi

success "Plugin setup complete."
