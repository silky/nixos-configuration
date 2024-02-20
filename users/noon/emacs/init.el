; More reading:
;
;  - <https://github.com/nix-community/emacs-overlay>
;  - <https://nixos.wiki/wiki/Emacs>
;  - <https://github.com/hlissner/dotfiles/blob/master/modules/editors/emacs.nix>
;  - <https://github.com/jwiegley/nix-config/blob/master/config/home.nix>
;  - <https://github.com/jwiegley/nix-config/blob/master/config/emacs.nix>
;  - <https://github.com/jwiegley/nix-config/blob/master/config/home.nix>
;  - <https://github.com/search?q=agda2-mode+language%3ANix+&type=code>
;  - <https://github.com/pimeys/nixos/blob/829c84322fed148ab69b3fe7ebdf09c11ba60ab0/desktop/emacs/config.org>
;  - <https://github.com/danderson/homelab/blob/2476c1a4f49689ed23ffe65649a78e6ced67982e/home/emacs/init.el>
;  - <https://github.com/search?q=emacsWithPackagesFromUsePackage&type=code>
;  - <https://github.com/purcell/emacs.d/blob/master/init.el>
;
; Default to mononoki
(set-face-attribute
  'default nil
  :family "mononoki"
  :height 140
  :weight 'normal
  :width  'normal
  )


; UI
(setq inhibit-startup-screen t)
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
(use-package company-web )
(add-hook 'after-init-hook 'global-company-mode)


(use-package ace-jump-mode)
(use-package ace-window)
(use-package doom-modeline)
(use-package org)
