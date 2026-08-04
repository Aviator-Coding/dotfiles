#!/usr/bin/env bash
# Claude Code must install via the npm-global activation script in home.nix,
# not the Homebrew cask: the cask build is blocked by Apple System Policy on
# the maintainer's machine (quarantine xattr suspends it before `main` runs).
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

test_claude_code_installs_via_npm_not_cask() {
  assert_not_contains "$(cat "$ROOT/configuration.nix")" '"claude-code"' \
    "configuration.nix still lists the claude-code Homebrew cask"
  assert_contains "$(cat "$ROOT/home.nix")" '@anthropic-ai/claude-code' \
    "home.nix does not install @anthropic-ai/claude-code via npm"
  pass "Claude Code installs via the npm-global activation script, not the Homebrew cask"
}

test_claude_code_installs_via_npm_not_cask
