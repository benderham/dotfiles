#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

info "Setting up skills..."

# Curated global skills, installed with the `skills` CLI (via npx) into the
# agents present. Format: "owner/repo|comma,separated,skill,names".
#
# This is the source of truth: skills track their source repo's latest, like the
# agent plugins do. There is no version lockfile (the CLI dropped the global
# lockfile model). Add or remove skills by editing this list and re-running.
SKILLS=(
	"antfu/skills|pnpm,vite,vitest"
	"webpro/skills|configure-knip,optimize-javascript"
	"vercel-labs/agent-skills|vercel-react-best-practices,vercel-composition-patterns,vercel-react-view-transitions,web-design-guidelines"
	"vercel-labs/agent-browser|agent-browser"
	"addyosmani/web-quality-skills|accessibility,core-web-vitals,performance,seo,web-quality-audit,best-practices"
	"GoogleChrome/modern-web-guidance|modern-web-guidance"
	"cursor/plugins|thermo-nuclear-code-quality-review"
)

# Target whichever agents are installed.
agents=""
command_exists claude && agents="claude-code"
command_exists codex && agents="${agents:+$agents,}codex"
if [ -z "$agents" ]; then
	warn "Neither claude nor codex found on PATH. Skipping skills."
	warn "Install an agent, then re-run: ~/.dotfiles/scripts/install-skills.sh"
	exit 0
fi

# The skills CLI runs via npx, which needs Node (provided by mise).
if command_exists mise; then
	eval "$(mise activate bash)" 2>/dev/null || true
	eval "$(mise hook-env)" 2>/dev/null || true
	mise install >/dev/null 2>&1 || true
fi
if ! command_exists npx; then
	warn "npx not available (need Node via mise). Open a new shell or run 'mise install', then re-run."
	exit 0
fi

info "Installing curated skills for: $agents"
for entry in "${SKILLS[@]}"; do
	repo="${entry%%|*}"
	names="${entry##*|}"
	info "[$repo] $names"
	npx --yes skills add -g "$repo" -s "$names" -a "$agents" -y \
		|| warn "[$repo] some skills may have failed. List current names: npx skills add -g $repo -l"
done

success "Skills setup complete."
