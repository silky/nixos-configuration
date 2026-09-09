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

;; Window separator: emacs draws the tty vertical border with ASCII `|',
;; which leaves a gap between rows and reads as a dashed line. nvim's
;; default `fillchars' vert is U+2502 BOX DRAWINGS LIGHT VERTICAL, which
;; joins up; the display table is how a tty frame picks the glyph. The
;; colour already matches -- `vertical-border' sets no attributes, so it
;; falls through to `default' (#444444), exactly like nvim's
;; WinSeparator here.
(unless standard-display-table
  (setq standard-display-table (make-display-table)))
(set-display-table-slot standard-display-table 'vertical-border ?│)

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
           (with-selected-window win
             (with-current-buffer buf
               (let ((xrefs (noon/eglot--xrefs response sym)))
                 (if (null xrefs)
                     (message "No %s for `%s' (%.1fs)" what sym secs)
                   (funcall show (lambda () xrefs) nil)))))))
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

(with-eval-after-load 'eglot       ; = haskell.lua's on_attach bindings
  ;; D and C used to be here, which cost `evil-delete-line' and
  ;; `evil-change-line' in every managed buffer. A bare `hd'/`hc' would
  ;; be worse still: it turns `h' into a prefix, so plain left-motion
  ;; stalls waiting for a second key. `,' is the leader everywhere else
  ;; here (,gs magit, ,o* org, ,h* diff-hl hunks), so LSP takes ,l*.
  (evil-define-key 'normal eglot-mode-map
    "gd"  #'noon/eglot-find-definitions
    "gr"  #'noon/eglot-find-references
    "K"   #'eldoc-doc-buffer
    ",ld" #'flymake-show-buffer-diagnostics
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
  :init (setq envrc-direnv-executable "direnv"
              ;; A nix devshell exports hundreds of vars, and envrc echoes
              ;; the whole +VAR/~VAR/-VAR diff into the echo area on every
              ;; visit. The mode-line lighter (envrc[on]) already says
              ;; whether direnv took; `envrc-reload' reports failures.
              envrc-show-summary-in-minibuffer nil)
  :config (envrc-global-mode 1))
