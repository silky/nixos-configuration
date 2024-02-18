; Default to mononoki
(set-face-attribute
  'default nil
  :family "mononoki"
  :height 120
  :weight 'normal
  :width  'normal
  )


; UI
; (setq inhibit-startup-screen t)
(setq inhibit-startup-message t)
(setq visible-bell t)
(setq make-backup-files nil)
(setq sentence-end-double-space nil)
(setq-default show-trailing-whitespace t)
(setq-default indicate-empty-lines t)

(scroll-bar-mode -1)
(tool-bar-mode -1)
(menu-bar-mode -1)
(set-fringe-mode 10)
(tooltip-mode -1)


; Auto-completion
(use-package company)
(add-hook 'after-init-hook 'global-company-mode)
