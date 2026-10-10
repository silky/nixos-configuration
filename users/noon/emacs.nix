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
    # emacs 31 (pinned in flake.nix, not in nixos-26.05): child frames on
    # TTY frames, which corfu and tty-tip-mode below need.
    package = pkgs.emacs31-nox;
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
      edit-indirect # markdown-mode soft-requires it for `C-c '`
      envrc # per-buffer direnv (HLS comes from project shells)
      kkp # kitty keyboard protocol: real modifier reporting in a tty
      undo-fu-session
      xclip
      # completion ui
      cape # dabbrev as the completion-at-point fallback (vim's C-n)
      consult
      corfu # in-buffer popup; needs child frames, hence emacs 31
      marginalia
      orderless
      vertico
      # child frames -- emacs 31 draws these on tty frames too
      eldoc-box # K -> hover doc float, in place of a split window
      posframe # backend for diff-hl's hunk popup
      # project navigation
      projectile
      # git
      diff-hl
      magit
      # languages (agda2-mode deliberately absent: loaded via `agda-mode locate`)
      # python, html, js/jsx, css, c, c++ and java use the built-in modes.
      dhall-mode
      elm-mode
      go-mode
      haskell-mode
      just-mode
      ledger-mode
      markdown-mode
      nix-mode
      purescript-mode
      shakespeare-mode
      tuareg # ocaml
      unison-ts-mode
      yaml-mode
      # typst-ts-mode 0.12.2 (and upstream HEAD, 2026-10) puts an autoload
      # cookie on its `define-compilation-mode' form, so the generated
      # autoloads file calls that macro at package activation -- before
      # init.el, when compile.el is not loaded. The load aborts there, and
      # the `typst-ts-mode' autoload and the .typ association, which come
      # after it in the file, never register: .typ files open in
      # fundamental-mode. Cut the form (two lines) out of the autoloads
      # file; the compilation mode still defines itself when
      # typst-ts-compile loads. elpaBuild installs straight from the
      # tarball, so this has to be post-install, not a source patch.
      (typst-ts-mode.overrideAttrs (old: {
        postInstall = (old.postInstall or "") + ''
          f=$(echo "$out"/share/emacs/site-lisp/elpa/typst-ts-mode-*/typst-ts-mode-autoloads.el)
          grep -q '^(define-compilation-mode typst-ts-compilation-mode' "$f"
          sed -i '/^(define-compilation-mode typst-ts-compilation-mode/,+1d' "$f"
          ! grep -q 'define-compilation-mode' "$f"
        '';
      }))
      # lean4-mode is on neither MELPA nor nongnu, so it is built from the
      # upstream repository. It hard-requires lsp-mode, which therefore
      # sits alongside eglot in the closure; it only loads when a .lean
      # file is opened, and init.el drops the `lsp' call from
      # `lean4-mode-hook', so nothing starts a server.
      (melpaBuild {
        pname = "lean4-mode";
        version = "1.1.2-unstable-2026-09-28";
        src = pkgs.fetchFromGitHub {
          owner = "leanprover-community";
          repo = "lean4-mode";
          rev = "6d4030e494039383664a0c08348a5c137eb4641c";
          hash = "sha256-FzeGnxjtCpeYbDU3GzadCTnLGtDPoe1q8aTpaZBck7A=";
        };
        packageRequires = [ compat dash lsp-mode magit-section ];
        # :defaults is the elisp and info; `data' holds the abbreviation
        # table behind the Lean unicode input method.
        files = ''(:defaults "data")'';
      })
      # Grammars for the ts modes: the built-in typescript ones (see
      # init.el's .tsx entry) plus typst-ts-mode's and unison-ts-mode's.
      # emacs finds these through the wrapper's load-path, so
      # `treesit-extra-load-path' needs nothing.
      (treesit-grammars.with-grammars (g: [
        g.tree-sitter-tsx
        g.tree-sitter-typescript
        g.tree-sitter-typst
        g.tree-sitter-unison
      ]))
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
