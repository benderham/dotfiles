#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

info "Applying macOS defaults..."

# -- Keyboard / text ---------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false

# Tab through all controls in dialogs, not just text fields
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# Disable smart punctuation. Particularly useful when working with code.
defaults write NSGlobalDomain NSAutomaticQuoteSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticDashSubstitutionEnabled -bool false
defaults write NSGlobalDomain NSAutomaticPeriodSubstitutionEnabled -bool false

# -- Trackpad ----------------------------------------------------------------

# Tap with one finger to click
defaults write com.apple.AppleMultitouchTrackpad Clicking -bool true
defaults -currentHost write NSGlobalDomain com.apple.mouse.tapBehavior -int 1
defaults write NSGlobalDomain com.apple.mouse.tapBehavior -int 1

# Three-finger drag
# Accessibility setting: 1 = three-finger drag
defaults write com.apple.AppleMultitouchTrackpad TrackpadThreeFingerDrag -bool true
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad TrackpadThreeFingerDrag -bool true

# Configure related drag settings to avoid conflicts
defaults write com.apple.AppleMultitouchTrackpad Dragging -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad Dragging -bool false
defaults write com.apple.AppleMultitouchTrackpad DragLock -bool false
defaults write com.apple.driver.AppleBluetoothMultitouch.trackpad DragLock -bool false


# -- Dock --------------------------------------------------------------------
defaults write com.apple.dock tilesize -int 48
defaults write com.apple.dock show-recents -bool false

# Auto-hide persistent UI when not in use. Particularly useful with OLED
# displays.
defaults write com.apple.dock autohide -bool true

# Remove the delay before the hidden Dock appears, while retaining a short
# animation so it doesn't feel abrupt.
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.25

# Minimise windows into their application icon instead of creating additional
# Dock items.
defaults write com.apple.dock minimize-to-application -bool true

# -- Mission Control / Spaces ------------------------------------------------
# Keep Spaces in a predictable order rather than rearranging them based on
# recent use.
defaults write com.apple.dock mru-spaces -bool false

# -- Hot Corners -------------------------------------------------------------

# Bottom-right: Show Desktop
defaults write com.apple.dock wvous-br-corner -int 4
defaults write com.apple.dock wvous-br-modifier -int 0

# -- Appearance --------------------------------------------------------------
# Prefer permanent Dark Mode. This also reduces persistent bright UI regions
# when using the OLED ultrawide. AppleInterfaceStyleSwitchesAutomatically must
# be false, or the scheduler overrides the fixed style.
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool false

# Graphite (grey) accent instead of a saturated colour. Applies after logout.
defaults write NSGlobalDomain AppleAccentColor -int -1
defaults write NSGlobalDomain AppleAquaColorVariant -int 6

# Disable font smoothing for crisp, thin text. Preferred on Retina and the OLED
# ultrawide. Font smoothing is read per-host (keyed to the machine's hardware
# UUID), so set both scopes to keep every machine consistent. Applies after
# logout.
defaults write NSGlobalDomain AppleFontSmoothing -int 0
defaults -currentHost write -g AppleFontSmoothing -int 0

# Solid (non-translucent) menus and Dock.
# Note: com.apple.universalaccess is cached by the accessibility daemon, so
# this and reduceMotion below only take effect after a logout/login.
# com.apple.universalaccess is TCC-protected: `defaults write` fails unless the
# terminal running setup has Full Disk Access. Don't let that abort the phase.
ua_ok=true
defaults write com.apple.universalaccess reduceTransparency -bool true 2>/dev/null || ua_ok=false
defaults write com.apple.universalaccess reduceMotion -bool true 2>/dev/null || ua_ok=false
if [ "$ua_ok" = false ]; then
	warn "Skipped reduce transparency/motion: com.apple.universalaccess needs Full Disk Access."
	warn "Grant your terminal Full Disk Access (System Settings > Privacy & Security), then re-run this phase."
fi

# Auto-hide the menu bar when not in use.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

# -- Menu bar ----------------------------------------------------------------
# Always show battery percentage alongside the battery icon.
defaults write com.apple.controlcenter BatteryShowPercentage -bool true

# -- Finder ------------------------------------------------------------------
defaults write com.apple.finder AppleShowAllExtensions -bool true
defaults write com.apple.finder ShowPathbar -bool true
defaults write com.apple.finder ShowStatusBar -bool true

# Column view by default
defaults write com.apple.finder FXPreferredViewStyle -string "clmv"

# Folders on top when sorting by name
defaults write com.apple.finder _FXSortFoldersFirst -bool true

# When searching, default to the current folder (not "This Mac")
defaults write com.apple.finder FXDefaultSearchScope -string "SCcf"

# New Finder windows open at $HOME
defaults write com.apple.finder NewWindowTarget -string "PfHm"

# Don't warn when changing a file extension
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false

# Stop polluting network and USB drives with .DS_Store
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# -- Save / print dialogs ----------------------------------------------------
# Show the full filesystem browser instead of the compact save dialog.
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode -bool true
defaults write NSGlobalDomain NSNavPanelExpandedStateForSaveMode2 -bool true

# Show the expanded print dialog by default.
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint -bool true
defaults write NSGlobalDomain PMPrintingExpandedStateForPrint2 -bool true

# -- Screenshots -------------------------------------------------------------
mkdir -p "$HOME/Screenshots"
defaults write com.apple.screencapture location -string "$HOME/Screenshots"

# -- App Store ---------------------------------------------------------------
# Automatically install updates for App Store applications.
defaults write com.apple.commerce AutoUpdate -bool true

# -- Apply -------------------------------------------------------------------
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

success "macOS defaults applied."
