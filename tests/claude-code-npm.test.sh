#!/usr/bin/env bash
# Claude Code must install via the npm-global activation script in home.nix,
# not the Homebrew cask: the cask build is blocked by Apple System Policy on
# the maintainer's machine (quarantine xattr suspends it before `main` runs).
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Both assertions target the declaration itself, never the whole file: the
# package name also appears in explanatory comments, so a whole-file match
# would stay green even if the real declaration were deleted.
test_claude_code_installs_via_npm_not_cask() {
  local casks npm_install

  casks=$(awk '/casks = \[/, /\];/' "$ROOT/configuration.nix")
  assert_contains "$casks" 'casks = [' \
    "could not locate the homebrew.casks list in configuration.nix"
  assert_not_contains "$casks" 'claude-code' \
    "configuration.nix still lists the claude-code Homebrew cask"

  npm_install=$(grep 'npm install --global' "$ROOT/home.nix")
  assert_contains "$npm_install" '@anthropic-ai/claude-code' \
    "home.nix does not install @anthropic-ai/claude-code via npm"

  pass "Claude Code installs via the npm-global activation script, not the Homebrew cask"
}

test_claude_code_installs_via_npm_not_cask
