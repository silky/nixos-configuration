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
   ;; vim has no doc-comment group: haddock (-- |), elisp docstrings and
   ;; friends all land on Comment, which is not italic. String is (see
   ;; below), so the italic here was a mis-port, not a choice.
   '(font-lock-doc-face ((t (:foreground "#004cff"))))
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
   ;; On a tty `vertical-border' has no colours of its own -- its default
   ;; spec is (((type tty)) :inherit mode-line-inactive), so it picked up
   ;; that :underline and drew a dash in every cell of the window
   ;; separator. State it outright instead: nvim's WinSeparator here is
   ;; plain fg-on-bg, no attributes.
   `(vertical-border ((t (:foreground ,fg :background ,bg
                          :underline nil :inherit unspecified))))
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
   ;; diff-hl margin markers: foreground only (a background block behind a
   ;; single margin character reads as a smudge). insert/delete reuse the
   ;; magit-diff foregrounds above; change would otherwise default to a cold
   ;; #ddddff that fights the warm background, and blue collides with
   ;; font-lock-comment-face, so it takes the builtin violet.
   '(diff-hl-insert ((t (:background unspecified :foreground "#005f00"))))
   '(diff-hl-delete ((t (:background unspecified :foreground "#9f0000"))))
   '(diff-hl-change ((t (:background unspecified :foreground "#b56bfa"))))
   ;; evil-quickscope / avy (easymotion targets)
   '(evil-quickscope-first-face ((t (:foreground "#ff00ff" :underline t))))
   '(evil-quickscope-second-face ((t (:foreground "#d700ff"))))
   '(avy-lead-face ((t (:background "#87ffaf" :foreground "#444444" :weight bold))))
   '(avy-lead-face-0 ((t (:background "#ffd7d7" :foreground "#444444" :weight bold))))))

(provide-theme 'noon-light)
