#!/usr/bin/env bash
# This machine runs 24/7 unattended, and macOS's default idle sleep killed
# agent runs mid-response. A reverted sleep setting does not announce itself,
# so guard the declaration here.
#
# These assertions read configuration.nix as text rather than querying pmset:
# CI never applies (or even evaluates) the darwin system, so live power state
# is not observable there. The declaration is what a revert would remove.
set -u

# shellcheck source=tests/lib.sh
. "$(dirname "${BASH_SOURCE[0]}")/lib.sh"

# Scoped to the `power = { ... }` attrset, never the whole file: the same
# option names appear in the explanatory comments above it, so a whole-file
# match would stay green even if the real declaration were deleted.
test_power_block_declares_no_sleep_and_auto_restart() {
  local power

  power=$(awk '/^  power = \{/, /^  \};/' "$ROOT/configuration.nix")
  assert_contains "$power" 'power = {' \
    "could not locate the power attrset in configuration.nix"

  assert_contains "$power" 'computer = "never"' \
    "configuration.nix no longer sets power.sleep.computer = \"never\""
  assert_contains "$power" 'harddisk = "never"' \
    "configuration.nix no longer sets power.sleep.harddisk = \"never\""
  assert_contains "$power" 'restartAfterPowerFailure = true' \
    "configuration.nix no longer sets power.restartAfterPowerFailure = true"

  pass "configuration.nix declares no system/disk sleep and automatic restart"
}

# restartAfterFreeze is excluded on purpose. nix-darwin applies it with an
# unguarded `systemsetup -setRestartFreeze` in an activation script that runs
# under `set -e`, and restart-on-freeze is commonly unsupported on Apple
# Silicon - so adding it back untested breaks `darwin-rebuild switch` outright
# rather than merely missing a setting.
test_restart_after_freeze_stays_unset() {
  local power

  power=$(awk '/^  power = \{/, /^  \};/' "$ROOT/configuration.nix")
  assert_not_contains "$power" 'restartAfterFreeze =' \
    "configuration.nix now sets power.restartAfterFreeze - it is unverified on this Apple Silicon hardware and an unsupported systemsetup call aborts activation"

  pass "restartAfterFreeze is left unset"
}

# Display sleep is deliberately left at the system default. Upstream's
# power.sleep.display would disable it; asserting its absence keeps a
# well-meaning "disable all sleep" edit from quietly widening the scope.
test_display_sleep_stays_unmanaged() {
  local power

  power=$(awk '/^  power = \{/, /^  \};/' "$ROOT/configuration.nix")
  assert_not_contains "$power" 'display =' \
    "configuration.nix now manages power.sleep.display - display sleep is intentionally left at the system default"

  pass "display sleep is left unmanaged"
}

# Power Nap has no declarative option at the pinned nix-darwin rev, so it is
# disabled by an activation script. Activation runs under `set -e` with
# postActivation as the last fragment before /run/current-system is repointed,
# so the call must be guarded: a hard failure there would apply the whole
# generation without marking it current.
test_power_nap_disabled_without_failing_activation() {
  local activation

  activation=$(awk '/system\.activationScripts\.postActivation\.text = /, /^  '"''"';/' \
    "$ROOT/configuration.nix")
  assert_contains "$activation" 'pmset -a powernap 0' \
    "configuration.nix no longer disables Power Nap via the postActivation script"

  assert_contains "$activation" 'pmset -g cap' \
    "the Power Nap activation call is no longer guarded on hardware capability"
  assert_contains "$activation" '|| echo' \
    "the Power Nap activation call can now fail hard and abort activation"

  pass "Power Nap is disabled by a guarded activation call that cannot abort activation"
}

test_power_block_declares_no_sleep_and_auto_restart
test_restart_after_freeze_stays_unset
test_display_sleep_stays_unmanaged
test_power_nap_disabled_without_failing_activation
