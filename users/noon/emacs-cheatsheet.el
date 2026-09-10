#!/usr/bin/env -S emacs --no-site-file --script
;;; emacs-cheatsheet.el --- keybinding cheat-sheet generated from init.el -*- lexical-binding: t -*-

;; --no-site-file only to keep "Loading .../site-start" off ./build's
;; output; the packages below still resolve, because the nix emacs
;; wrapper puts them on EMACSLOADPATH rather than in site-start.

;; Reads init.el with the Lisp reader (not regexps) and writes a markdown
;; table of every key this configuration binds itself. Package defaults --
;; evil's own motions, magit, evil-collection -- are deliberately absent:
;; this answers "what did I change", which is the part no manual covers.
;;
;;   ./emacs-cheatsheet.el                          # init.el -> EMACS-KEYS.md
;;   ./emacs-cheatsheet.el path/to/init.el out.md
;;
;; Descriptions come from docstrings. For noon/* commands those are read
;; straight out of init.el, because actually loading init.el in batch
;; wedges on the terminal/direnv setup; for everything else the relevant
;; packages are required and `documentation' is consulted. Commands from
;; packages that cannot load headlessly (agda2-mode, which is loaded from
;; whatever `agda-mode' is on PATH) simply come out blank.

(require 'cl-lib)
(require 'subr-x)

;;;; ---------------------------------------------------------------- config

(defconst cheat/binding-heads
  '(define-key evil-define-key evil-ex-define-cmd evilem-default-keybindings
     keymap-global-unset)
  "Forms that introduce, move or remove a binding.
Note that `keymap-global-set' is absent: init.el does not use it. Add it
here, with a branch in `cheat/collect', if that changes.")

(defconst cheat/doc-packages
  '(evil evil-commentary evil-lion evil-easymotion evil-quickscope
         magit projectile diff-hl diff-hl-show-hunk eglot xref flymake
         eldoc eldoc-box org dired)
  "Loaded, best-effort, only so `documentation' can be consulted.")

(defconst cheat/state-map-names
  '(("evil-normal-state-map" . "normal")
    ("evil-visual-state-map" . "visual")
    ("evil-motion-state-map" . "motion")
    ("evil-insert-state-map" . "insert")
    ("evil-emacs-state-map"  . "Emacs")
    ("evil-operator-state-map" . "operator"))
  "Evil's global per-state maps, so that `(define-key evil-normal-state-map ...)'
and `(evil-define-key 'normal 'global ...)' land in one group.")

(defconst cheat/min-note-length 16
  "Notes shorter than this are labels like \"magit\", not explanations.")

;;;; ------------------------------------------------------------ extraction

(defun cheat/first-sentence (text)
  "First sentence of TEXT, flattened to a single line."
  (when text
    (let* ((flat (string-join (split-string text "[ \t\n]+" t) " ")))
      (if (string-match "\\`\\(.*?[.!?]\\)\\(?: \\|\\'\\)" flat)
          (match-string 1 flat)
        (truncate-string-to-width flat 100 nil nil t)))))

(defun cheat/local-docstrings (buffer)
  "Map of symbol -> first docstring sentence for definitions in BUFFER.
Covers `defun' and `evil-define-command', at any indentation."
  (let ((table (make-hash-table :test #'eq)))
    (with-current-buffer buffer
      (save-excursion
        (goto-char (point-min))
        (while (re-search-forward "^[ \t]*(\\(defun\\|evil-define-command\\)[ \t]" nil t)
          (goto-char (match-beginning 0))
          (skip-chars-forward " \t")
          (let ((form (ignore-errors (read (current-buffer)))))
            (if (and (consp form) (memq (car form) '(defun evil-define-command)))
                (let ((name (nth 1 form))
                      (doc  (nth 3 form)))
                  (when (and (symbolp name) (stringp doc))
                    (puthash name (cheat/first-sentence doc) table)))
              (forward-line 1))))))
    table))

(defun cheat/comment-above (pos)
  "The contiguous ;; comment block immediately above POS, as one string."
  (save-excursion
    (goto-char pos)
    (forward-line 0)
    (let ((lines nil) (stop nil))
      (while (and (not stop) (zerop (forward-line -1)))
        (if (not (looking-at "^[ \t]*;;+ ?\\(.*\\)$"))
            (setq stop t)
          (let ((text (string-trim (match-string 1))))
            (cond
             ;; a section rule (;; -- Foo ----) is a heading, not a note
             ((string-prefix-p "--" text) (setq stop t))
             ((string-empty-p text) (setq stop t))
             (t (push text lines))))))
      (when lines (string-join lines " ")))))

(defun cheat/dolist-maps (sym pos)
  "If SYM is the variable of a `dolist' over a list of maps above POS,
return those maps, so that

    (dolist (map (list a-map b-map)) (define-key map ...))

is reported against a-map and b-map rather than the loop variable."
  (save-excursion
    (goto-char pos)
    (when (re-search-backward
           (format "(dolist (%s (list " (regexp-quote (symbol-name sym)))
           (max (point-min) (- pos 2000)) t)
      (let ((form (ignore-errors (read (current-buffer)))))
        (when (and (consp form) (eq (car form) 'dolist))
          (let ((spec (nth 1 form)))
            (when (and (eq (car spec) sym)
                       (consp (cadr spec))
                       (eq (car (cadr spec)) 'list))
              (cdr (cadr spec)))))))))

(defun cheat/read-binding-forms (buffer)
  "Every binding form in BUFFER as (FORM . POSITION), in source order."
  (let (found)
    (with-current-buffer buffer
      (dolist (head cheat/binding-heads)
        (save-excursion
          (goto-char (point-min))
          (while (re-search-forward
                  (format "(%s\\_>" (regexp-quote (symbol-name head))) nil t)
            (let ((start (match-beginning 0)))
              (goto-char start)
              (let ((form (ignore-errors (read (current-buffer)))))
                (if form
                    (push (cons form start) found)
                  (goto-char (1+ start)))))))))
    (sort found (lambda (a b) (< (cdr a) (cdr b))))))

;;;; ------------------------------------------------------------- rendering

(defun cheat/code (s)
  "S as a markdown code span, coping with S containing a backtick."
  (if (string-match-p "`" s) (format "`` %s ``" s) (format "`%s`" s)))

(defun cheat/plain-dashes (s)
  "Fold em and en dashes to ASCII hyphens.
The generated document keeps to ASCII punctuation, and docstrings from
elsewhere are not guaranteed to."
  (replace-regexp-in-string "[—–]" "-" (or s "")))

(defun cheat/md-escape (s)
  (cheat/plain-dashes (replace-regexp-in-string "|" "\\\\|" (or s ""))))

(defun cheat/key-sequence (expr)
  "Resolve EXPR -- a string literal or (kbd \"...\") -- to a key sequence."
  (cond ((stringp expr) expr)
        ((vectorp expr) expr)
        ((and (consp expr) (eq (car expr) 'kbd) (stringp (cadr expr)))
         (kbd (cadr expr)))
        (t nil)))

(defun cheat/key-label (key)
  "Render KEY the way you would type it."
  (cond
   ((null key) "?")
   ;; all-graphic strings read better verbatim (,gs) than spaced (, g s)
   ((and (stringp key)
         (not (string-empty-p key))
         (cl-every (lambda (c) (and (> c 32) (< c 127))) key))
    key)
   (t (key-description key))))

(defun cheat/def-symbol (def)
  (cond ((and (consp def) (memq (car def) '(function quote))) (cadr def))
        ((and (symbolp def) def) def)))

(defun cheat/def-label (def)
  (cond
   ((null def) "*unbound*")
   ((eq def 'cheat--easymotion) "*evil-easymotion*")
   ((stringp def) (format "keyboard macro %s" (cheat/code def)))
   ((cheat/def-symbol def) (cheat/code (symbol-name (cheat/def-symbol def))))
   (t (cheat/code (format "%S" def)))))

(defun cheat/describe (def local-docs)
  "One-line description of DEF, from init.el's docstrings or the command's."
  (let ((sym (cheat/def-symbol def)))
    (cond
     ((null def) "removed, so the key falls through")
     ((eq def 'cheat--easymotion)
      "prefix: follow with a motion (w, e, j, f, ...) to jump to a target")
     ((stringp def) (format "replays the keys %s" (cheat/code def)))
     ((and sym (gethash sym local-docs)))
     ((and sym (string-suffix-p "-map" (symbol-name sym))) "prefix map")
     ((and sym (fboundp sym))
      (or (cheat/first-sentence (ignore-errors (documentation sym))) ""))
     (t ""))))

;;;; -------------------------------------------------------------- collection

(cl-defstruct (cheat/bind (:constructor cheat/bind-make))
  map state key def note pos)

(defun cheat/map-name (map)
  (let ((m (if (and (consp map) (eq (car map) 'quote)) (cadr map) map)))
    (cond ((eq m 'global) "Global")
          ((symbolp m) (symbol-name m))
          (t (format "%S" m)))))

(defun cheat/states (state)
  "STATE as a list of state-name strings."
  (let ((s (if (and (consp state) (eq (car state) 'quote)) (cadr state) state)))
    (cond ((null s) (list nil))
          ((listp s) (mapcar #'symbol-name s))
          (t (list (symbol-name s))))))

(defun cheat/collect (buffer)
  "All bindings this config makes, as `cheat/bind' records."
  (let ((rows nil))
    (with-current-buffer buffer
      (pcase-dolist (`(,form . ,pos) (cheat/read-binding-forms buffer))
        (let ((note (cheat/comment-above pos)))
          (pcase form
            (`(define-key ,map ,key ,def)
             (let ((maps (if (and (symbolp map)
                                  (not (string-suffix-p "-map" (symbol-name map))))
                             (or (cheat/dolist-maps map pos) (list map))
                           (list map))))
               (dolist (m maps)
                 (push (cheat/bind-make
                        :map (cheat/map-name m) :state nil
                        :key (cheat/key-label (cheat/key-sequence key))
                        :def def :note note :pos pos)
                       rows))))
            (`(evil-define-key ,state ,map . ,pairs)
             ;; one row per state, so a normal+visual binding shows up in both
             (dolist (st (cheat/states state))
               (let ((ps pairs))
                 (while (cdr ps)
                   (push (cheat/bind-make
                          :map (cheat/map-name map) :state st
                          :key (cheat/key-label (cheat/key-sequence (car ps)))
                          :def (cadr ps) :note note :pos pos)
                         rows)
                   (setq ps (cddr ps))))))
            ;; the trailing _ is the optional REMOVE argument
            (`(keymap-global-unset ,key . ,_)
             (push (cheat/bind-make
                    :map "Global" :state nil
                    ;; `keymap-*' take `key-valid-p' syntax ("M-f"), which
                    ;; is not a literal key sequence -- parse, do not pass
                    ;; the string through as if it were one.
                    :key (cheat/key-label
                          (and (stringp key) (ignore-errors (key-parse key))))
                    :def nil :note note :pos pos)
                   rows))
            (`(evil-ex-define-cmd ,name ,def)
             (push (cheat/bind-make
                    :map "Ex commands" :state nil :key (format ":%s" name)
                    :def def :note note :pos pos)
                   rows))
            (`(evilem-default-keybindings ,prefix)
             ;; no single command behind this one -- it is a whole family
             (dolist (st '("normal" "visual"))
               (push (cheat/bind-make
                      :map "Global" :state st :key prefix
                      :def 'cheat--easymotion :note note :pos pos)
                     rows)))))))
    (nreverse rows)))

(defun cheat/dedupe (rows)
  "Drop rows repeating a key already covered in the same group.
`.' is both unbound from `evil-normal-state-map' and claimed by
easymotion; the informative row is the one worth printing."
  (let ((seen (make-hash-table :test #'equal)) (out nil))
    (dolist (r rows)
      (let* ((k (cons (cheat/group-name r) (cheat/bind-key r)))
             (prev (gethash k seen)))
        (cond
         ((null prev) (puthash k r seen) (push r out))
         ;; prefer a row that names a command over a bare unbinding
         ((and (null (cheat/bind-def prev)) (cheat/bind-def r))
          (setf (cheat/bind-def prev) (cheat/bind-def r))
          (setf (cheat/bind-note prev)
                (or (cheat/bind-note prev) (cheat/bind-note r)))))))
    (nreverse out)))

;;;; ----------------------------------------------------------- prefix chains

(defun cheat/prefix-parents (rows)
  "Map of prefix-map-name -> list of (PARENT-MAP-NAME . KEY)."
  (let ((table (make-hash-table :test #'equal)))
    (dolist (r rows)
      (let ((sym (cheat/def-symbol (cheat/bind-def r))))
        (when (and sym (string-suffix-p "-map" (symbol-name sym))
                   ;; a state map is not a prefix
                   (not (assoc (symbol-name sym) cheat/state-map-names)))
          (push (cons (cheat/bind-map r) (cheat/bind-key r))
                (gethash (symbol-name sym) table)))))
    table))

(defun cheat/prefix-paths (map-name parents &optional seen)
  "Full typed prefixes for MAP-NAME, e.g. (\"TAB p\") for a nested map."
  (if (member map-name seen)
      nil
    (let ((entries (gethash map-name parents)))
      (if (null entries)
          nil
        (apply #'append
               (mapcar
                (lambda (e)
                  (let* ((parent (car e))
                         (key (cdr e))
                         (up (cheat/prefix-paths parent parents (cons map-name seen))))
                    (if up
                        (mapcar (lambda (u) (concat u " " key)) up)
                      (list key))))
                entries))))))

;;;; ---------------------------------------------------------------- grouping

(defun cheat/group-name (r)
  "Group heading for R, merging evil's global state maps into \"Global\"."
  (let* ((map (cheat/bind-map r))
         (state (cheat/bind-state r))
         (as-state (cdr (assoc map cheat/state-map-names))))
    (when as-state (setq map "Global" state as-state))
    (cond ((and (string= map "Global") state) (format "Global (%s state)" state))
          ;; a global map entry with no evil state applies everywhere
          ((string= map "Global") "Global (all states)")
          (state (format "%s (%s state)" map state))
          (t map))))

(defconst cheat/state-order '("normal" "visual" "motion" "operator" "insert" "Emacs"))

(defun cheat/group-rank (name)
  (cond
   ((string-prefix-p "Global" name)
    (let ((i (cl-position-if (lambda (s) (string-suffix-p (format "(%s state)" s) name))
                             cheat/state-order)))
      (+ 0 (or i 7))))
   ((string= "Ex commands" name) 90)
   (t 50)))

;;;; ---------------------------------------------------------------- output

(defun cheat/generate (init-file out-file)
  (with-temp-buffer
    (insert-file-contents init-file)
    (let* ((src (current-buffer))
           (local-docs (cheat/local-docstrings src))
           (rows (cheat/dedupe (cheat/collect src)))
           (parents (cheat/prefix-parents rows))
           (groups (make-hash-table :test #'equal))
           order)
      (dolist (r rows)
        (let ((g (cheat/group-name r)))
          (unless (gethash g groups) (push g order))
          (puthash g (cons r (gethash g groups)) groups)))
      (setq order (sort (nreverse order)
                        (lambda (a b)
                          (let ((ra (cheat/group-rank a)) (rb (cheat/group-rank b)))
                            (if (= ra rb) (string< a b) (< ra rb))))))
      (with-temp-file out-file
        (insert "# Emacs keybindings\n\n")
        (insert (format "Generated from `%s` by `emacs-cheatsheet.el`.\n\n"
                        (file-name-nondirectory init-file)))
        (insert "Only keys this configuration binds itself are listed. Evil's own\n"
                "motions and the defaults that ship with magit, dired and\n"
                "evil-collection are not.\n\n")
        (let (pnames)
          (maphash (lambda (k _v) (push k pnames)) parents)
          (when pnames
            (insert "## Prefix keys\n\n| Type | Then you are in |\n|---|---|\n")
            (dolist (p (sort pnames #'string<))
              (insert (format "| %s | `%s` |\n"
                              (mapconcat #'cheat/code
                                         (or (cheat/prefix-paths p parents) '("?"))
                                         " or ")
                              p)))
            (insert "\n")))
        (dolist (g order)
          (let* ((rs (nreverse (gethash g groups)))
                 (paths (cheat/prefix-paths g parents))
                 (pfx (car paths)))
            (insert (format "## %s\n\n" (if pfx (format "%s (the `%s` prefix)" g pfx) g)))
            (insert "| Key | Command | Does |\n|---|---|---|\n")
            (let ((described 0))
              (dolist (r rs)
                (let ((key (if pfx (format "%s %s" pfx (cheat/bind-key r))
                             (cheat/bind-key r)))
                      (doc (cheat/describe (cheat/bind-def r) local-docs)))
                  (unless (string-empty-p doc) (cl-incf described))
                  (insert (format "| %s | %s | %s |\n"
                                  (cheat/md-escape (cheat/code key))
                                  (cheat/md-escape (cheat/def-label (cheat/bind-def r)))
                                  (cheat/md-escape doc)))))
              (insert "\n")
              (when (and (zerop described) (> (length rs) 1))
                (insert "*(No descriptions: this package cannot be loaded headlessly,"
                        " so its docstrings are unavailable here.)*\n\n")))
            (let ((seen (make-hash-table :test #'equal)) (notes nil))
              (dolist (r rs)
                (let ((n (cheat/bind-note r)))
                  (when (and n
                             (>= (length n) cheat/min-note-length)
                             (not (gethash n seen)))
                    (puthash n t seen)
                    (push n notes))))
              (when notes
                (insert "> "
                        (cheat/plain-dashes
                         (string-join (nreverse notes) "\n>\n> "))
                        "\n\n")))))
        (insert "---\n\n")
        ;; ASCII punctuation only; fail loudly rather than quietly emit one
        (goto-char (point-min))
        (when (re-search-forward "[—–]" nil t)
          (error "%s: dash at line %d slipped past `cheat/plain-dashes'"
                 out-file (line-number-at-pos))))
      (message "wrote %s (%d bindings, %d groups)"
               out-file (length rows) (length order)))))

;;;; ------------------------------------------------------------------ main

(let* ((here (file-name-directory (or load-file-name buffer-file-name default-directory)))
       (init (or (nth 0 argv) (expand-file-name "init.el" here)))
       (out  (or (nth 1 argv) (expand-file-name "EMACS-KEYS.md" here))))
  (unless (file-readable-p init) (error "cannot read %s" init))
  (dolist (p cheat/doc-packages) (ignore-errors (require p)))
  (cheat/generate init out))

;;; emacs-cheatsheet.el ends here
