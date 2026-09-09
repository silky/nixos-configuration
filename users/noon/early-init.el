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
