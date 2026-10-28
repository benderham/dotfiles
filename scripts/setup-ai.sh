#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

if [ "$#" -ne 1 ] || [[ ! "$1" =~ ^(cursor|claude-code|codex)$ ]]; then
	error "Usage: $0 cursor|claude-code|codex"
	exit 2
fi

agent="$1"
scripts="$(cd "$(dirname "$0")" && pwd)"

"$scripts/install-ai-context.sh" --agent "$agent"
"$scripts/install-rtk.sh" --agent "$agent"
"$scripts/install-skills.sh" --agent "$agent"
"$scripts/install-plugins.sh" --agent "$agent"
