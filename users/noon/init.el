;;; init.el -*- lexical-binding: t -*-
;;
;; Deployed by emacs.nix as a read-only symlink into the nix store: edit
;; here, rebuild, and the daemon restarts itself on switch. External
;; programs (rg, direnv, xclip) are found via PATH.

;; Keep customize out of this read-only file.
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
  ;; C-z suspends, as in vim. Evil binds `evil-toggle-key' (C-z) in the
  ;; three maps below; unbinding it there lets the key fall through to
  ;; the global `suspend-frame' -- nil frees a key rather than shadowing
  ;; it, which is what `evil-set-toggle-key' itself does. Under
  ;; emacsclient this suspends the client, not the daemon (fg resumes).
  ;; Nothing toggles Emacs state now: use M-x evil-emacs-state.
  (dolist (map (list evil-motion-state-map
                     evil-insert-state-map
                     evil-emacs-state-map))
    (define-key map (kbd "C-z") nil))
  (evil-mode 1))

(use-package evil-collection       ; vim keys in magit, dired, help, ...
  :after evil
  :config (evil-collection-init))

;; -- Clipboard + persistent undo -----------------------------------------

(use-package xclip                 ; clipboard=unnamedplus
  :init (setq xclip-program "xclip")
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

;; dired-mode-map is an evil "overriding" map, so dired's own `;'
;; (the epa encryption prefix) beats the motion-state binding above.
;; An auxiliary binding on the mode map outranks overriding maps.
(with-eval-after-load 'dired
  (evil-define-key 'normal dired-mode-map ";" #'evil-ex))

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
current buffer's directory. Change it with :cd, inspect with :pwd."
  (or (frame-parameter nil 'noon-client-cwd) default-directory))

(evil-define-command noon/cd (&optional path)
  "Vim-like :cd -- change this frame's working directory (the root
used by the pickers). With no PATH, go home."
  (interactive "<f>")
  (let ((dir (file-name-as-directory (expand-file-name (or path "~")))))
    (unless (file-directory-p dir)
      (user-error "Not a directory: %s" dir))
    (cd dir)
    (set-frame-parameter nil 'noon-client-cwd dir)
    (message "%s" dir)))

(defun noon/pwd ()
  "Vim-like :pwd -- show this frame's working directory."
  (interactive)
  (message "%s" (noon/picker-root)))

(evil-ex-define-cmd "cd" #'noon/cd)
(evil-ex-define-cmd "pwd" #'noon/pwd)

(defun noon/fuzzy-pick (prompt candidates)
  "`completing-read' with fzf-style subsequence (flex) matching."
  (let ((orderless-matching-styles '(orderless-flex)))
    (completing-read prompt candidates nil t)))

(defun noon/find-file-rg ()
  "Open a file under the launch directory, like :Files."
  (interactive)
  (let* ((default-directory (noon/picker-root))
         (files (process-lines "rg"
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

;; -- Projectile (project navigation) ----------------------------------------

;; Completion goes through completing-read, so vertico/orderless apply.
(use-package projectile
  :config
  (projectile-mode 1)
  (define-key projectile-mode-map (kbd "C-c p") projectile-command-map)
  ;; TAB p alongside the other file/window keys.
  (with-eval-after-load 'evil
    (define-key noon-tab-map "p" projectile-command-map)))

;; -- Languages -------------------------------------------------------------

;; The nix-installed modes register their extensions via autoloads
;; (haskell, nix, dhall, elm, purescript, typescript, go, yaml, ledger,
;; markdown, shakespeare); toml is the built-in conf-toml-mode.
(add-to-list 'auto-mode-alist
             '("/cabal\\.project\\(\\.local\\)?\\'" . haskell-cabal-mode))

;; python: match vim's classification (python.vim + noon-light):
;;   from/import        Include -> PreProc          (emacs: keyword grey)
;;   builtins (print..) Function -> black           (emacs: builtin violet)
;;   class names        Function -> black           (emacs: type violet)
;;   assignments/hints  plain                       (emacs: variable/type)
(font-lock-add-keywords
 'python-mode
 '(("\\_<\\(?:from\\|import\\)\\_>" 0 'font-lock-preprocessor-face t)
   ("\\_<class\\s-+\\(\\(?:\\sw\\|\\s_\\)+\\)" 1 'font-lock-function-name-face t))
 'append)

(defun noon/python-vim-faces ()
  (face-remap-add-relative 'font-lock-builtin-face 'font-lock-function-name-face)
  (face-remap-add-relative 'font-lock-variable-name-face 'default)
  (face-remap-add-relative 'font-lock-type-face 'default))
(add-hook 'python-mode-hook #'noon/python-vim-faces)

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

;; -- Git gutter (diff-hl) --------------------------------------------------

;; gitsigns-nvim's counterpart. A tty has no fringes, so the +/-/!
;; markers go in the left margin; the hunk popup is an overlay
;; (diff-hl-show-hunk-function defaults to the tty-safe
;; `diff-hl-show-hunk-inline'; the posframe backend is GUI-only).
(use-package diff-hl
  :config
  (global-diff-hl-mode 1)
  (diff-hl-margin-mode 1)                 ; fringe -> margin
  (diff-hl-flydiff-mode 1)                ; diff the buffer, not just the file
  ;; xterm-mouse-mode is on, so clicking a margin marker opens the hunk.
  (global-diff-hl-show-hunk-mouse-mode 1)
  ;; Re-diff after staging/committing from magit. (There is no
  ;; pre-refresh hook any more -- it is an obsolete alias for `ignore'.)
  (with-eval-after-load 'magit
    (add-hook 'magit-post-refresh-hook #'diff-hl-magit-post-refresh))
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      "]c"  #'diff-hl-next-hunk           ; vim's diff motions; evil leaves
      "[c"  #'diff-hl-previous-hunk       ; ]c/[c free (it binds ]f ]F ]s)
      ",hh" #'diff-hl-show-hunk
      ",hr" #'diff-hl-revert-hunk
      ",hs" #'diff-hl-stage-dwim)))

;; -- direnv (keep last: hooks added last run first, and envrc's
;; find-file hook must run before eglot looks for HLS) ----------------------

(use-package envrc
  :init (setq envrc-direnv-executable "direnv")
  :config (envrc-global-mode 1))
