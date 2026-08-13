# dotfiles

Watch the walkthrough: https://youtu.be/5N-okeDdIuI

My personal Mac setup, managed with nix-darwin and home-manager.
One repo, one command, and a fresh Mac ends up configured the same way every time.

## Contributing / Using This Repo

These are my personal dotfiles, shared publicly so people can read them, learn from them, and fork them freely.
Feature requests and pull requests are not accepted here, and PRs are auto-closed.
If you find a bug, please open a GitHub Issue using the bug report template.

## What you get

Running the switch builds:

- System settings (dark mode, key repeat, dock, Finder, trackpad)
- Homebrew apps (casks and CLI tools, including VS Code Insiders)
- Nix user packages (ripgrep, fd, fzf, jq, lazygit, Neovim, pre-commit, gitleaks, Hack Nerd Font)
- Shell (zsh, aliases, starship prompt)
- Editor (Neovim config with the rose-pine moon theme)
- Terminal (WezTerm config with the rose-pine moon theme and dimmed unfocused windows)
- Agent configs (Claude, Codex, opencode all share one AGENTS.md)
- Optional Pi theme and local extensions, UI settings, a default model and model overrides, plus two deliberately pinned third-party Pi packages
- SSH server (Remote Login), key-only auth, for connecting from another machine on the LAN (e.g. VS Code Remote-SSH)
- Git identity, GitHub SSH auth, and commit signing, using a dedicated machine key pulled non-interactively from 1Password via a Service Account (no human required - this box runs unattended)

## Prerequisites

- Apple Silicon Mac, by default.
- Intel Mac: change one line.
  In `configuration.nix`, set `nixpkgs.hostPlatform = "x86_64-darwin";` (the comment right there tells you the same thing).

## Fresh-machine setup

On a brand new Mac, from a bare clone of this repo:

```sh
git clone https://github.com/kunchenguid/dotfiles.git
cd dotfiles
```

Before you run it: review "Make it yours" below.
Change the host label or CPU architecture if needed, and read the Homebrew cleanup warning.
`bootstrap.sh` applies the config to your machine, so do this first.

```sh
./bootstrap.sh
```

`bootstrap.sh` does five things, in order:

1. Installs Determinate Nix, if it isn't already installed.
2. Symlinks this repo to `~/.dotfiles`.
   This has to happen before the first build, because `home.nix` points at config files through `~/.dotfiles`.
3. Checks the `user` configured in `flake.nix` against your actual macOS username, and offers to fix it for you if they differ.
4. Runs the first `darwin-rebuild switch`.
   It fetches the `darwin-rebuild` tool from the nix-darwin 26.05 release branch, then applies this repo's locked flake config.
5. Installs the local git pre-commit hooks (gitleaks secret scanning). See CONTRIBUTING.md if you need the one-line manual fallback.

After that, `darwin-rebuild` exists and you're on the normal workflow below.

### Validate without applying

Once Nix is installed (`bootstrap.sh` step 1 handles that), you can check that the config builds without touching your system - handy when you have edited something:

```sh
nix flake check --no-build
nix build .#darwinConfigurations.mac.system --dry-run
```

If you renamed the host label in "Make it yours", substitute your label for `mac` in these commands.

## Daily use

Edit the config files in place, then apply:

```sh
./rebuild.sh
```

That's it.
No separate build-and-copy step.

## Make it yours

This repo is mine.
If you clone it, review these before you run `bootstrap.sh`:

- **Username**: run `./bootstrap.sh` (it detects your macOS username and offers to set it) OR change the single `user = "kunchen"` line in `flake.nix`.
  Everything else (`configuration.nix`, `home.nix`, home directory paths) is threaded from that one variable.
- **Host label** `"mac"`, in three places: `flake.nix` (the `darwinConfigurations."mac"` name), `rebuild.sh:5` (the `#mac` at the end of the flake reference), and `bootstrap.sh`'s first-switch command (also `#mac`).
  All three have to match.
- **CPU architecture**, `hostPlatform` in `configuration.nix` (see Prerequisites above).

**Git identity:** `user.name`/`email` aren't in this repo at all - they come from a `GIT_NAME`/`GIT_EMAIL` item in 1Password, materialized by `rebuild.sh` straight to `~/.config/git/config-local` (outside this repo, same as the SSH keys) and pulled in via `programs.git.includes`, so this public repo never hardcodes anyone's real name or email. `user.signingkey` points at `~/.ssh/id_ed25519_mac_signing`, which likewise doesn't exist until "GitHub SSH authentication & commit signing" below is done. If you clone this repo, add your own `GIT_NAME`/`GIT_EMAIL` item instead (see that section for the exact item shape), or just hardcode `programs.git.settings.user` in `home.nix` if you don't want the 1Password indirection.

**Homebrew cleanup warning:** `configuration.nix` sets `homebrew.onActivation.cleanup = "zap"`.
That means every time you switch, Homebrew removes any package or cask on your machine that isn't listed in the `brews` and `casks` arrays in `configuration.nix`.
If you already have Homebrew stuff installed that isn't in that list, the first switch will uninstall it.
Read through `brews` and `casks` before you run `bootstrap.sh` or `rebuild.sh` for the first time, and add anything you want to keep.

**About `herdr`:** it's in the `brews` list.
It's a real public Homebrew formula (`brew info herdr` finds it in homebrew-core, no tap needed), so it will install fine.
If you don't use it, just remove it from `brews` in your copy.

**About Claude Code:** it's installed via npm (`home.nix`'s npm-global activation script), not a Homebrew cask.
The Homebrew cask build carries a quarantine xattr that Apple System Policy suspends before it reaches `main`, hanging forever with no output.
npm is the supported install path until upstream fixes the cask.

**About the power settings:** `configuration.nix` sets `power.sleep.computer`/`power.sleep.harddisk` to `"never"` and enables `restartAfterPowerFailure`.
This machine runs 24/7 on mains power for unattended agent work, and macOS's default idle sleep (1 minute) killed runs mid-session.
`power.restartAfterFreeze` is left out on purpose, not by oversight: nix-darwin applies it with an unguarded `systemsetup -setRestartFreeze` in an activation script that runs under `set -e`, and restart-on-freeze is commonly unsupported on Apple Silicon, so an unsupported command there would abort `darwin-rebuild switch` outright.
Add it back only if you've confirmed the setting works on your hardware.
If you clone this repo for a laptop or a machine that should sleep normally, remove these before you switch - they will keep any machine awake and drawing power indefinitely.
Display sleep is deliberately left unmanaged (stays at the system default): it doesn't interrupt work, so there's no reason to disable it.
Power Nap is turned off separately, by the `system.activationScripts.postActivation` block right below the `power` attrset - nix-darwin has no declarative option for it at the pinned rev.
Deleting the `power` attrset alone will not restore Power Nap: remove that activation script too, and because activation scripts only ever apply a setting, re-enable it once by hand with `sudo pmset -a powernap 1`.

**Heads-up:**

- `home/AGENTS.md` is my personal agent policy, and `home.nix` installs it for Claude, Codex, and opencode.
  If you clone this repo, you'd silently inherit my agent instructions - edit or delete `home/AGENTS.md` if you don't want that.
- The `cc` and `co` shell aliases in `home.nix` are high-agency shortcuts: `claude --dangerously-skip-permissions` and `codex --full-auto`.
  They're convenient for me, but know what they do before you use them.

## Repo tour

- `flake.nix` - the entry point.
  Wires up nixpkgs, nix-darwin, home-manager, and nix-homebrew, and declares the `mac` machine.
- `configuration.nix` - system-level config: macOS defaults, Homebrew.
- `home.nix` - user-level config: shell, packages, prompt, and the symlinks described below.
- `rebuild.sh` - re-applies the config after the first switch.
  Run this every time you make a change.
- `home/` - the actual config files that get symlinked into place; the sections below explain the shared symlink model and Pi's narrower selective setup.

## How the symlinks work

The files under `home/` are the real files - editing them here is editing your live config, no rebuild needed to see the change in your editor.
`home.nix` uses `mkOutOfStoreSymlink` to point paths like `~/.config/nvim` straight at `home/.config/nvim` in this repo, so the two never drift out of sync.
You only run `./rebuild.sh` when you change something that isn't just a symlinked file, like a package list or a system default.

## Optional Pi configuration

This repo installs the Pi CLI declaratively: the official [`pi-coding-agent`](https://pi.dev) Homebrew formula is in `configuration.nix`'s `brews` list, so `pi` resolves on your `PATH` after a normal rebuild. Everything below is the configuration this repo layers on top of that install.

[Pi Launcher](https://github.com/kunchenguid/homebrew-tap) is a separate, optional GUI installed from its owner, not declared by this config:

```sh
brew install --cask kunchenguid/tap/pi-launcher
```

Home Manager owns exactly two repository-authored Pi directories: `~/.pi/agent/themes` and `~/.pi/agent/extensions`. It also links `models.json` and `settings.json` as individual files. Because those links point back into the clone, Pi rewrites `settings.json` in place - it serializes without a trailing newline (do not add one) and re-adds churn keys such as `lastChangelogVersion` on upgrade; discard those with `git checkout` instead of committing them. The local extension directory is for public, repository-authored extensions only - third-party package code never belongs there. Run `/reload` after editing a local extension or other Pi resources. The terminal-title extension shows a spinner while Pi is working, then a completion mark with the session name or current directory. The `rose-pine-moon` theme was authored clean-room from the public [Rosé Pine Moon palette](https://rosepinetheme.com/palette) and Pi's [public theme schema](https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json), not from a private or live theme file.

### Pi Calm

`home/.pi/agent/extensions/calm` is a standalone local Pi extension. Home Manager's existing global extensions-directory link makes Pi auto-load it without another declaration. `/calm` toggles a conversation-only presentation mode and is off by default. Its choice is stored locally in `~/.pi/agent/calm` (or the directory selected by `PI_CODING_AGENT_DIR`), not in this repository or Home Manager. Adapted from Firstmate under the bundled MIT license, Calm imports no Firstmate modules and has no Firstmate runtime dependency.

When enabled, Calm hides collapsed thinking and the call/result shells for Pi's seven built-in tools (`read`, `bash`, `edit`, `write`, `grep`, `find`, and `ls`) without leaving blank transcript rows. During an active run it replaces Pi's working row with a two-line animated blue-water, yellow-boat widget. `/calm` restores Pi's stock rendering and preserves the existing Ctrl+O tool-expansion choice.

Calm never changes prompts, tool execution, model context, session data, or ordering. `/share` and `/export` use the complete stock transcript. Generic custom tools, images, and unsupported Pi transcript classes deliberately remain visible because Pi has no safe general-purpose transcript filter. If a future Pi release no longer exports the exact collapsed-thinking rendering seam, Calm logs one diagnostic and leaves only that adapter disabled; all other behavior remains available.

Pi's package system declares two third-party sources in the linked global `settings.json`:

- `npm:@ryan_nookpi/pi-extension-codex-fast-mode@0.2.6` - the exact public npm release from `ryan_nookpi`.
- `git:github.com/algal/pi-openai-server-compaction@c6d593087709e9481223dc6c6c2269b371b5e055` - the exact public `algal` commit for experimental OpenAI server-side compaction.

The version and commit are immutable pins, so Pi does not move them during package updates. Deliberate updates require a new source and security audit, followed by an explicit pin change in `home/.pi/agent/settings.json`. On Pi 0.82.0, global settings declarations install missing pinned packages automatically at startup. No one-time install command is required. Pi keeps the downloaded npm and git package trees in its own unmanaged `~/.pi/agent/npm` and `~/.pi/agent/git` runtime directories, outside Home Manager and Git tracking.

Both packages execute with your full user permissions and must be trusted like any other executable code. The compaction package is experimental, sends the relevant OpenAI compaction and continuity data to OpenAI, and upstream declares the stale peer range `>=0.80.9 <0.81.0`; this exact immutable ref was locally proven to load and perform remote compaction on Pi 0.82.0. Do not treat that proof as a guarantee for a different Pi version or a different package ref.

Home Manager deliberately does not manage `~/.pi/agent` itself, or Pi authentication, sessions, trust decisions, caches, npm/git package trees, or any other runtime state. `settings.json` does pick a default provider, model, and thinking level (`xai` / `grok-4.5` / `medium`); change those three keys if you use a different provider. Neither those settings nor the model overrides contain credentials or endpoint settings, and both only take effect after you authenticate Pi yourself. This remains an additive post-video layer for `~/.pi/agent` config: beyond the `pi-coding-agent` CLI declared in `configuration.nix`, it does not install a launcher or vendor package source code into this repository.

## Remote access (SSH / VS Code Remote-SSH)

`configuration.nix` declares `services.openssh.enable = true;`, which turns on macOS's built-in Remote Login (the same sshd behind System Settings > Sharing) on every switch, and disables password authentication (`PasswordAuthentication no`, `KbdInteractiveAuthentication no`) so only key-based logins are accepted.

`home/.ssh/authorized_keys` is symlinked to `~/.ssh/authorized_keys` and ships with a placeholder line. To let another machine (e.g. a Windows PC running VS Code Insiders' Remote-SSH extension) connect:

1. On that machine, generate a keypair if you don't already have one: `ssh-keygen -t ed25519`.
2. Replace the placeholder line in `home/.ssh/authorized_keys` with the contents of the resulting `.pub` file.
3. Run `./rebuild.sh` on the Mac.

This setup assumes both machines are on the same local network - it doesn't open any port on your router or configure a tunnel. For access from outside your LAN, put something like Tailscale in front of it rather than port-forwarding SSH directly to the internet.

`visual-studio-code@insiders` is in the `casks` list, giving this Mac its own local VS Code Insiders install. That's separate from the Remote-SSH connection itself: when you connect from the Windows PC's VS Code Insiders, the Remote-SSH extension downloads and runs its own remote server component on the Mac automatically over the SSH connection the first time you connect - no separate install step for that part, since macOS already ships the `curl`/`tar` it needs.

## GitHub SSH authentication & commit signing (1Password)

This Mac runs unattended - nobody is sitting at it to approve a Touch ID prompt, and VNC-ing in every time git wants to push or sign a commit isn't "hands off." So this isn't 1Password's interactive SSH agent (that always requires a human to approve each use, every time it locks or restarts - fine for a laptop, not for a server). Instead:

- A dedicated, non-default 1Password vault (`mac-automation`) holds two SSH keys used **only** by this machine: `dotfiles-mac-auth` and `dotfiles-mac-signing`, kept separate so a problem with one never touches the other.
- A **Service Account** scoped read-only to just that vault authenticates non-interactively - no vault unlock, no biometrics, no human required.
- `home/.ssh/*.tmpl` are committed templates containing only `op://` references (safe - no secrets). `rebuild.sh` runs `op inject` after every `darwin-rebuild switch` to materialize the real private keys, public keys, and `allowed_signers` straight into `~/.ssh/`, entirely outside both this git repo and the Nix store (which is world-readable, so secrets must never pass through it).
- `home/.ssh/config` routes `github.com` at the local materialized key directly (`IdentityAgent none`), and falls back to 1Password's interactive agent for every other host - so a human still gets the vault-gated, private-key-never-touches-disk experience for their own ad hoc SSH use.
- Git signing uses git's default `ssh-keygen`-based signer against the local key file - no `op-ssh-sign`, no 1Password dependency at commit time.
- The same vault also holds a `dotfiles-personal` item with `GIT_NAME`/`GIT_EMAIL` fields, injected into `~/.config/git/config-local` and pulled in via `programs.git.includes` - so this repo's `home.nix` never hardcodes anyone's real name or email either.
- The GitHub **CLI** (`gh`, and the `gh-axi` wrapper firstmate uses to open, poll, and merge pull requests) talks to the GitHub *API*, which an SSH key can't authenticate. So the same vault holds a `dotfiles-gh-token` item whose password is a GitHub Personal Access Token; `rebuild.sh` injects it into `~/.config/gh/token` (mode 600, outside repo and Nix store), and `home.nix` exports it as `GH_TOKEN`/`GITHUB_TOKEN` from `.zshenv` for every shell. Git operations still go over SSH with the auth key; only the API uses this token.

**The trade-off, stated plainly:** the private keys now exist as ordinary files on this machine's disk, protected by Unix permissions and FileVault-at-rest - not "held only inside 1Password's vault." That's the same security posture as any standard CI/deploy key, not stronger. It's the accepted trade-off for unattended automation; it is a real downgrade from the interactive-agent model, not a wash.

One-time setup:

1. In 1Password, create the `mac-automation` vault (Service Accounts can't be granted access to your Personal/Private/Shared vault, so it has to be a fresh one).
2. In that vault, create `dotfiles-mac-auth` and `dotfiles-mac-signing` as SSH Key items (+ New Item > SSH Key > Generate, type ed25519), and a `dotfiles-personal` item (any item type with custom text fields) with `GIT_NAME` and `GIT_EMAIL` fields set to your actual name and email. Also create a `dotfiles-gh-token` Password item whose `password` is a GitHub Personal Access Token for the GitHub CLI/API. A classic PAT needs `repo` and `workflow` scopes (add `read:org` if you work in org repos); a fine-grained PAT needs Contents, Pull requests, and Workflows read/write plus Actions/Checks read, on the repos you ship to.
3. Create a Service Account, read-only, scoped to only the `mac-automation` vault. Copy its token immediately - 1Password shows it exactly once.
4. On this machine: `mkdir -p ~/.config/op && chmod 700 ~/.config/op`, save the token to `~/.config/op/service-account-token`, then `chmod 600` it. That path is outside `~/.dotfiles`, so it can never end up in this repo.
5. Run `./rebuild.sh`. It installs `1password-cli` (the `op` binary, via the `casks` list), then injects the keys, git identity, and GitHub token into `~/.ssh/`, `~/.config/git/config-local`, and `~/.config/gh/token`.
6. On GitHub, go to Settings > SSH and GPG keys > New SSH key. Add `~/.ssh/id_ed25519_mac_auth.pub`'s contents with key type "Authentication Key", and `~/.ssh/id_ed25519_mac_signing.pub`'s with key type "Signing Key".
7. Point this clone at GitHub over SSH: `git remote set-url origin git@github.com:<you>/<repo>.git`.
8. Verify: `ssh -T git@github.com` should greet you by username with no prompt at all, and `git commit --allow-empty -m test && git log --show-signature -1` should show a good SSH signature. GitHub also shows a "Verified" badge on pushed commits signed this way.

Rotating a key later is just: generate a new one in the 1Password item, re-run `./rebuild.sh` (`op inject --force` overwrites the local file), and update the GitHub-registered public key to match.

If you're setting this up on a laptop you actually sit at instead of a headless box, skip all of this and just use 1Password's interactive SSH agent directly - point `home/.ssh/config`'s `IdentityAgent` at 1Password's socket for all hosts, point `git`'s `gpg.ssh.program` at `op-ssh-sign`, and accept the occasional Touch ID prompt in exchange for the private key never touching disk at all. That's a better trade for a machine a person is actually present at.

## Notes

The first time you launch `nvim`, it bootstraps [lazy.nvim](https://github.com/folke/lazy.nvim) by cloning plugins from GitHub.
That needs network access once; after that it's offline.
Neovim and WezTerm both use the rose-pine moon theme.
Neovim keeps italics off and uses a transparent background on macOS, Windows, and WSL so it matches the terminal setup.

## License

This repo is licensed under MIT No Attribution.
See `LICENSE`.
