#!/bin/bash
set -euo pipefail

# Set up a machine-specific git identity.
#
# The tracked ~/.gitconfig defaults to your personal identity (personal email +
# personal 1Password signing). This script only does something on a WORK machine:
# it writes ~/.gitconfig-machine, which is included last so it wins — making work
# the default on that machine while keeping personal for repos under
# ~/Sites/Personal/. The file is gitignored, so no work details reach this repo.
#
# On a personal machine, answer no: no machine file, personal stays the default.

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

MACHINE_CONFIG="$HOME/.gitconfig-machine"
PERSONAL_DIR="$HOME/Sites/Personal"
OP_SSH_SIGN="/Applications/1Password.app/Contents/MacOS/op-ssh-sign"

# Default NO: a personal machine is the common case and should stay clean.
read -r -p "$(printf "${YELLOW}? Is this a work machine (make work the default identity)? [y/N] ${NC}")" reply
if [[ ! "$reply" =~ ^[Yy] ]]; then
	if [ -f "$MACHINE_CONFIG" ]; then
		read -r -p "$(printf "${YELLOW}? Remove existing %s and revert to personal default? [y/N] ${NC}" "$MACHINE_CONFIG")" rm_reply
		if [[ "$rm_reply" =~ ^[Yy] ]]; then
			rm -f "$MACHINE_CONFIG"
			success "Removed $MACHINE_CONFIG. This machine now defaults to your personal identity."
			exit 0
		fi
	fi
	info "Personal identity is the default on this machine. Nothing to do."
	exit 0
fi

if [ -f "$MACHINE_CONFIG" ]; then
	info "Existing machine identity:"
	sed 's/^/  /' "$MACHINE_CONFIG"
	read -r -p "$(printf "${YELLOW}? Overwrite %s? [y/N] ${NC}" "$MACHINE_CONFIG")" ow
	[[ "$ow" =~ ^[Yy] ]] || { info "Keeping existing machine identity."; exit 0; }
fi

read -r -p "Work email: " work_email
if [ -z "$work_email" ]; then
	error "No email entered. Aborting without changes."
	exit 1
fi

# -- Optional work commit signing ---------------------------------------------

signing_block=""
read -r -p "$(printf "${YELLOW}? Set up work commit signing? [y/N] ${NC}")" sign_reply
if [[ "$sign_reply" =~ ^[Yy] ]]; then
	read -r -p "Work SSH public key (e.g. 'ssh-ed25519 AAAA...'): " work_key
	if [ -z "$work_key" ]; then
		warn "No key entered — skipping signing setup."
	else
		program_line=""
		read -r -p "$(printf "${YELLOW}? Is this key managed by 1Password on this machine? [y/N] ${NC}")" op_reply
		if [[ "$op_reply" =~ ^[Yy] ]]; then
			program_line="	program = $OP_SSH_SIGN
"
		fi
		signing_block="	signingkey = $work_key
[gpg]
	format = ssh
[gpg \"ssh\"]
$program_line[commit]
	gpgsign = true
"
	fi
fi

cat > "$MACHINE_CONFIG" <<EOF
# Machine-specific git identity (work machine). Gitignored — no work details in
# the repo. Included last by ~/.gitconfig, so this is the default on this
# machine. Personal applies only under $PERSONAL_DIR/ (below).
[user]
	email = $work_email
$signing_block
# Personal identity for personal repos on this machine.
[includeIf "gitdir:$PERSONAL_DIR/**"]
	path = ~/.gitconfig-personal
[includeIf "gitdir:$PERSONAL_DIR/**"]
	path = ~/.gitconfig-1password-ssh
EOF

success "Created $MACHINE_CONFIG."
info "Work is now the default identity on this machine."
info "Personal identity applies only to repos under $PERSONAL_DIR/."
