{ config, pkgs, user, ... }:

let
  dotfiles = "${config.home.homeDirectory}/.dotfiles";
in

{
  home.username = user;
  home.homeDirectory = "/Users/${user}";
  home.stateVersion = "24.11";
  home.packages = with pkgs; [
    # cli i use constantly
    ripgrep   # fast search
    fd        # fast find
    fzf       # fuzzy finder
    jq        # json on the command line
    lazygit
    neovim
    nodejs    # npm-based CLI tooling
    gh        # GitHub CLI
    bun       # JS runtime/toolkit
    # the font everything renders in
    nerd-fonts.hack
  ];
  fonts.fontconfig.enable = true;
  home.sessionVariables.EDITOR = "nvim";
  # npm's global installs default into the Nix store, which is read-only, so
  # global packages need their own writable prefix on PATH.
  home.sessionVariables.NPM_CONFIG_PREFIX = "${config.home.homeDirectory}/.npm-global";
  home.sessionPath = [ "${config.home.homeDirectory}/.npm-global/bin" ];

  # firstmate's own CLI tools aren't in nixpkgs, so keep them installed via
  # plain `npm install -g` on every rebuild instead of hand-writing a Nix
  # derivation for each one.
  home.activation.installFirstmateAxiTools = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    # home.sessionVariables only applies to login shells, not this script, so
    # the npm prefix has to be set explicitly here too - otherwise npm falls
    # back to installing into the read-only Nix store.
    $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/.npm-global"
    $DRY_RUN_CMD env NPM_CONFIG_PREFIX="${config.home.homeDirectory}/.npm-global" ${pkgs.nodejs}/bin/npm install --global gh-axi chrome-devtools-axi lavish-axi tasks-axi quota-axi
  '';

  # no-mistakes and treehouse aren't packaged in nixpkgs either and ship their
  # own installers, which are safe to re-run (they update in place). Re-run
  # them on every rebuild so a fresh clone ends up with the full firstmate
  # toolchain, same reasoning as the npm tools above.
  home.activation.installNoMistakes = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD sh -c '${pkgs.curl}/bin/curl -fsSL https://raw.githubusercontent.com/kunchenguid/no-mistakes/main/docs/install.sh | sh'
  '';
  home.activation.installTreehouse = config.lib.dag.entryAfter [ "writeBoundary" ] ''
    $DRY_RUN_CMD sh -c '${pkgs.curl}/bin/curl -fsSL https://kunchenguid.github.io/treehouse/install.sh | sh'
  '';

  # GitHub auth and commit signing for this box. This machine runs
  # unattended, so its keys are a dedicated pair pulled from a read-only
  # 1Password Service Account into plain files at rebuild time (see
  # rebuild.sh and README: "GitHub SSH authentication & commit signing"),
  # rather than 1Password's interactive SSH agent, which always requires a
  # human to approve each use. Signing therefore uses git's default
  # ssh-keygen-based signer against the local key - no 1Password dependency
  # at commit time, no prompts. user.name/email live in ~/.config/git/config-local
  # instead, which rebuild.sh also materializes from 1Password - so this
  # public repo's config never hardcodes anyone's real identity.
  programs.git = {
    enable = true;
    includes = [
      { path = "${config.home.homeDirectory}/.config/git/config-local"; }
    ];
    settings = {
      user.signingkey = "${config.home.homeDirectory}/.ssh/id_ed25519_mac_signing";
      commit.gpgsign = true;
      gpg.format = "ssh";
      gpg.ssh.allowedSignersFile = "${config.home.homeDirectory}/.ssh/allowed_signers";
    };
  };

  programs.zsh = {
    enable = true;
    autosuggestion.enable = true;      # ghost text from history
    syntaxHighlighting.enable = true;  # commands turn green when valid
    initContent = ''
      bindkey '^f' autosuggest-accept
    '';
    shellAliases = {
      ".." = "cd ..";
      add = "git add .";
      push = "git push";
      pull = "git pull";
      m = "git switch main";
      cc = "claude --dangerously-skip-permissions";
      co = "codex --full-auto";
    };
  };

  programs.starship = {
    enable = true;
    settings = {
      add_newline = false;
      format = "$directory$git_branch$git_status$cmd_duration$line_break$character";
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
      };
      cmd_duration.format = "[$duration]($style) ";
    };
  };

  # Edit-in-place: the real file stays in my repo, ~/.config just points at it.
  home.file.".config/wezterm".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/wezterm";
  home.file.".config/nvim".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/nvim";
  home.file.".config/herdr".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.config/herdr";
  home.file.".claude/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.claude/settings.json";
  home.file.".ssh/authorized_keys".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.ssh/authorized_keys";
  home.file.".ssh/config".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.ssh/config";
  # id_ed25519_mac_{auth,signing}(.pub) and allowed_signers are NOT declared
  # here: they hold real key material (or are derived from it), so rebuild.sh
  # writes them straight to ~/.ssh from 1Password via `op inject`, skipping
  # both the Nix store (world-readable) and this git repo entirely.

  # Keep Pi's credential and runtime state local by linking only authored files and directories.
  home.file.".pi/agent/themes".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/themes";
  home.file.".pi/agent/extensions".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/extensions";
  home.file.".pi/agent/models.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/models.json";
  home.file.".pi/agent/settings.json".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/.pi/agent/settings.json";

  home.file.".claude/CLAUDE.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".codex/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
  home.file.".config/opencode/AGENTS.md".source =
    config.lib.file.mkOutOfStoreSymlink "${dotfiles}/home/AGENTS.md";
}
