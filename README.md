# Dotfiles

macOS dotfiles managed with [GNU Stow](https://www.gnu.org/software/stow/).
Designed to be portable across work and personal machines: identity is split
via git `includeIf`, GUI apps are opt-in, and per-machine tweaks live in an
untracked local file.

## Quick start

Fresh Mac:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/benderham/dotfiles/main/setup.sh)"
```

Repo already cloned:

```bash
~/.dotfiles/setup.sh
```

## How it works

`setup.sh` runs each phase as a separate script under `scripts/`. Any script can be re-run on its own.

Only Phase 1 (Homebrew) is mandatory — everything else depends on the tools it installs. Every other phase prompts before running: hit Enter to accept (the default) or answer `n` to skip. That makes re-running setup for a single phase painless — just skip past the ones you don't need.

| Phase | Script                    | Optional? | What it does                                              |
| ----- | ------------------------- | --------- | --------------------------------------------------------- |
| 1     | `install-homebrew.sh`     | no        | Install or update Homebrew                                |
| 2     | `install-brewfile.sh`     | yes       | Required Brewfile, then `fzf` picker for optional entries |
| 3     | `install-stow.sh`         | yes       | Symlink configs from top-level dirs into `$HOME`          |
| 4     | `setup-git.sh`            | no        | Prompt (default no) to add a work git identity            |
| 5     | `install-bat-themes.sh`   | yes       | Download Catppuccin theme, rebuild bat cache              |
| 6     | `setup-macos-defaults.sh` | yes       | macOS defaults (appearance/OLED, Dock, Finder, keyboard)  |
| 7     | `setup-1password.sh`      | yes       | SSH agent + Git signing via 1Password                     |
| 8     | `install-rtk.sh`          | yes       | Link rtk filters, wire rtk into Claude Code + Codex        |
| 9     | `install-skills.sh`       | yes       | Restore pinned Claude skills from the lockfile             |
| 10    | `install-plugins.sh`      | yes       | Install agent plugins (ponytail, caveman, mattpocock) per agent |

Failed runs preserve `setup-YYYYMMDD-HHMMSS.log` in the repo root and print the path. Successful runs clean up.

## Brewfile

`Brewfile` is bootstrap-only — just the CLI tools needed for a working shell and to run the installer itself (`git`, `stow`, `mise`, `zsh`, `starship`, `fzf`, `zoxide`, `eza`, `bat`, `ripgrep`, `fd`, `mas`). Everything else — GUI apps, fonts, and situational CLIs — lives in `Brewfile.optional` and is chosen from an `fzf` checklist picker.

```bash
~/.dotfiles/scripts/install-brewfile.sh         # required + picker
~/.dotfiles/scripts/install-brewfile.sh --all   # required + all optional
~/.dotfiles/scripts/install-brewfile.sh --none  # required only
```

`Brewfile.optional` format:

```text
brew:doggo                       # modern DNS client
cask:ghostty                     # terminal emulator
tap:owner/repo
mas:Harvest=506189836
```

Selections feed into `brew bundle --file=-`.

### Maintenance

```bash
# Remove anything not in Brewfile (ignores Brewfile.optional)
brew bundle cleanup --force --file=~/.dotfiles/Brewfile
```

> **Warning:** avoid `brew bundle dump --file=~/.dotfiles/Brewfile` — it rewrites the
> file from _everything_ currently installed, which re-bloats the bootstrap-only
> `Brewfile` and undoes the split. The `bdump` alias dumps to `/tmp/Brewfile.dump`
> instead; cherry-pick anything new into `Brewfile.optional` by hand.

> **Warning:** `brew bundle cleanup` only consults the required `Brewfile`, so it
> will uninstall everything you picked from `Brewfile.optional`. Treat it as a reset
> back to the bootstrap baseline — re-run the picker (or `install-brewfile.sh --all`)
> to restore your optional packages afterwards.

VS Code extensions sync through Settings Sync, hence `--no-vscode`.

## Adding a new config

Each top-level dir is a stow package, except `scripts`, `.git`, and `.stow-backups`:

```bash
mkdir -p newtool/.config/newtool
echo "my config" > newtool/.config/newtool/config.toml
stow -t ~ newtool
git add newtool && git commit -m "feat: add newtool config"
```

## Machine-specific config

Anything that should only run on one machine (per-machine tool inits, PATH tweaks,
work-only aliases) goes in `~/.config/zsh/.zshrc.local`, which `.zshrc` sources last and
`.gitignore` keeps untracked. Bootstrap it from the tracked template:

```bash
cp ~/.config/zsh/.zshrc.local.example ~/.config/zsh/.zshrc.local
```

## Git identity

The default identity is **per machine**, chosen by `setup-git.sh` (Phase 4), which
prompts defaulting to **no**:

- **Personal machine** (answer no): personal identity is the default everywhere —
  personal email + personal 1Password signing (`git/.gitconfig-personal` +
  `~/.gitconfig-1password-ssh`). No work file exists.
- **Work machine** (answer yes): the script writes a **gitignored**
  `~/.gitconfig-machine` that makes **work the default** on that machine (work email,
  optional work signing key), and scopes personal — including 1Password signing — to
  repos under `~/Sites/Personal/`.

So a work laptop never signs work commits with your personal 1Password key and never
falls back to your personal email; and no work details are ever committed to this repo.

Re-run any time (it can also revert a machine back to the personal default):

```bash
~/.dotfiles/scripts/setup-git.sh
```

## 1Password

`setup-1password.sh` (optional) writes:

- 1Password SSH agent socket into `~/.ssh/config`
- `~/.gitconfig-1password-ssh` for SSH-based commit signing (sourced by the main gitconfig)

Requires the 1Password app with SSH agent enabled, the 1Password CLI, and an SSH key item named `GitHub key`.

## Skills

A curated set of Claude skills is version-controlled here for reproducibility across
machines. The lockfile (`skills/.local/state/skills/.skill-lock.json`) is stowed to
`~/.local/state/skills/.skill-lock.json` and pins each skill to a source repo, so any
machine restores the same set.

### Install

`install-skills.sh` (Phase 9) activates mise, prepares `pnpm` via corepack, and runs the
restore:

```bash
~/.dotfiles/scripts/install-skills.sh
# or directly:
pnpm dlx skills experimental_install
```

### Usage

```bash
pnpm dlx skills experimental_install   # restore everything in the lockfile
pnpm dlx skills add <owner>/<repo>     # add a skill (updates the lockfile)
pnpm dlx skills                        # interactive picker / update
```

After adding or updating skills, commit the changed lockfile:

```bash
git add skills/.local/state/skills/.skill-lock.json && git commit -m "chore: update skills"
```

> **Pinned, not auto-updated.** The lockfile trades automatic freshness for
> reproducibility — you get the same skills on every machine, and update deliberately by
> re-running the restore (which re-pins). This is separate from Claude Code **plugins**,
> which update on their own. Don't manage the same skill via both a plugin and this
> lockfile, or it loads twice. First-party/Anthropic plugins (e.g. cloudflare, dataviz)
> aren't GitHub skills and stay as plugins.

## Agent plugins

Some tools are **plugins**, not plain skills — they ship SessionStart hooks (always-on
activation), statuslines, and slash commands that a bare `SKILL.md` install would drop. So
they can't live in the skills lockfile; `install-plugins.sh` (Phase 10) installs them
per-agent via each agent's plugin CLI, for whichever of `claude`/`codex` is present:

| Plugin | Marketplace | Why a plugin |
| --- | --- | --- |
| ponytail | `DietrichGebert/ponytail` | always-on minimalism (hook + statusline + commands) |
| caveman | `JuliusBrussee/caveman` | always-on terse prose (hook) |
| mattpocock-skills | `anthropics/claude-plugins-official` | engineering/productivity skills collection |

```bash
~/.dotfiles/scripts/install-plugins.sh   # installs for claude and/or codex, whichever exist
```

Claude Code uses `claude plugin install <plugin>@<marketplace>`; Codex uses `codex plugin
add …`. Each is attempted with `|| warn`, so an agent that doesn't support a given plugin
skips cleanly.

> Lifecycle hooks need `node` on PATH (mise provides it). Claude Code may require confirming
> a trust prompt — if the CLI can't auto-accept, run `/plugin install <plugin>@<marketplace>`
> in Claude Code. In Codex, run `/hooks` to trust hooks after install.

## rtk

[rtk](https://www.rtk-ai.app/) is a token-optimizing CLI proxy for AI coding agents — it
trims noisy tool output to cut token spend. It's an optional Brewfile entry (`brew:rtk`);
pick it in the picker.

`install-rtk.sh` (Phase 8) is idempotent:

- Symlinks the tracked global filters (`rtk/filters.toml`) into
  `~/Library/Application Support/rtk/filters.toml`.
- Wires rtk into **Claude Code** via `rtk init -g --auto-patch`, only if `claude` is installed.
- Wires rtk into **Codex** via `rtk init -g --codex`, only if `codex` is installed.

```bash
~/.dotfiles/scripts/install-rtk.sh   # re-run any time; no-ops if already set up
```

> `rtk` is intentionally **not** a stow package. Its config dir also holds runtime data
> (`history.db`), so stow would fold that into the repo. The script symlinks only
> `filters.toml`; the hook/`RTK.md`/agent-config artifacts are regenerated by `rtk init`,
> so they aren't tracked.

## macOS defaults

`setup-macos-defaults.sh` (optional) sets:

- **Appearance (tuned for OLED):** force Dark mode permanently (dark pixels are physically off — less power, no burn-in); Graphite (grey) accent colour; disable font smoothing for crisp text (set in both scopes since it's read per-host); reduce transparency (solid black menus/Dock instead of grey); reduce motion; auto-hide the Dock and menu bar to remove the two permanent bright strips
- Finder: show extensions, path bar, status bar; column view; folders on top; search current folder; new windows open at `$HOME`; no `.DS_Store` on network/USB
- Dock: `tilesize=37`, hide recent apps, auto-hide
- Keyboard: fast key repeat (2/15), no press-and-hold accent picker, full keyboard access in dialogs
- Launch Services: no "Are you sure?" prompt for downloaded apps
- Screenshots saved to `~/Downloads`
- App Store: daily update check, auto-install

> **Note:** reduce transparency and reduce motion write to `com.apple.universalaccess`,
> which the accessibility daemon caches. They only take effect after a **logout/login**.
> The rest apply immediately via `killall Dock`/`Finder`/`SystemUIServer`.
