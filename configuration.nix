{ user, ... }:

{
  # Determinate already manages the Nix daemon, so nix-darwin shouldn't.
  nix.enable = false;

  nixpkgs.config.allowUnfree = true;
  nixpkgs.hostPlatform = "aarch64-darwin"; # use x86_64-darwin for Intel CPU

  system.primaryUser = user;
  users.users.${user} = {
    home = "/Users/${user}";
  };
  system.stateVersion = 6;
  # Remote Login (Apple's built-in sshd), for VS Code Remote-SSH from another
  # machine on the LAN. Key-only: see home/.ssh/authorized_keys.
  services.openssh = {
    enable = true;
    extraConfig = ''
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      MaxAuthTries 50
    '';
  };
  system.defaults = {
    NSGlobalDomain = {
      AppleInterfaceStyle = "Dark";
      KeyRepeat = 2;          # fast key repeat
      InitialKeyRepeat = 15;  # short delay before repeat
      _HIHideMenuBar = true;  # auto-hide the menu bar
      AppleShowAllExtensions = true;
    };
    dock.autohide = true;
    finder.FXPreferredViewStyle = "Nlsv";  # list view by default
    finder.CreateDesktop = false;          # clean desktop
    trackpad.Clicking = true;              # tap to click
  };
  # This machine is a Mac mini on permanent mains power, kept on 24/7 for
  # unattended agent work. macOS's default `sleep 1` (system sleeps after
  # 1 minute idle) killed unattended runs repeatedly. Do not reintroduce
  # system/disk idle sleep here - display sleep (system default, ~10 min)
  # is intentionally left unmanaged since it costs nothing on its own.
  power = {
    sleep = {
      computer = "never";  # never idle-sleep the system - the actual fix
      harddisk = "never";  # a spun-down disk stalls long-running work
    };
    # Come back on its own after a power cut. This one is confirmed supported
    # here (it shows up in live `pmset -g custom` as `autorestart`).
    restartAfterPowerFailure = true;
    # Confirmed on this machine (Mac16,10 / M4 Mac mini, macOS 26.5.2) on
    # 2026-08-12 via `sudo systemsetup -getRestartFreeze` reporting "On"
    # after `sudo systemsetup -setRestartFreeze on`. nix-darwin still applies
    # this with an unguarded `systemsetup -setRestartFreeze` inside an
    # activation script that runs under `set -e`, so on hardware where the
    # command is unsupported, setting this would abort `darwin-rebuild
    # switch` outright - verify on your own hardware before copying this.
    restartAfterFreeze = true;
  };
  # Power Nap has no declarative nix-darwin option at the pinned nix-darwin
  # rev (checked modules/power/{default,sleep}.nix). Its dark-wake
  # maintenance cycles buy nothing once the system never sleeps, so turn it
  # off explicitly via activation script instead of leaving it to chance.
  #
  # Activation runs under `set -e` and postActivation is the last fragment
  # before /run/current-system is repointed, so this must never exit nonzero:
  # hardware without Power Nap support would otherwise leave the whole
  # generation applied but not marked current.
  system.activationScripts.postActivation.text = ''
    if pmset -g cap | grep -q powernap; then
      echo "disabling Power Nap (system never sleeps, so its dark-wake cycles buy nothing)" >&2
      pmset -a powernap 0 || echo "warning: could not disable Power Nap" >&2
    else
      echo "skipping Power Nap (not supported on this hardware)" >&2
    fi
  '';
  nix-homebrew = {
    enable = true;
    inherit user;
  };
  homebrew = {
    enable = true;
    onActivation.cleanup = "zap";  # remove anything not listed here
    onActivation.autoUpdate = true;
    onActivation.extraFlags = [ "--force" ];
    brews = [
      "herdr"
      "pi-coding-agent"  # Pi agent CLI (earendil-works/pi); config already managed in home.nix
    ];
    casks = [
      "wezterm"
      "visual-studio-code@insiders"
      "1password"
      "1password-cli"
    ];
  };
}
