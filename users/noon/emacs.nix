# ---------------------------------------------------------------------------
#
# ~ Emacs
#
# Terminal-only emacs (launched via `emacsclient -t`, alias `e`), mirroring
# the neovim setup (vim.nix + init.vim + haskell.lua). Packages and the
# daemon are declared here; the elisp lives in sibling files:
#
#   early-init.el        startup/GC tuning
#   init.el              the main configuration
#   noon-light-theme.el  port of noon-light-vim
#
# Edits to those files need a rebuild; the daemon restarts itself on
# switch whenever they change (X-Restart-Triggers below). External
# programs the elisp shells out to (rg, direnv, xclip) come from PATH.
#
# ---------------------------------------------------------------------------
{ lib, pkgs, ... }:
{
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-nox;
    extraPackages = epkgs: with epkgs; [
      # evil
      evil
      evil-collection
      evil-commentary
      evil-easymotion
      evil-lion
      evil-org # (org itself is built-in)
      evil-quickscope
      # editing
      envrc # per-buffer direnv (HLS comes from project shells)
      undo-fu-session
      xclip
      # completion ui
      consult
      marginalia
      orderless
      vertico
      # project navigation
      projectile
      # git
      diff-hl
      magit
      # languages (agda2-mode deliberately absent: loaded via `agda-mode locate`)
      dhall-mode
      elm-mode
      go-mode
      haskell-mode
      ledger-mode
      markdown-mode
      nix-mode
      shakespeare-mode
      typescript-mode
      yaml-mode
    ];
  };

  services.emacs = {
    enable = true;
    # After graphical-session.target, so DISPLAY is in the daemon's
    # environment (xclip needs it).
    startWithUserSession = "graphical";
    # EDITOR stays nvim.
    defaultEditor = false;
    client.enable = false;
  };

  home.file = {
    ".config/emacs/early-init.el".source = ./early-init.el;
    ".config/emacs/init.el".source = ./init.el;
    ".config/emacs/themes/noon-light-theme.el".source = ./noon-light-theme.el;
  };

  # Restart the daemon on switch when (and only when) the emacs config
  # changed: home-manager's sd-switch restarts units whose file changed,
  # and this hash ties the unit file to the elisp. (A package change
  # already alters the unit's ExecStart store path.)
  systemd.user.services.emacs.Unit = {
    X-Restart-Triggers = [
      (builtins.hashString "sha256" (
        builtins.readFile ./early-init.el
        + builtins.readFile ./init.el
        + builtins.readFile ./noon-light-theme.el
      ))
    ];
    # home-manager sets this to false to protect unsaved buffers; we
    # accept the tradeoff (auto-save is off!) -- save before rebuilding.
    X-RestartIfChanged = lib.mkForce true;
  };
}
