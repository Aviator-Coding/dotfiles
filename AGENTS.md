# Project notes for agents

Deliberate decisions in this repo - do NOT silently revert them:

- `homebrew.onActivation.cleanup = "zap"` in `configuration.nix` is intentional. It forces the good habit of declaring every Homebrew package in the Nix config instead of installing things ad-hoc, which keeps the machine reproducible. Do not soften it to `uninstall` or `none`. Users are warned about its effect in README.md; this note is for anyone tempted to change the setting itself.
- Never commit `.no-mistakes/` validation evidence to this public repo. `.no-mistakes/` is gitignored; if a validation pipeline stages evidence into a branch, drop it before merging.

- Secret scanning is local-only: `.pre-commit-config.yaml` runs gitleaks (plus detect-private-key / large-file checks). `pre-commit` and `gitleaks` are declared in `home.nix`; `bootstrap.sh` runs `pre-commit install` after the first switch. Secret scanning stays local-only and is not run in CI - do not add a secret-scanning workflow (`.github/workflows/ci.yml` deliberately runs only the `tests/` suite). Manual fallback: `pre-commit install`. Full-history scan: `gitleaks detect --source . --log-opts="--all"`.

- Claude Code is installed via the npm-global activation script in `home.nix` (`@anthropic-ai/claude-code`), not `homebrew.casks`. The Homebrew cask build is blocked by Apple System Policy (quarantine xattr suspends it before `main` runs, hanging forever). Do not move it back to `homebrew.casks`; `tests/claude-code-npm.test.sh` guards both halves of this.

- `configuration.nix` sets `power.sleep.computer`/`power.sleep.harddisk = "never"`, `power.restartAfterPowerFailure = true`, and `power.restartAfterFreeze = true`, and disables Power Nap via `system.activationScripts.postActivation`. This machine runs 24/7 unattended; macOS's default idle sleep was killing unattended agent work. Do not soften these back to a timed sleep, and do not add display-sleep or other energy-saver settings alongside them - display sleep is deliberately left at the system default. `power.restartAfterFreeze` is applied via an unguarded `systemsetup -setRestartFreeze` under `set -e`, so it is a real hazard on hardware where the command is unsupported - it was verified working on this machine (Mac16,10 / M4 Mac mini, macOS 26.5.2) on 2026-08-12 before being enabled; re-verify before copying this to different hardware. Verify option names against the pinned nix-darwin (`modules/power/*.nix` in `flake.lock`'s `nix-darwin` rev) before changing this block. `tests/power-247.test.sh` guards each setting in this block; the Power Nap activation call must stay failure-tolerant, since `postActivation` runs under `set -e` right before `/run/current-system` is repointed.

## Maintaining this file

Keep this file for knowledge useful to almost every future agent session in this project.
Do not repeat what the codebase already shows; point to the authoritative file or command instead.
Prefer rewriting or pruning existing entries over appending new ones.
When updating this file, preserve this bar for all agents and keep entries concise.
