#!/bin/bash
set -euo pipefail

# Set up a machine-specific work git identity.
#
# The main ~/.gitconfig applies your personal identity globally and includes
# ~/.gitconfig-work only for repos under ~/Sites/Work/. That work file is
# gitignored and lives outside the repo, so work details never get committed to
# this personal repo. This script creates it — only on a work machine.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

WORK_CONFIG="$HOME/.gitconfig-work"
WORK_DIR="$HOME/Sites/Work"

# Default NO: a personal machine is the common case and should stay clean.
read -r -p "$(printf "${YELLOW}? Is this a work machine (set up a work git identity)? [y/N] ${NC}")" reply
if [[ ! "$reply" =~ ^[Yy] ]]; then
	info "Skipping work git identity. This machine uses your personal identity only."
	exit 0
fi

if [ -f "$WORK_CONFIG" ]; then
	info "Existing work identity:"
	sed 's/^/  /' "$WORK_CONFIG"
	read -r -p "$(printf "${YELLOW}? Overwrite %s? [y/N] ${NC}" "$WORK_CONFIG")" ow
	[[ "$ow" =~ ^[Yy] ]] || { info "Keeping existing work identity."; exit 0; }
fi

read -r -p "Work email: " work_email
if [ -z "$work_email" ]; then
	error "No email entered. Aborting without changes."
	exit 1
fi

cat > "$WORK_CONFIG" <<EOF
# Work identity — applied only to repos under $WORK_DIR (via ~/.gitconfig
# includeIf). Machine-specific and gitignored; not committed to the dotfiles.
[user]
  email = $work_email
EOF

success "Created $WORK_CONFIG."
info "Applies to repos under $WORK_DIR/ — clone work repos there."
