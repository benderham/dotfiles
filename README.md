# Dotfiles Setup

This repository contains the dotfiles for my macOS system. It includes configurations for terminal, shell, and various development tools.

## Installation

### Remote Installation

You can run the setup script directly from this repository using `curl`. This will:

- Clone the dotfiles repository if not already cloned
- Install Homebrew if it is not already installed
- Install dependencies from the Brewfile
- Symlink dotfiles to their correct locations using GNU Stow

To execute the script remotely:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/benderham/dotfiles/main/setup.sh)"
```

### Local Installation

If you've already cloned the repository, you can run the setup script locally:

```bash
# Make the script executable first
chmod +x ~/.dotfiles/setup.sh

# Run the script
~/.dotfiles/setup.sh
```

### Manual Steps

If any issues occur while running the script, or if you prefer a manual setup, follow these steps:

#### Install Homebrew (if not already installed)

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

#### Install Brewfile dependencies

```bash
# Navigate to the dotfiles directory
cd ~/.dotfiles

# Install dependencies from the Brewfile (using the specific file path)
brew bundle --file=~/.dotfiles/Brewfile
```

#### Symlink the dotfiles using GNU Stow

```bash
cd ~/.dotfiles
stow home_files
```

### Updating Brewfile

Current packages in the `Brewfile`:

- `bat` - `cat` clone with syntax highlighting and Git integration.
- `curl` - Command-line tool for transferring data with URLs.
- `doggo` - Modern DNS lookup client for quick DNS queries.
- `eza` - Modern replacement for `ls` with icons and git info.
- `fd` - Fast, user-friendly alternative to `find`.
- `fzf` - Fuzzy finder for files, command history, and more.
- `gh` - GitHub CLI for issues, PRs, and repo workflows.
- `git` - Distributed version control system.
- `imagemagick` - Tools for image conversion and manipulation.
- `lazygit` - Terminal UI for common Git operations.
- `mas` - CLI for installing apps from the Mac App Store.
- `mise` - Runtime/version manager for languages and tools.
- `ripgrep` - Extremely fast recursive text search (`rg`).
- `starship` - Cross-shell, customizable prompt.
- `stow` - Symlink farm manager for dotfiles.
- `trash` - CLI that moves files to Trash instead of deleting permanently.
- `wget` - Non-interactive network downloader.
- `yazi` - Fast terminal file manager.
- `zoxide` - Smarter `cd` command that learns your habits.
- `zsh` - Z shell.

Current apps in the `Brewfile` (`cask`):

- `figma` - Collaborative interface design and prototyping app.
- `firefox@developer-edition` - Firefox build with developer-focused tools and features.
- `font-fira-code-nerd-font` - Fira Code Nerd Font with programming ligatures and patched icons.
- `ghostty` - Fast, modern GPU-accelerated terminal emulator.
- `google-chrome` - Google’s web browser.
- `insomnia` - HTTP and GraphQL Client.
- `logi-options+` - Logitech utility for customizing supported mice, keyboards, and device settings.
- `logitune` - Logitech app for managing webcams, headsets, and video collaboration device settings.
- `notion` - All-in-one workspace for notes, docs, and project management.
- `notion-calendar` - Calendar app integrated with Notion workflows.
- `raycast` - Spotlight-style launcher and productivity command palette.
- `slack` - Team communication and collaboration app.
- `visual-studio-code` - Code editor for development workflows.

Current App Store apps in the `Brewfile` (`mas`):

- `Harvest` (`506189836`) - Time tracking app for logging work and billing hours.

To update the Brewfile with any new dependencies, run:

```bash
brew bundle dump --force --no-vscode --file=~/.dotfiles/Brewfile
```

To remove any installed packages not listed in the Brewfile, run:

```bash
brew bundle cleanup --force --file=~/.dotfiles/Brewfile
```

This command will uninstall all packages, casks, or taps not defined in the `Brewfile`, keeping your system aligned with the `Brewfile` contents.

**Note:** VS Code extensions are excluded from the Brewfile (via `--no-vscode` flag) and should be managed through VS Code's built-in Settings Sync feature instead.

## 1Password Setup

Optional setup for using 1Password as your SSH agent and for Git commit signing.

### Automatic Setup

Run the setup script:

```bash
~/.dotfiles/scripts/setup-1password.sh
```

This will:

- Configure SSH to use 1Password agent
- Set up Git commit signing (requires 1Password CLI)

### Requirements

- 1Password app with SSH agent enabled
- For Git signing: 1Password CLI (`brew install --cask 1password/tap/1password-cli`)
- SSH key stored in 1Password (customize script if item name isn't "GitHub key")
