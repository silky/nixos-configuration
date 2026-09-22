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
;; Same story for haskell-mode's indentation knobs, which editorconfig
;; sets from indent_size on *.hs: none of them carry a :safe predicate,
;; so opening any file in a project with an .editorconfig (hydra, for
;; one) stops on "Please type y, n, !, ..." before the mode -- and hence
;; eglot -- finishes loading.
(dolist (v '(haskell-indentation-layout-offset
             haskell-indentation-left-offset
             haskell-indentation-starter-offset
             haskell-indentation-where-post-offset
             haskell-indentation-where-pre-offset))
  (put v 'safe-local-variable #'integerp))
(which-key-mode 1)
(xterm-mouse-mode 1)               ; mouse=a
;; mwheel only auto-enables in GUI sessions; in a tty daemon it
;; never loads, leaving the scroll wheel unbound.
(setq mouse-wheel-scroll-amount '(3 ((shift) . 1))
      mouse-wheel-progressive-speed nil)
(mouse-wheel-mode 1)

;; A plain tty collapses shifted keys onto their bare byte, so S-SPC
;; arrives indistinguishable from SPC. ghostty reports modifiers
;; properly once asked, via the kitty keyboard protocol -- which is what
;; kkp does: it queries each new terminal, pushes the enhancement flags,
;; and pops them again on teardown, so nothing outside emacs is
;; affected, and a terminal that doesn't answer is left as it was.
;; kkp reparents `local-function-key-map' rather than replacing it, so
;; the tab key (now reported as <tab>) still falls back to TAB and the
;; noon-tab-map prefix below is unaffected.
(global-kkp-mode 1)

;; Window separator: emacs draws the tty vertical border with ASCII `|',
;; which leaves a gap between rows and reads as a dashed line. nvim's
;; default `fillchars' vert is U+2502 BOX DRAWINGS LIGHT VERTICAL, which
;; joins up; the display table is how a tty frame picks the glyph. The
;; colour already matches -- `vertical-border' sets no attributes, so it
;; falls through to `default' (#444444), exactly like nvim's
;; WinSeparator here.
;;
;; This used to set the vertical-border slot to U+2502 by hand. The emacs
;; 31 builtin puts that very character in that very slot, and also fills
;; the box-drawing slots (U+2500/250C/2510/2514/2518 and the double-line
;; variants) that tty child frames draw their borders from -- without
;; them the corfu and eldoc-box popups below get boxes of blanks.
(unless standard-display-table
  (setq standard-display-table (make-display-table)))
(standard-display-unicode-special-glyphs)

;; Tooltips on tty frames (emacs 31). `help-echo' text -- flymake and
;; eglot diagnostics, diff-hl's margin markers -- hovers in a child
;; frame instead of going to the echo area, or nowhere. xterm-mouse-mode
;; above is what makes hovering register at all.
(tty-tip-mode 1)

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

;; -- Modeline: path [+] [lsp] ... (fmt/enc/ft) (line N/M, col C) ---------

;; eglot publishes its status through `mode-line-misc-info', which this
;; mode line does not include, so none of it was visible -- including the
;; "Setting up"/"Processing" progress HLS reports while it loads a
;; component, which is the slow part worth watching. Kept to a handful of
;; characters so the line cannot wrap onto a second row: the progress
;; title only appears while HLS is actually working, and collapses to a
;; bare [hls] once it is idle. Full detail is in the tooltip.
(defun noon/eglot-mode-line ()
  "Compact LSP status: server progress, in-flight requests, or nothing."
  (when (bound-and-true-p eglot--managed-mode)
    (let* ((server (eglot-current-server))
           (pending (and server (jsonrpc-continuation-count server)))
           (report (and server
                        (catch 'found
                          (maphash (lambda (_k p)
                                     (when (eq (car p) 'eglot--mode-line-reporter)
                                       (throw 'found p)))
                                   (eglot--progress-reporters server))
                          nil)))
           (title (and report (nth 2 report)))
           (pct   (and report (nth 4 report)))
           ;; HLS's titles are "Setting up hydra (for <file>)" and
           ;; "Processing"; the first word is the informative part and
           ;; keeps this to a couple of characters. A literal % must be
           ;; doubled -- this string is itself a mode-line construct, and
           ;; a bare %] is read as the recursive-edit spec and eaten.
           (text (cond
                  (report (format "hls %s%s"
                                  (truncate-string-to-width
                                   (car (split-string (or title "?"))) 10 nil nil t)
                                  (if pct (format " %s%%%%" pct) "")))
                  ((and pending (> pending 0)) (format "hls ~%d" pending))
                  (t "hls"))))
      (propertize (concat " [" text "]")
                  'help-echo (if report
                                 (format "HLS: %s %s" title (or (nth 3 report) ""))
                               "HLS: connected")))))

(setq-default
 mode-line-format
 '(" "
   (:eval (if buffer-file-name (abbreviate-file-name buffer-file-name)
            (buffer-name)))
   (:eval (when (buffer-modified-p) " [+]"))
   (:eval (when buffer-read-only " [RO]"))
   (:eval (noon/eglot-mode-line))
   ;; flymake's diagnostic counters are its minor-mode *lighter*, and
   ;; this mode line carries no `mode-line-modes', so "[0 1]" was never
   ;; drawn anywhere -- a buffer with errors looked exactly like a clean
   ;; one. Guarded on `flymake-mode' so non-LSP buffers stay bare.
   (:eval (when (bound-and-true-p flymake-mode)
            (list " " flymake-mode-line-counters)))
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

;; Copy-on-select, matching ghostty's own `copy-on-select'. Ghostty only
;; ever sees selections the terminal itself makes, and xterm-mouse-mode
;; hands emacs the mouse, so nothing selected inside emacs -- by `v' or
;; by dragging -- reached the clipboard without an explicit ,y.
;;
;; Evil already has the machinery for this and it is already switched on
;; (`evil-visual-update-x-selection-p'): a 0.1s idle timer, so extending
;; a selection with j/j/j does not spawn an xclip per keystroke. It is
;; inert here for two independent reasons -- it writes PRIMARY (this
;; config is unnamedplus/CLIPBOARD throughout: ,y ,p YY), and it bails on
;; `display-selections-p', which on a tty demands `tty-select-active-
;; regions' plus the OSC 52 terminal parameter that xclip-mode
;; deliberately clears to win the gui-backend-set-selection dispatch.
;;
;; Evil's timer alone is not enough to hang this on. It only fires after
;; a 0.1s pause *while still in visual state*, and the next command
;; cancels it, so `v3w<escape>' in one flow copies nothing -- and a
;; command that ends the selection never routes through it at all. So
;; note the selection as it changes (a substring, no subprocess) and
;; flush it to the CLIPBOARD when the selection ends, from whichever
;; hook gets there first:
;;
;;   post-command-hook            remember, while a selection exists
;;   evil-visual-state-exit-hook  v ... <escape>, or an operator
;;   deactivate-mark-hook         a mouse drag, or any plain region
;;
;; Evil's timer advice stays as well, so a lingering selection lands in
;; the clipboard before you leave it -- that is what copy-on-select does
;; in the terminal, where the text is available the moment you let go.
(with-eval-after-load 'evil
  (defvar noon--pending-selection nil
    "Text of the selection in progress, awaiting the clipboard.")

  (defun noon/remember-selection (&optional buffer)
    "Note the current selection in BUFFER for `noon/flush-selection'.
Cheap enough for `post-command-hook': it copies a string and spawns
nothing. Also serves as evil's idle-timer callback, whence BUFFER."
    (let ((buf (or buffer (current-buffer))))
      (when (buffer-live-p buf)
        ;; Every variable read here is buffer-local, so read them with BUF
        ;; current -- evil's own version tests the state outside this and
        ;; consults whatever buffer the idle timer happened to land in.
        (with-current-buffer buf
          (let ((bounds
                 (cond
                  ;; A block selection is disjoint ranges; visual
                  ;; beginning/end is only its bounding box, so the text
                  ;; between them is not what is highlighted. Evil skips
                  ;; block for PRIMARY too.
                  ((eq evil-visual-selection 'block) nil)
                  ((and (evil-visual-state-p)
                        ;; Markers, per evil's docstrings; this also
                        ;; covers the nil they hold before a selection.
                        (number-or-marker-p evil-visual-beginning)
                        (number-or-marker-p evil-visual-end))
                   (cons evil-visual-beginning evil-visual-end))
                  ;; Not every selection is an evil one: a mouse drag
                  ;; under xterm-mouse-mode just activates the region.
                  ((region-active-p) (cons (region-beginning) (region-end))))))
            (if (null bounds)
                ;; No selection here any more. Drop anything noted
                ;; earlier: a selection that ended without either flush
                ;; hook firing must not resurface in the clipboard later,
                ;; long after its text stopped being what was selected.
                (setq noon--pending-selection nil)
              (let ((text (buffer-substring-no-properties (car bounds) (cdr bounds))))
                (unless (string-empty-p text)
                  (setq noon--pending-selection text)))))))))

  (defun noon/flush-selection ()
    "Put the noted selection in the system CLIPBOARD."
    (when-let* ((text noon--pending-selection))
      (setq noon--pending-selection nil)
      ;; `gui-set-selection', not `kill-new': merely looking at a region
      ;; should not push it onto the kill-ring.
      (gui-set-selection 'CLIPBOARD text)))

  (add-hook 'post-command-hook #'noon/remember-selection)
  (add-hook 'evil-visual-state-exit-hook #'noon/flush-selection)
  (add-hook 'deactivate-mark-hook #'noon/flush-selection)
  ;; Evil's own idle timer, for the still-selecting case.
  (advice-add 'evil-visual-update-x-selection :after #'noon/remember-selection)
  (advice-add 'evil-visual-update-x-selection :after
              (lambda (&rest _) (noon/flush-selection))
              '((name . noon/flush-after-evil-timer))))

(use-package undo-fu-session       ; undofile
  :config (undo-fu-session-global-mode 1))

;; -- Editing plugins ------------------------------------------------------

(use-package evil-commentary       ; vim-commentary (also binds gc)
  :after evil
  :config (evil-commentary-mode 1))

(use-package evil-lion :after evil) ; vim-easy-align; ga/gA bound below

;; quick-scope. init.vim sets `g:qs_highlight_on_keys = ['f','F','t','T']',
;; i.e. the targets light up only once you reach for one of those keys --
;; so this is `-mode', not `-always-mode'. Always-mode underlines a
;; scattering of letters on the cursor's line the whole time, which is
;; what nvim deliberately avoids.
(use-package evil-quickscope
  :after evil
  :config (global-evil-quickscope-mode 1))

(use-package evil-easymotion       ; vim-easymotion, leader `.`
  :after evil
  :config
  (evilem-default-keybindings ".")
  ;; Let `.` fall through to the easymotion prefix in normal state;
  ;; repeat lives on `r`, exactly as in nvim.
  (define-key evil-normal-state-map "." nil))

;; -- Keybindings (port of init.vim) ---------------------------------------

;; xmonad's modMask is mod1 (Alt), which a terminal delivers as Meta, so
;; anything xmonad binds never reaches here. Alt-b is one of those, and a
;; working M-f next to a dead M-b is worse than neither: editing is vim's
;; job in this configuration anyway.
(keymap-global-unset "M-f")

(with-eval-after-load 'evil
  ;; `;` -> ex command line
  (define-key evil-motion-state-map ";" #'evil-ex)
  (defun noon/save-buffer ()
    "Save the current buffer; in *scratch*, hint at C-x C-s instead.
*scratch* visits no file, so saving it only ever reaches a \"File to
save in:\" prompt -- worth a deliberate keystroke, not a stray one."
    (interactive)
    (if (string= (buffer-name) "*scratch*")
        ;; Transient hint; keep it out of *Messages*.
        (let ((message-log-max nil))
          (message "C-x C-s saves *scratch*"))
      (save-buffer)))
  ;; Space saves; in *scratch* it only names the key that does (nothing
  ;; there is worth a save prompt). S-SPC used to be that key; it shows
  ;; the hunk at point now (see diff-hl), which leaves plain C-x C-s for
  ;; the one buffer that wants a deliberate save.
  (define-key evil-normal-state-map (kbd "SPC") #'noon/save-buffer)
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

;; -- In-buffer completion (nvim-cmp's counterpart) ------------------------

;; vertico handles the minibuffer; this is the popup at point, which is
;; where HLS completions land. It draws into a child frame, so on a tty
;; it needs emacs 31 -- before that the only option was corfu-terminal's
;; overlay reimplementation.
(use-package corfu
  :init
  (setq corfu-auto nil                      ; ask for it; see C-n/C-p below
        corfu-cycle t
        ;; Preselect the prompt (what was typed) rather than the first
        ;; candidate: completeopt=longest,menuone from init.vim -- a menu,
        ;; and no free guess at which entry you meant. With nothing
        ;; selected RET dismisses the menu rather than inserting anything
        ;; (`corfu-insert' quits when the index is -1), so the newline
        ;; takes a second RET.
        corfu-preselect 'prompt)
  :config
  (global-corfu-mode 1)
  ;; Completion is asked for, never offered. The ask is vim's own C-n/C-p:
  ;; init.vim never ran nvim-cmp (it is commented out in vim.nix), just
  ;; native insert-mode completion on those two keys.
  ;;
  ;; One command has to do both jobs -- open the menu, then walk it --
  ;; because corfu cannot have the keys once the menu is up: it registers
  ;; `corfu-map' in `minor-mode-overriding-map-alist', and evil's insert
  ;; state map outranks that, so C-n/C-p would stay on evil's own dabbrev
  ;; completion the whole time. Which is also what vim's C-n does: first
  ;; press offers, further presses cycle. RET and TAB need no such help --
  ;; `newline' and `indent-for-tab-command' come from maps that do sit
  ;; below corfu's, so they turn into insert/complete on their own.
  ;; `(and corfu-mode completion-in-region-mode)' is corfu's own test for
  ;; "the menu is mine" (see `corfu--eldoc-advice'): the mode alone is on
  ;; in buffers where plain *Completions* is doing the work, and there
  ;; `corfu-next' would move an index nobody is showing.
  (defun noon/complete-next ()
    "Ask for completion, or move to the next candidate (vim's insert C-n)."
    (interactive)
    (if (and corfu-mode completion-in-region-mode)
        (corfu-next)
      (completion-at-point)))
  (defun noon/complete-previous ()
    "Ask for completion, or move to the previous candidate (vim's C-p)."
    (interactive)
    (if (and corfu-mode completion-in-region-mode)
        (corfu-previous)
      (completion-at-point)))
  ;; Walking the menu has to be declared as such. `corfu--prepare' runs on
  ;; pre-command-hook and, for any command not matched by this list,
  ;; commits the previewed candidate and quits -- that is what lets you
  ;; type on after selecting one. Corfu's own commands match it by name;
  ;; these two have to say so, or the third C-n would insert candidate one
  ;; and reopen the menu on it instead of moving to candidate two.
  (dolist (cmd '(noon/complete-next noon/complete-previous))
    (add-to-list 'corfu-continue-commands cmd))
  (with-eval-after-load 'evil
    (evil-define-key 'insert 'global
      (kbd "C-n") #'noon/complete-next
      (kbd "C-p") #'noon/complete-previous)))

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
;; (haskell, nix, dhall, elm, purescript, go, yaml, ledger, markdown,
;; shakespeare, just); toml is the built-in conf-toml-mode.
(add-to-list 'auto-mode-alist
             '("/cabal\\.project\\(\\.local\\)?\\'" . haskell-cabal-mode))

;; just-mode's autoload only claims `justfile' / `.justfile' / `Justfile';
;; `just' modules live in `foo.just', so claim that extension too.
(add-to-list 'auto-mode-alist '("\\.just\\'" . just-mode))

;; typescript: the built-in tree-sitter modes, and *not* ELPA
;; typescript-mode (dropped from emacs.nix), whose indenter predates JSX
;; and has no grammar for it. On a .tsx it reads `<p className={...}>' as
;; a comparison and puts the line one level left of where it belongs --
;; which `electric-indent-mode' applies to the current line on every RET,
;; and which TAB cannot undo, because `indent-for-tab-command' asks the
;; same engine and gets the same wrong column back. The grammars are
;; installed alongside emacs, so these modes are always ready.
(add-to-list 'auto-mode-alist '("\\.tsx\\'" . tsx-ts-mode))
(add-to-list 'auto-mode-alist '("\\.ts\\'" . typescript-ts-mode))

;; haskell: match vim's classification (haskell-vim + noon-light).
;; haskell-mode paints every keyword with haskell-keyword-face, so the
;; lot arrives as Statement grey; haskell-vim splits them three ways.
;; The gap is loudest on `deriving stock (Generic)', violet end to end
;; in vim but half grey here:
;;   data type family class instance newtype module where let in,
;;   deriving + anyclass/newtype/stock/via/instance  Structure -> Type
;;   import qualified as hiding safe                 Include -> PreProc
;;   do case of, if then else, infix{,l,r}, default  Keyword -> Statement
;; Only the first two groups move; the third is already grey. Every
;; matcher skips strings and comments, which the override flag these
;; rules need would otherwise repaint.

(defun noon/haskell-search (regexp limit)
  "Search forward for REGEXP before LIMIT, skipping strings and comments.
`syntax-ppss' leaves point at its argument and can run
`syntax-propertize' over the match data, so both are saved: without the
`save-excursion' point slides back to the start of the match and the
anchored rules below spin on it forever."
  (catch 'hit
    (while (re-search-forward regexp limit t)
      (let ((data (match-data)))
        (unless (save-excursion
                  (save-match-data (nth 8 (syntax-ppss (car data)))))
          (set-match-data data)
          (throw 'hit t))))
    nil))

(defconst noon/haskell-structure-re
  (concat "\\_<" (regexp-opt '("class" "data" "deriving" "in" "instance"
                               "let" "module" "newtype" "type" "where"))
          "\\_>"))
(defconst noon/haskell-strategy-re
  (concat "\\_<" (regexp-opt '("anyclass" "instance" "newtype" "stock" "via"))
          "\\_>"))
(defconst noon/haskell-import-word-re
  (concat "\\_<" (regexp-opt '("as" "hiding" "qualified" "safe")) "\\_>"))

(defun noon/haskell-structure (limit)
  (noon/haskell-search noon/haskell-structure-re limit))
(defun noon/haskell-deriving (limit)
  (noon/haskell-search "\\_<deriving\\_>" limit))
(defun noon/haskell-strategy (limit)
  (noon/haskell-search noon/haskell-strategy-re limit))
(defun noon/haskell-import (limit)
  (noon/haskell-search "^[ \t]*\\(import\\)\\_>" limit))
(defun noon/haskell-import-word (limit)
  (noon/haskell-search noon/haskell-import-word-re limit))
;; `family' is a keyword only in `type family' / `data family'; elsewhere
;; it is an ordinary name (a record field, say). Same for the strategy
;; words, which only count on a `deriving' line -- hence the anchored
;; rules rather than one flat keyword list.
(defun noon/haskell-family (limit)
  (noon/haskell-search "\\_<\\(?:type\\|data\\)\\_>[ \t]+\\(family\\)\\_>" limit))

(font-lock-add-keywords
 'haskell-mode
 '((noon/haskell-structure 0 'font-lock-type-face t)
   (noon/haskell-family    1 'font-lock-type-face t)
   (noon/haskell-deriving
    (noon/haskell-strategy (line-end-position) nil
                           (0 'font-lock-type-face t)))
   (noon/haskell-import
    (1 'font-lock-preprocessor-face t)
    (noon/haskell-import-word (line-end-position) nil
                              (0 'font-lock-preprocessor-face t))))
 'append)

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

;; No inlay hints. Eglot switches `eglot-inlay-hints-mode' on by itself
;; whenever the server advertises :inlayHintProvider, and HLS's
;; explicit-fields plugin then splices record-field names into the
;; buffer as overlays -- "$sel:notApplicableReason:WaitOnNotApplicableTx="
;; and friends. It is not real text (no file on disk changes), but it
;; reflows the line and nvim shows none of it.
(setq eglot-ignored-server-capabilities '(:inlayHintProvider))

;; eglot's built-in entry is ("haskell-language-server-wrapper" "--lsp"),
;; but a nix devshell puts the plain `haskell-language-server' on PATH and
;; no wrapper at all (the wrapper only exists to pick a GHC-matched binary,
;; which nix has already done). Resolve at connect time so both layouts
;; work; without this, eglot dies with "Searching for program: No such
;; file or directory, haskell-language-server-wrapper".
(with-eval-after-load 'eglot
  (add-to-list 'eglot-server-programs
               `((haskell-mode haskell-literate-mode)
                 . ,(lambda (&rest _)
                      (list (or (executable-find "haskell-language-server-wrapper")
                                (executable-find "haskell-language-server")
                                "haskell-language-server-wrapper")
                            "--lsp")))))

(defun noon/maybe-start-hls ()
  "Attach eglot when this is Haskell and the project shell provides HLS.
On `find-file-hook', NOT `haskell-mode-hook': envrc is a globalized
minor mode, so it switches itself on from `after-change-major-mode-hook'
-- which runs after the major mode's own hook. At haskell-mode-hook time
the direnv PATH is therefore not in place yet, `executable-find' returns
nil, and eglot never starts at all. `find-file-hook' runs after both."
  (when (and (derived-mode-p 'haskell-mode)
             (or (executable-find "haskell-language-server-wrapper")
                 (executable-find "haskell-language-server")))
    (eglot-ensure)))
(add-hook 'find-file-hook #'noon/maybe-start-hls)

;; -- Non-blocking jump-to-definition / references --------------------------
;;
;; eglot's xref backend calls `jsonrpc-request', which blocks redisplay and
;; input for `jsonrpc-default-request-timeout' (10s) and passes no
;; :cancel-on-input -- so a slow server freezes the editor outright, and
;; then the request is dropped and nothing happens. On a project the size
;; of hydra that is the normal case, not the exception. These send the same
;; requests with `jsonrpc-async-request' and act on the reply when it turns
;; up; the cursor keeps moving in the meantime.

(defvar noon/eglot-async-timeout 120
  "Seconds to wait for an async LSP xref reply before giving up.
Generous on purpose: nothing is blocked while we wait.")

(defun noon/eglot--xrefs (response sym)
  "Convert a Location/LocationLink RESPONSE for SYM into xref items."
  (eglot--collecting-xrefs (collect)
    (mapc (lambda (loc)
            (eglot--dcase loc
              (((LocationLink) targetUri targetSelectionRange)
               (collect (eglot--xref-make-match sym targetUri targetSelectionRange)))
              (((Location) uri range)
               (collect (eglot--xref-make-match sym uri range)))))
          (if (vectorp response) response (and response (list response))))))

(defun noon/eglot-xref-async (method capability what show)
  "Ask the server for METHOD at point without blocking.
CAPABILITY is checked first, WHAT names the query for messages, and SHOW
is the xref display function to hand the results to."
  (eglot-server-capable-or-lose capability)
  (let* ((server (eglot--current-server-or-lose))
         (sym (symbol-name (or (symbol-at-point) '\?)))
         (params (append (eglot--TextDocumentPositionParams)
                         (when (eq method :textDocument/references)
                           '(:context (:includeDeclaration t)))))
         (buf (current-buffer))
         (t0 (float-time)))
    (message "%s: %s..." what sym)
    (force-mode-line-update)
    (jsonrpc-async-request
     server method params
     :success-fn
     (lambda (response)
       ;; This runs from a process filter, where `current-buffer' is
       ;; whatever Emacs happened to have current -- never the buffer we
       ;; asked from. "Is the user still here?" is a question about the
       ;; selected window, so ask it that way and re-establish the
       ;; buffer/window ourselves before handing over to xref (which
       ;; records them for the jump-back marker).
       (let ((secs (- (float-time) t0))
             (win (selected-window)))
         (cond
          ((not (buffer-live-p buf)) nil)
          ;; Wandering off mid-flight is the whole point of being async;
          ;; do not yank the user back to where they started.
          ((not (eq (window-buffer win) buf))
           (message "%s for `%s' ready after %.1fs (you moved on; run it again)"
                    what sym secs))
          (t
           (let ((xrefs (with-current-buffer buf
                          (noon/eglot--xrefs response sym))))
             (if (null xrefs)
                 (message "No %s for `%s' (%.1fs)" what sym secs)
               ;; Display from the main loop, not from here. The display
               ;; functions read the minibuffer now, and entering it from
               ;; a process filter runs Emacs's input loop underneath the
               ;; jsonrpc connection whose output is still being read.
               ;; The window test is repeated there because the answer to
               ;; "is the user still here?" can change in between.
               ;;
               ;; A timer body runs under `inhibit-quit', so the read has
               ;; to be wrapped for C-g to leave it; and a minibuffer that
               ;; is already open cannot be entered a second time (this
               ;; config leaves `enable-recursive-minibuffers' nil), which
               ;; from inside a timer would surface as nothing more than
               ;; "Error running timer".
               (run-at-time
                0 nil
                (lambda ()
                  (when (and (window-live-p win)
                             (eq (window-buffer win) buf))
                    (if (active-minibuffer-window)
                        (message "%s for `%s' ready -- ask again from here"
                                 what sym)
                      (with-local-quit
                        (with-selected-window win
                          (with-current-buffer buf
                            (funcall show (lambda () xrefs) nil))))))))))))
         (force-mode-line-update)))
     :error-fn
     (lambda (err)
       (message "%s for `%s' failed: %s" what sym (plist-get err :message))
       (force-mode-line-update))
     :timeout noon/eglot-async-timeout
     :timeout-fn
     (lambda ()
       (message "%s for `%s': no answer from the server in %ss"
                what sym noon/eglot-async-timeout)
       (force-mode-line-update)))))

;; gd/gr answer in the minibuffer instead of splitting off an xref window
;; that then has to be closed. These are xref's own display hooks, so this
;; covers every xref caller here, not just the two commands below:
;;
;;   definitions  `xref-show-definitions-completing-read' goes straight
;;                there when the server names one place (gd's usual case)
;;                and only asks when there are several.
;;   references   `consult-xref' lists the usages through vertico -- 15
;;                rows like every other picker here -- previewing the one
;;                at point as you move. RET jumps, escape leaves you put.
;;
;; Both read the minibuffer, which is why the reply below is handed to
;; them from a timer rather than from the jsonrpc filter it arrives in.
(with-eval-after-load 'xref
  (setq xref-show-definitions-function #'xref-show-definitions-completing-read
        xref-show-xrefs-function #'consult-xref))

(defun noon/eglot-find-definitions ()
  "Jump to the definition at point, without blocking Emacs."
  (interactive)
  (noon/eglot-xref-async :textDocument/definition :definitionProvider
                         "definition" #'xref--show-defs))

(defun noon/eglot-find-references ()
  "List references to the symbol at point, without blocking Emacs."
  (interactive)
  (noon/eglot-xref-async :textDocument/references :referencesProvider
                         "references" #'xref--show-xrefs))

(defun noon/flymake-diagnostic-at-point ()
  "Pop the diagnostics under point into an eldoc-box child frame.
`K' reaches them too, but only as whatever eldoc last composed at this
position -- HLS's hover doc first, the diagnostic appended. This is the
diagnostic alone, computed now. Deliberately not inline: HLS reports
cradle failures as one 300-character line, and flymake's end-of-line
overlay wraps it across four rows of the buffer."
  (interactive)
  (require 'eldoc-box)
  (if-let* ((diags (flymake-diagnostics (point))))
      (let ((eldoc-box-position-function eldoc-box-at-point-position-function))
        ;; visual-line-mode in the box buffer wraps the long ones.
        (eldoc-box--display
         (mapconcat
          (lambda (d)
            (propertize (flymake-diagnostic-text d)
                        'face (flymake--lookup-type-property
                               (flymake-diagnostic-type d)
                               'echo-face 'flymake-error)))
          diags "\n\n"))
        ;; Same dismissal as `eldoc-box-help-at-point': the frame goes
        ;; away as soon as point moves off.
        (setq eldoc-box--help-at-point-last-point (point))
        (run-with-timer 0.1 nil #'eldoc-box--help-at-point-cleanup))
    (message "no diagnostics at point")))

(with-eval-after-load 'eglot       ; = haskell.lua's on_attach bindings
  ;; D and C used to be here, which cost `evil-delete-line' and
  ;; `evil-change-line' in every managed buffer. A bare `hd'/`hc' would
  ;; be worse still: it turns `h' into a prefix, so plain left-motion
  ;; stalls waiting for a second key. `,' is the leader everywhere else
  ;; here (,gs magit, ,o* org, ,h* diff-hl hunks), so LSP takes ,l*.
  (evil-define-key 'normal eglot-mode-map
    "gd"  #'noon/eglot-find-definitions
    "gr"  #'noon/eglot-find-references
    ;; nvim's K is a hover float, not a split. `eldoc-doc-buffer' stole
    ;; half the frame for a type signature; eldoc-box puts it in a child
    ;; frame at point, which emacs 31 can draw on a tty. Press it again
    ;; to focus the frame (to scroll a long HLS doc); any other key
    ;; dismisses it.
    "K"   #'eldoc-box-help-at-point
    ",ld" #'flymake-show-buffer-diagnostics
    ",le" #'noon/flymake-diagnostic-at-point
    ",lc" #'eglot-code-actions
    ",ln" #'flymake-goto-next-error
    ",lp" #'flymake-goto-prev-error
    ",lr" #'eglot-rename
    ",lf" #'eglot-format))

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

;; -- Markdown --------------------------------------------------------------

;; A nox build, so nothing in-frame renders markdown properly: inline
;; images and the xwidget preview both want a GUI, and the built-in
;; `markdown-live-preview-mode' only gets as far as eww, which flattens
;; the result. Previewing is therefore go-grip's job (installed in
;; home.nix) -- GitHub styling in a real browser tab, and it watches the
;; file, so the tab follows every save. What stays in the buffer is
;; markup hiding (`,mh'): `**bold**' drops its asterisks and goes bold,
;; links show only their text, and it is still editable.
;;
;; edit-indirect needs no config -- markdown-mode soft-requires it, and
;; having it installed is what makes `C-c '' open a fenced code block in
;; a buffer running its own major mode (haskell-mode, nix-mode, ...).
(use-package markdown-mode
  :defer t
  ;; Off by default, which leaves fenced blocks a flat wall of string face.
  :init (setq markdown-fontify-code-blocks-natively t)
  ;; Prose, not code: soft-wrap (`j'/`k' are already visual-line motions).
  :hook ((markdown-mode . visual-line-mode)
         (markdown-mode . noon/markdown-tab-setup)))

(defun noon/markdown-tab-setup ()
  "Make TAB insert indentation in prose, at the 2 columns used elsewhere.
markdown-mode sets `tab-width' to 4, and the default `tab-always-indent'
only ever *re-indents* the line -- which on a prose line, where there is
no indentation to compute, means doing nothing at all.  With it nil, TAB
in the leading whitespace still runs markdown's own list-aware
`markdown-indent-line', and anywhere else inserts to the next stop (as
spaces, `indent-tabs-mode' being nil) -- vim's expandtab/sts=2."
  (setq-local tab-width 2
              tab-always-indent nil))

;; One server at a time: go-grip binds a fixed port (6419), so a second
;; one exits rather than sharing it.
(defvar noon/go-grip-process nil
  "The running go-grip preview server, if any.")

(defun noon/go-grip-quit ()
  "Stop the running go-grip preview server."
  (interactive)
  (when (process-live-p noon/go-grip-process)
    (kill-process noon/go-grip-process))
  (setq noon/go-grip-process nil))

(defun noon/go-grip ()
  "Preview the current file with go-grip, in a browser tab.
go-grip reads from disk rather than from the buffer, but reloads the
tab whenever the file changes -- so the preview tracks saves, not
edits. The daemon starts after graphical-session.target (see
emacs.nix), so DISPLAY is set and go-grip can find a browser."
  (interactive)
  (unless buffer-file-name
    (user-error "Buffer %s does not visit a file" (buffer-name)))
  (noon/go-grip-quit)
  (setq noon/go-grip-process
        (start-process "go-grip" "*go-grip*" "go-grip" buffer-file-name))
  ;; Don't hold up `kill-emacs' asking about it.
  (set-process-query-on-exit-flag noon/go-grip-process nil)
  (message "go-grip: serving %s" (file-name-nondirectory buffer-file-name)))

(with-eval-after-load 'markdown-mode
  ;; markdown-mode puts TAB on `markdown-cycle' -- heading visibility
  ;; cycling, which on a prose line does nothing whatsoever -- and
  ;; evil-collection puts the same command on `<tab>' in its normal-state
  ;; auxiliary map for the mode. kkp has ghostty reporting the tab key as
  ;; `<tab>' (see `global-kkp-mode' above) and an aux map outranks the
  ;; plain mode map, so in a markdown buffer the key reached neither the
  ;; indent nor the `noon-tab-map' prefix. Clearing both layers leaves
  ;; `<tab>' to fall back to TAB, as it does in every other mode.
  ;;
  ;; TAB indents again; `markdown-cycle' moves to `,mc'.
  (define-key markdown-mode-map (kbd "TAB") nil)
  (evil-define-key 'normal markdown-mode-map (kbd "<tab>") nil)
  ;; localleader, as in agda2-mode above and org below.
  (evil-define-key 'normal markdown-mode-map
    ",mp" #'noon/go-grip
    ",mq" #'noon/go-grip-quit
    ",mh" #'markdown-toggle-markup-hiding
    ",mc" #'markdown-cycle))

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

;; Browsing a diff is walking hunks, so n/p walk hunks -- magit's own
;; keys for that, which evil-collection moves out from under you: the
;; section motions land on `C-j'/`C-k' (`]'/`[' between siblings), `n'
;; keeps evil's search-repeat, and `p' becomes `magit-push', which is one
;; keystroke away from a push transient where a motion was meant. Push
;; goes back to magit's own `P', which evil-collection leaves bound;
;; search-repeat backwards is still `N'.
;;
;; A hunk is just a section, so step until we land on one; where no hunk
;; follows -- a collapsed status buffer, the last file of a diff -- fall
;; back to a single plain section move, magit's own `n'/`p' behaviour, so
;; the key always goes somewhere. From inside a hunk, p goes to its
;; heading first (`magit-section-backward' moves to the beginning of the
;; current section), then to the hunk before it.
;;
;; This has to be registered after `evil-collection-init' above: both
;; hang off `with-eval-after-load 'magit' and those run in the order
;; they were registered, so the later one wins the auxiliary keymap.
(with-eval-after-load 'magit
  (defun noon/magit--goto-hunk (step)
    "Call STEP until point is on a hunk; stay put if no hunk is that way.
Returns whether one was found."
    (let ((start (point)) (found nil) (moved t))
      (while (and moved (not found))
        (let ((from (point)))
          ;; The section motions signal at the first/last section.
          (setq moved (and (ignore-errors (funcall step) t)
                           (/= (point) from)))
          (when (and moved (magit-section-match 'hunk))
            (setq found t))))
      (unless found (goto-char start))
      found))

  (defun noon/magit-next-hunk ()
    "Go to the next hunk, or to the next section if no hunk follows."
    (interactive)
    (unless (noon/magit--goto-hunk #'magit-section-forward)
      (magit-section-forward)))

  (defun noon/magit-previous-hunk ()
    "Go to the previous hunk, or to the previous section if none precedes."
    (interactive)
    (unless (noon/magit--goto-hunk #'magit-section-backward)
      (magit-section-backward)))

  (evil-define-key 'normal magit-mode-map
    "n" #'noon/magit-next-hunk
    "p" #'noon/magit-previous-hunk))

;; -- Git gutter (diff-hl) --------------------------------------------------

;; gitsigns-nvim's counterpart. A tty has no fringes, so the +/-/!
;; markers go in the left margin. The hunk popup defaults to the
;; tty-safe `diff-hl-show-hunk-inline', which splices the hunk into the
;; buffer and pushes the surrounding lines around; the posframe backend
;; floats it instead. That backend used to be GUI-only -- it gates on
;; `posframe-workable-p', which as of emacs 31 also accepts a tty with
;; `tty-child-frames'.
(use-package diff-hl
  :init
  (setq diff-hl-show-hunk-function #'diff-hl-show-hunk-posframe)
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
  ;; S-SPC (a real key -- see kkp) asks "what changed on this line?" and
  ;; asks again to dismiss. Three details of the popup shape this:
  ;;
  ;; - It hides on any command outside `diff-hl-show-hunk-ignorable-
  ;;   commands', and that hook runs for the command that opened it too,
  ;;   so this one has to be on the list or it dismisses its own popup.
  ;; - "Is a popup showing?" is the transient mode. It is not
  ;;   `diff-hl-show-hunk--hide-function', which dismissal by an
  ;;   unrelated key leaves set -- and `diff-hl-show-hunk-hide' ends by
  ;;   restoring the window it recorded, so acting on that stale flag
  ;;   jumps into whichever file the last popup was opened in.
  ;; - `diff-hl-show-hunk' walks point to the nearest hunk above when
  ;;   this line has no change of its own. Say so and stay put instead;
  ;;   ]c is right there for going to a hunk.
  ;;
  ;; Closing leaves point on the hunk that was shown, which is diff-hl's
  ;; placement (it anchors the popup below the hunk), not a choice here.
  (defun noon/toggle-hunk ()
    "Show the diff hunk at point, or hide the hunk popup already showing."
    (interactive)
    (cond
     ((bound-and-true-p diff-hl-show-hunk-posframe--transient-mode)
      (diff-hl-show-hunk-hide))
     ((diff-hl-hunk-overlay-at (point))
      (diff-hl-show-hunk))
     (t (message "No change on this line"))))
  (add-to-list 'diff-hl-show-hunk-ignorable-commands #'noon/toggle-hunk)
  ;; The popup does not take the cursor with it -- posframe's
  ;; `select-window' sits inside a `with-selected-frame', which puts the
  ;; selection back -- so its own keys (n/p between changes, q to close,
  ;; c/e/r/S) are read in the file buffer, where evil's state maps
  ;; outrank the minor-mode map they live in. n searched and p pasted
  ;; instead, and being unrelated commands they dismissed the popup on
  ;; the way. (The overlay keymap posframe also installs would win, but
  ;; it covers the popup buffer, which nothing ever selects.)
  ;;
  ;; `substitute-command-keys' finds no unshadowed key either, so the
  ;; header line's hints fall back to the one map that still has these
  ;; commands -- `diff-hl-command-map', on the `C-x v' prefix -- whence
  ;; "Previous change in hunk (C-x v {)".
  ;;
  ;; So tell evil the map overrides it, and re-normalize on both edges of
  ;; the transient mode, in the file buffer as much as the popup's own.
  (defun noon--hunk-popup-sync ()
    "Recompute evil's keymaps wherever the popup's keys have to work."
    (evil-normalize-keymaps)                ; the popup buffer, on the way in
    (when (buffer-live-p diff-hl-show-hunk--original-buffer)
      (with-current-buffer diff-hl-show-hunk--original-buffer
        (evil-normalize-keymaps))))         ; where the keys are actually read
  (with-eval-after-load 'diff-hl-show-hunk-posframe
    (evil-make-overriding-map diff-hl-show-hunk-posframe--transient-mode-map
                              'normal)
    (add-hook 'diff-hl-show-hunk-posframe--transient-mode-hook
              #'noon--hunk-popup-sync))
  (with-eval-after-load 'evil
    (evil-define-key 'normal 'global
      "]c"  #'diff-hl-next-hunk           ; vim's diff motions; evil leaves
      "[c"  #'diff-hl-previous-hunk       ; ]c/[c free (it binds ]f ]F ]s)
      (kbd "S-SPC") #'noon/toggle-hunk
      ",hh" #'noon/toggle-hunk
      ",hr" #'diff-hl-revert-hunk
      ",hs" #'diff-hl-stage-dwim)))

;; -- direnv (keep last: hooks added last run first, and envrc's
;; find-file hook must run before eglot looks for HLS) ----------------------

(use-package envrc
  :init (setq envrc-direnv-executable "direnv"
              ;; A nix devshell exports hundreds of vars, and envrc echoes
              ;; the whole +VAR/~VAR/-VAR diff into the echo area on every
              ;; visit. The mode-line lighter (envrc[on]) already says
              ;; whether direnv took; `envrc-reload' reports failures.
              envrc-show-summary-in-minibuffer nil)
  :config (envrc-global-mode 1))
