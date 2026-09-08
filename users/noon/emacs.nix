# ---------------------------------------------------------------------------
#
# ~ Emacs
#
# Self-contained: the package + plugins, the daemon, and all elisp
# (early-init/init/theme) live in this one file. A port of the neovim
# setup (vim.nix + init.vim + haskell.lua); terminal-only, launched via
# `emacsclient -t` (alias `e`).
#
# Elisp is embedded as nix strings, so: a literal '' must be written ''',
# a literal ${ must be written ''${. Store paths like ${pkgs.direnv} are
# interpolated on purpose, so the daemon doesn't depend on user PATH.
#
# ---------------------------------------------------------------------------
{ pkgs, ... }:
let
  earlyInit = ''
    ;;; early-init.el -*- lexical-binding: t -*-

    ;; GC off during startup; restored once startup finishes.
    (setq gc-cons-threshold most-positive-fixnum)
    (add-hook 'emacs-startup-hook
              (lambda () (setq gc-cons-threshold (* 32 1024 1024))))

    ;; Packages come from nix (site-lisp/elpa). package-activate-all must
    ;; still run -- it loads their autoloads -- but nothing may ever be
    ;; downloaded.
    (setq package-archives nil)

    (menu-bar-mode -1)
    (setq inhibit-startup-screen t
          initial-scratch-message nil
          frame-background-mode 'light)
  '';

  initEl = ''
    ;;; init.el -*- lexical-binding: t -*-

    ;; This file is a read-only nix symlink; keep customize out of it.
    (setq custom-file (locate-user-emacs-file "custom.el"))
    (load custom-file 'noerror)

    ;; -- Core behaviour (settings port) --------------------------------------

    (setq make-backup-files nil        ; nobackup
          auto-save-default nil        ; noswapfile
          create-lockfiles nil
          ring-bell-function #'ignore
          read-process-output-max (* 1024 1024))

    (global-auto-revert-mode 1)        ; autoread / vim-autoread
    (save-place-mode 1)                ; reopen files at the last position
    (recentf-mode 1)

    (setq scroll-margin 3              ; scrolloff=3
          scroll-conservatively 101
          scroll-step 1)

    (setq-default indent-tabs-mode nil ; expandtab; 2 spaces everywhere
                  tab-width 2
                  standard-indent 2
                  fill-column 78)      ; textwidth=78
    (setq sentence-end-double-space nil)

    (editorconfig-mode 1)              ; respects ~/.editorconfig
    ;; editorconfig applies its settings as file-local variables, and
    ;; smie-indent-basic (set via indent_size) has no :safe predicate in
    ;; emacs 30.2 -- declare it, or every file prompts about unsafe
    ;; local variables.
    (put 'smie-indent-basic 'safe-local-variable #'integerp)
    (which-key-mode 1)
    (xterm-mouse-mode 1)               ; mouse=a
    ;; mwheel only auto-enables in GUI sessions; in a tty daemon it
    ;; never loads, leaving the scroll wheel unbound.
    (setq mouse-wheel-scroll-amount '(3 ((shift) . 1))
          mouse-wheel-progressive-speed nil)
    (mouse-wheel-mode 1)

    ;; Strip trailing whitespace on every save, all filetypes.
    (add-hook 'before-save-hook #'delete-trailing-whitespace)

    ;; Hybrid line numbers.
    (setq display-line-numbers-type 'relative
          display-line-numbers-current-absolute t)
    (global-display-line-numbers-mode 1)

    ;; vim sets `cursorline` but the theme makes CursorLine invisible; the
    ;; only visible effect is the green current line number, which
    ;; display-line-numbers already gives us. So: no hl-line-mode.
    (show-paren-mode 1)
    (blink-cursor-mode -1)

    ;; -- Modeline: path [+] ... (fmt/enc/ft) (line N/M, col C) ---------------

    (setq-default
     mode-line-format
     '(" "
       (:eval (if buffer-file-name (abbreviate-file-name buffer-file-name)
                (buffer-name)))
       (:eval (when (buffer-modified-p) " [+]"))
       (:eval (when buffer-read-only " [RO]"))
       mode-line-format-right-align
       "("
       (:eval (pcase (coding-system-eol-type buffer-file-coding-system)
                (0 "unix") (1 "dos") (2 "mac") (_ "?")))
       "/"
       (:eval (symbol-name (coding-system-base buffer-file-coding-system)))
       "/"
       (:eval (format-mode-line mode-name))
       ") (line %l/"
       (:eval (number-to-string (line-number-at-pos (point-max))))
       ", col %c) "))

    ;; -- Theme ---------------------------------------------------------------

    (add-to-list 'custom-theme-load-path (locate-user-emacs-file "themes/"))
    (load-theme 'noon-light :no-confirm)

    ;; -- Evil ----------------------------------------------------------------

    (use-package evil
      :init
      (setq evil-want-keybinding nil   ; required by evil-collection
            evil-want-integration t
            evil-want-C-u-scroll t
            evil-undo-system 'undo-redo
            evil-search-module 'evil-search
            evil-ex-search-case 'smart ; ignorecase+smartcase
            evil-ex-substitute-global t ; gdefault
            evil-shift-width 2
            evil-split-window-below t
            evil-vsplit-window-right t)
      :config
      (setq evil-lookup-func #'ignore) ; K -> nop
      (evil-mode 1))

    (use-package evil-collection       ; vim keys in magit, dired, help, ...
      :after evil
      :config (evil-collection-init))

    ;; -- Clipboard + persistent undo -----------------------------------------

    (use-package xclip                 ; clipboard=unnamedplus
      :init (setq xclip-program "${pkgs.xclip}/bin/xclip")
      :config (xclip-mode 1))

    (use-package undo-fu-session       ; undofile
      :config (undo-fu-session-global-mode 1))

    ;; -- Editing plugins ------------------------------------------------------

    (use-package evil-commentary       ; vim-commentary (also binds gc)
      :after evil
      :config (evil-commentary-mode 1))

    (use-package evil-lion :after evil) ; vim-easy-align; ga/gA bound below

    (use-package evil-quickscope       ; quick-scope (always-on, as in nvim)
      :after evil
      :config (global-evil-quickscope-always-mode 1))

    (use-package evil-easymotion       ; vim-easymotion, leader `.`
      :after evil
      :config
      (evilem-default-keybindings ".")
      ;; Let `.` fall through to the easymotion prefix in normal state;
      ;; repeat lives on `r`, exactly as in nvim.
      (define-key evil-normal-state-map "." nil))

    ;; -- Keybindings (port of init.vim) ---------------------------------------

    (with-eval-after-load 'evil
      ;; `;` -> ex command line
      (define-key evil-motion-state-map ";" #'evil-ex)
      ;; Space saves (S-Space is invisible to a tty; dropped)
      (define-key evil-normal-state-map (kbd "SPC") #'save-buffer)
      ;; r repeats; visual r replaces selection without clobbering the register
      (define-key evil-normal-state-map "r" #'evil-repeat)
      (evil-define-key 'visual 'global "r" "P")
      ;; ' -> exact mark; ` -> alternate buffer
      (define-key evil-motion-state-map "'" #'evil-goto-mark)
      (define-key evil-motion-state-map (kbd "`") #'evil-switch-to-windows-last-buffer)
      ;; j/k move by visual lines
      (define-key evil-normal-state-map "j" #'evil-next-visual-line)
      (define-key evil-normal-state-map "k" #'evil-previous-visual-line)
      ;; keep search matches centred (nzzzv)
      (defun noon/recenter (&rest _) (recenter))
      (advice-add 'evil-ex-search-next :after #'noon/recenter)
      (advice-add 'evil-ex-search-previous :after #'noon/recenter)
      ;; ,<space> clears search highlight
      (evil-define-key 'normal 'global (kbd ", SPC") #'evil-ex-nohighlight)
      ;; ,p / ,y -- system clipboard
      (evil-define-key '(normal visual) 'global
        ",p" "\"+p"
        ",y" "\"+y")
      ;; YY -- whole buffer to system clipboard. Y must become a prefix
      ;; key, so lone Y (yank-line, a duplicate of yy) is sacrificed.
      (defun noon/copy-buffer ()
        "Copy the entire buffer to the system clipboard."
        (interactive)
        (clipboard-kill-ring-save (point-min) (point-max)))
      (define-key evil-normal-state-map "Y" nil)
      (define-key evil-normal-state-map "YY" #'noon/copy-buffer)
      ;; \\ comments
      (evil-define-key 'normal 'global "\\\\" #'evil-commentary-line)
      (evil-define-key 'visual 'global "\\\\" #'evil-commentary)
      ;; ga/gA align (easy-align); equational reasoning: ga ip /[≤≡≈∎]
      (evil-define-key '(normal visual) 'global
        "ga" #'evil-lion-left
        "gA" #'evil-lion-right)
      (evil-define-key 'visual 'global (kbd ", SPC") #'evil-lion-left)
      ;; magit
      (evil-define-key 'normal 'global ",gs" #'magit-status)
      ;; TAB prefix (tty TAB==C-i, so evil-jump-forward is shadowed -- the
      ;; same loss terminal nvim has)
      (defvar noon-tab-map (make-sparse-keymap))
      (define-key noon-tab-map "e" #'noon/find-file-rg)
      (define-key noon-tab-map "s" #'noon/find-git-modified-file)
      (define-key noon-tab-map "h" #'evil-window-left)
      (define-key noon-tab-map "j" #'evil-window-down)
      (define-key noon-tab-map "k" #'evil-window-up)
      (define-key noon-tab-map "l" #'evil-window-right)
      (define-key noon-tab-map (kbd "TAB") #'evil-window-mru)
      (define-key evil-normal-state-map (kbd "TAB") noon-tab-map))

    ;; -- Fuzzy finding (fzf feel) ---------------------------------------------

    (use-package vertico
      :init (setq vertico-count 15)
      :config (vertico-mode 1))

    (use-package orderless
      :init
      (setq completion-styles '(orderless basic)
            completion-category-defaults nil
            completion-category-overrides
            '((file (styles basic partial-completion)))))

    (use-package marginalia
      :config (marginalia-mode 1))

    (use-package consult :defer t)

    ;; Vim-like cwd for the pickers: server.el binds default-directory to
    ;; the emacsclient's invocation directory, but only while its internal
    ;; " *server*" buffer is current -- and with no files it switches to
    ;; *scratch* before server-after-make-frame-hook runs. So capture the
    ;; dir at entry to server-execute, which still sees the binding and is
    ;; handed the new frame.
    (defun noon/remember-client-cwd (&rest args)
      (let ((frame (seq-find #'framep args)))
        (when frame
          (set-frame-parameter frame 'noon-client-cwd default-directory))))
    (advice-add 'server-execute :before #'noon/remember-client-cwd)

    (defun noon/picker-root ()
      "Where this frame's emacsclient was launched (vim's cwd), else the
    current buffer's directory."
      (or (frame-parameter nil 'noon-client-cwd) default-directory))

    (defun noon/fuzzy-pick (prompt candidates)
      "`completing-read' with fzf-style subsequence (flex) matching."
      (let ((orderless-matching-styles '(orderless-flex)))
        (completing-read prompt candidates nil t)))

    (defun noon/find-file-rg ()
      "Open a file under the launch directory, like :Files."
      (interactive)
      (let* ((default-directory (noon/picker-root))
             (files (process-lines "${pkgs.ripgrep}/bin/rg"
                                   "--files" "-M" "1000" "--.")))
        (find-file (noon/fuzzy-pick "Files: " files))))

    (defun noon/find-git-modified-file ()
      "Open a git-modified file, like :GFiles?. Paths in --porcelain are
    repo-root-relative, so run from the repo root."
      (interactive)
      (let* ((default-directory (or (locate-dominating-file (noon/picker-root) ".git")
                                    (noon/picker-root)))
             (lines (process-lines "git" "status" "--porcelain"))
             (files (delete-dups (mapcar (lambda (l) (substring l 3)) lines))))
        (find-file (noon/fuzzy-pick "Modified: " files))))

    ;; -- Languages -------------------------------------------------------------

    ;; The nix-installed modes register their extensions via autoloads
    ;; (haskell, nix, dhall, elm, purescript, typescript, go, yaml, ledger,
    ;; markdown, shakespeare); toml is the built-in conf-toml-mode.
    (add-to-list 'auto-mode-alist
                 '("/cabal\\.project\\(\\.local\\)?\\'" . haskell-cabal-mode))

    ;; -- LSP: eglot + HLS from the project's direnv shell ----------------------

    (setq eglot-autoshutdown t)

    (defun noon/maybe-start-hls ()
      ;; Only attach when the project shell provides HLS.
      (when (or (executable-find "haskell-language-server-wrapper")
                (executable-find "haskell-language-server"))
        (eglot-ensure)))
    (add-hook 'haskell-mode-hook #'noon/maybe-start-hls)

    (with-eval-after-load 'eglot       ; = haskell.lua's on_attach bindings
      (evil-define-key 'normal eglot-mode-map
        "gd" #'xref-find-definitions
        "gr" #'xref-find-references
        "K"  #'eldoc-doc-buffer
        "D"  #'flymake-show-buffer-diagnostics
        "C"  #'eglot-code-actions))

    ;; -- Agda ------------------------------------------------------------------

    ;; agda2-mode elisp is loaded from whatever `agda-mode` is on PATH, so
    ;; it always matches the project's agda (global agda covers the rest).
    ;; First load wins for the daemon's lifetime: restart the daemon when
    ;; switching between projects with different agda versions.
    (defun noon/agda-mode-bootstrap ()
      (unless (featurep 'agda2-mode)
        (let ((loc (string-trim (shell-command-to-string "agda-mode locate"))))
          (when (file-readable-p loc)
            (load-file loc))))
      (if (fboundp 'agda2-mode)
          (agda2-mode)
        (fundamental-mode)))

    (add-to-list 'auto-mode-alist '("\\.l?agda\\'" . noon/agda-mode-bootstrap))

    (with-eval-after-load 'agda-input
      ;; \st -> ≡⟨⟩ (equational-reasoning muscle memory; input prefix is
      ;; the canonical `\`, not nvim's S-Tab)
      (add-to-list 'agda-input-user-translations '("st" . ("≡⟨⟩")))
      (agda-input-setup))

    (with-eval-after-load 'agda2-mode
      ;; localleader bindings mirroring cornelis
      (evil-define-key 'normal agda2-mode-map
        ",l" #'agda2-load
        ",r" #'agda2-refine
        ",d" #'agda2-make-case
        ",," #'agda2-goal-and-context
        ",." #'agda2-goal-and-context-and-inferred
        ",n" #'agda2-solve-maybe-all
        ",a" #'agda2-mimer-maybe-all
        ",g" #'agda2-give
        "gd" #'agda2-goto-definition-keyboard))

    ;; -- Org (simple entryway; replaces the dailynotes workflow) ----------------

    (use-package org
      :defer t
      :init
      (setq org-directory "~/dev/w/notes"
            org-default-notes-file (concat org-directory "/notes.org")
            org-agenda-files (list org-directory)
            org-startup-indented t))

    (use-package evil-org               ; vim-style editing in org buffers
      :after org
      :hook (org-mode . evil-org-mode)
      :config
      (require 'evil-org-agenda)
      (evil-org-agenda-set-keys))

    (defun noon/open-notes ()
      "Open the default org notes file."
      (interactive)
      (find-file org-default-notes-file))

    (with-eval-after-load 'evil
      (evil-define-key 'normal 'global
        ",oa" #'org-agenda
        ",oc" #'org-capture
        ",oo" #'noon/open-notes))

    ;; -- Magit -----------------------------------------------------------------

    (use-package magit :defer t)

    ;; -- direnv (keep last: hooks added last run first, and envrc's
    ;; find-file hook must run before eglot looks for HLS) ----------------------

    (use-package envrc
      :init (setq envrc-direnv-executable "${pkgs.direnv}/bin/direnv")
      :config (envrc-global-mode 1))
  '';

  noonLight = ''
    ;;; noon-light-theme.el -*- lexical-binding: t -*-
    ;; Port of noon-light-vim (silky/noon-light-vim).

    (deftheme noon-light "Port of noon-light-vim.")

    (let ((bg "#fff7f1")
          (fg "#444444"))
      (custom-theme-set-faces
       'noon-light
       `(default ((t (:background ,bg :foreground ,fg))))
       ;; syntax
       '(font-lock-comment-face ((t (:foreground "#004cff"))))
       '(font-lock-comment-delimiter-face ((t (:foreground "#004cff"))))
       '(font-lock-doc-face ((t (:foreground "#004cff" :slant italic))))
       '(font-lock-string-face ((t (:foreground "#ff00ff" :slant italic))))
       '(font-lock-constant-face ((t (:foreground "#d700ff"))))
       '(font-lock-number-face ((t (:foreground "#d700ff"))))
       '(font-lock-variable-name-face ((t (:foreground "#005fff"))))
       '(font-lock-function-name-face ((t (:foreground "#000000"))))
       '(font-lock-keyword-face ((t (:foreground "#767676"))))
       '(font-lock-operator-face ((t (:foreground "#808080"))))
       '(font-lock-preprocessor-face ((t (:foreground "#5f00ff"))))
       '(font-lock-type-face ((t (:foreground "#c71eff"))))
       '(font-lock-builtin-face ((t (:foreground "#b56bfa"))))
       '(font-lock-warning-face ((t (:background "#ffffaf" :foreground "#4a4a4a" :slant italic))))
       ;; ui
       '(region ((t (:background "#ffd7d7"))))
       '(isearch ((t (:background "#87ffaf" :foreground "#444444"))))
       '(lazy-highlight ((t (:background "#87ffaf" :foreground "#444444"))))
       '(evil-ex-search ((t (:background "#87ffaf" :foreground "#444444"))))
       '(evil-ex-lazy-highlight ((t (:background "#87ffaf" :foreground "#444444"))))
       '(line-number ((t (:foreground "#d4d4d4" :slant italic))))
       '(line-number-current-line ((t (:foreground "#00af5f" :slant italic))))
       '(hl-line ((t (:background "#ffeee3"))))
       `(mode-line ((t (:background "#ffebb5" :foreground ,fg :box nil))))
       `(mode-line-inactive ((t (:background ,bg :foreground "#9a9a9a" :underline t :box nil))))
       '(show-paren-match ((t (:background "#ffffaf" :underline t))))
       `(fringe ((t (:background ,bg))))
       '(error ((t (:foreground "#ff6075"))))
       '(warning ((t (:foreground "#b56bfa"))))
       '(success ((t (:foreground "#00af5f"))))
       '(minibuffer-prompt ((t (:foreground "#5f00ff"))))
       '(link ((t (:foreground "#005fff" :underline t))))
       '(dired-directory ((t (:foreground "#5f00ff"))))
       ;; flymake / eglot
       '(flymake-error ((t (:background "#ff8a9a"))))
       '(flymake-warning ((t (:underline (:style wave :color "#b56bfa")))))
       '(flymake-note ((t (:underline (:style wave :color "#87ffaf")))))
       '(eglot-highlight-symbol-face ((t (:background "#ffd7d7"))))
       ;; completion ui
       '(vertico-current ((t (:background "#ffd7d7"))))
       '(orderless-match-face-0 ((t (:foreground "#ff00ff" :weight bold))))
       '(orderless-match-face-1 ((t (:foreground "#005fff" :weight bold))))
       '(orderless-match-face-2 ((t (:foreground "#d700ff" :weight bold))))
       '(orderless-match-face-3 ((t (:foreground "#00af5f" :weight bold))))
       '(marginalia-file-name ((t (:foreground "#767676"))))
       ;; which-key
       '(which-key-key-face ((t (:foreground "#005fff"))))
       '(which-key-command-description-face ((t (:foreground "#444444"))))
       '(which-key-group-description-face ((t (:foreground "#5f00ff"))))
       ;; magit (diff colours are judgment calls tuned to the palette)
       '(magit-section-heading ((t (:foreground "#5f00ff" :weight bold))))
       '(magit-branch-local ((t (:foreground "#005fff"))))
       '(magit-branch-remote ((t (:foreground "#d700ff"))))
       '(magit-hash ((t (:foreground "#767676"))))
       '(magit-diff-added ((t (:background "#e2ffe2" :foreground "#005f00"))))
       '(magit-diff-added-highlight ((t (:background "#c8f7c8" :foreground "#005f00"))))
       '(magit-diff-removed ((t (:background "#ffe0e0" :foreground "#9f0000"))))
       '(magit-diff-removed-highlight ((t (:background "#ffc8c8" :foreground "#9f0000"))))
       '(magit-diff-context-highlight ((t (:background "#fff0e6"))))
       '(magit-diff-hunk-heading ((t (:background "#ffebb5" :foreground "#767676"))))
       '(magit-diff-hunk-heading-highlight ((t (:background "#ffe3a0" :foreground "#444444"))))
       '(magit-section-highlight ((t (:background "#fff0e6"))))
       ;; evil-quickscope / avy (easymotion targets)
       '(evil-quickscope-first-face ((t (:foreground "#ff00ff" :underline t))))
       '(evil-quickscope-second-face ((t (:foreground "#d700ff"))))
       '(avy-lead-face ((t (:background "#87ffaf" :foreground "#444444" :weight bold))))
       '(avy-lead-face-0 ((t (:background "#ffd7d7" :foreground "#444444" :weight bold))))))

    (provide-theme 'noon-light)
  '';
in
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
      # git
      magit
      # languages (agda2-mode deliberately absent: loaded via `agda-mode locate`)
      dhall-mode
      elm-mode
      go-mode
      haskell-mode
      ledger-mode
      markdown-mode
      nix-mode
      purescript-mode
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
    ".config/emacs/early-init.el".text = earlyInit;
    ".config/emacs/init.el".text = initEl;
    ".config/emacs/themes/noon-light-theme.el".text = noonLight;
  };
}
