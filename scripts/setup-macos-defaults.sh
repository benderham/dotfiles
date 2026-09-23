#!/bin/bash
set -euo pipefail

source "$(cd "$(dirname "$0")" && pwd)/lib.sh"

info "Applying macOS defaults..."

# -- General / launch services -----------------------------------------------
# Skip the "Are you sure you want to open this app?" prompt for downloaded binaries
defaults write com.apple.LaunchServices LSQuarantine -bool false

# -- Keyboard ----------------------------------------------------------------
defaults write NSGlobalDomain KeyRepeat -int 2
defaults write NSGlobalDomain InitialKeyRepeat -int 15
defaults write NSGlobalDomain ApplePressAndHoldEnabled -bool false
# Tab through all controls in dialogs, not just text fields
defaults write NSGlobalDomain AppleKeyboardUIMode -int 3

# -- Dock --------------------------------------------------------------------
defaults write com.apple.dock tilesize -int 37
defaults write com.apple.dock show-recents -bool false
# Auto-hide the Dock. On OLED a permanent bright Dock strip is a burn-in risk.
defaults write com.apple.dock autohide -bool true

# -- Appearance (tuned for OLED) ---------------------------------------------
# Force Dark permanently. On OLED, dark pixels are physically off: less power,
# no backlight bleed, and far less burn-in than a bright Light-mode raster.
# AppleInterfaceStyleSwitchesAutomatically must be false, or the scheduler
# overrides the fixed style.
defaults write NSGlobalDomain AppleInterfaceStyle -string "Dark"
defaults write NSGlobalDomain AppleInterfaceStyleSwitchesAutomatically -bool false

# Graphite (grey) accent instead of a saturated colour. Applies after logout.
defaults write NSGlobalDomain AppleAccentColor -int -1
defaults write NSGlobalDomain AppleAquaColorVariant -int 6

# Solid (non-translucent) menus/Dock render true black instead of grey.
# Note: com.apple.universalaccess is cached by the accessibility daemon, so
# this and reduceMotion below only take effect after a logout/login.
defaults write com.apple.universalaccess reduceTransparency -bool true
defaults write com.apple.universalaccess reduceMotion -bool true

# Auto-hide the menu bar — removes the other permanent bright strip.
defaults write NSGlobalDomain _HIHideMenuBar -bool true

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

# Stop polluting network and USB drives with .DS_Store
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true

# -- Screenshots -------------------------------------------------------------
mkdir -p "$HOME/Downloads"
defaults write com.apple.screencapture location -string "$HOME/Downloads"

# -- Software updates --------------------------------------------------------
# Daily check + auto-install for App Store apps
defaults write com.apple.SoftwareUpdate ScheduleFrequency -int 1
defaults write com.apple.commerce AutoUpdate -bool true

# -- Apply -------------------------------------------------------------------
killall Dock 2>/dev/null || true
killall Finder 2>/dev/null || true
killall SystemUIServer 2>/dev/null || true

success "macOS defaults applied."
