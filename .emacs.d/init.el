;; My Emacs configuration
;; Author: Sibi <sibi@psibi.in>
;; File path: ~/.emacs.d/init.el
(server-start)

(setq package-archives
      '(("gnu"         . "http://elpa.gnu.org/packages/")
        ("original"    . "http://tromey.com/elpa/")
        ("org"         . "http://orgmode.org/elpa/")
        ("marmalade"   . "http://marmalade-repo.org/packages/")
        ("melpa" . "http://melpa.milkbox.net/packages/")))

(package-initialize)

(load-theme 'wheatgrass t)
(require 'use-package)

(use-package cl)
(use-package saveplace)
(use-package ffap)
(use-package uniquify)
(use-package ansi-color)
(use-package recentf)
(use-package tramp)

(use-package auto-complete
  :ensure t
  :init
  (progn
    (ac-config-default)
;;    (autopair-global-mode) ;; enable autopair in all buffers
    ))

(use-package fullscreen-mode
  :ensure t
  :init 
  (progn
    (fullscreen-mode-fullscreen)))

(use-package google-this
  :ensure t)
(use-package imenu-anywhere
  :ensure t)
(use-package haskell-mode
  :ensure t)

(use-package ace-window
  :ensure t)
(use-package flycheck
  :ensure t)


;; (load-file "~/.emacs.d/haskell.el")
;; (load-file "~/.emacs.d/python.el")
;; (load-file "~/.emacs.d/web.el")
;; (load-file "~/.emacs.d/sibi-utils.el")
;(load-file "~/.emacs.d/sml.el")

;; Remove menu, tool and scroll bar.
(menu-bar-mode -1)
(tool-bar-mode -1)
(set-scroll-bar-mode 'nil)
(size-indication-mode 1)

;; My Details
(setq user-full-name "Sibi")
(setq user-mail-address "sibi@psibi.in")

;; Unbind C-z
(when window-system
  (global-unset-key [(control z)]))

;; ----------------------
;; Final newline handling
;; ----------------------
(setq require-final-newline t)
(setq next-line-extends-end-of-buffer nil)
(setq next-line-add-newlines nil)

;; -------------------
;; Everything in UTF-8
;; -------------------
(prefer-coding-system                   'utf-8)
(set-language-environment               'utf-8)
(set-default-coding-systems             'utf-8)
(setq file-name-coding-system           'utf-8)
(setq default-buffer-file-coding-system 'utf-8)
(setq coding-system-for-write           'utf-8)
(set-keyboard-coding-system             'utf-8)
(set-terminal-coding-system             'utf-8)
(set-clipboard-coding-system            'utf-8)
(set-selection-coding-system            'utf-8)
(setq default-process-coding-system     '(utf-8 . utf-8))
(add-to-list 'auto-coding-alist         '("." . utf-8))




;;Tramp for editing protected files in existing Emacs session.(C-x C-f /sudo)
(setq tramp-default-method "ssh")

;; Custom Shortcuts
(global-set-key "\C-w" 'backward-kill-word)
(global-set-key "\C-x\C-k" 'kill-region)
(global-set-key "\C-c\C-k" 'kill-region)

;; Package List key binding
(global-set-key (kbd "C-x p") 'package-list-packages-no-fetch)
;; Rebind Enter
(define-key global-map (kbd "C-c j") 'newline-and-indent)

(global-set-key (kbd "C-x m") 'shell)

;; Emacs doesn't seem to have `copy-rectangle-as-kill`
;; http://www.gnu.org/software/emacs/manual/html_node/emacs/Rectangles.html
(defun my-copy-rectangle (start end)
   "Copy the region-rectangle instead of `kill-rectangle'."
   (interactive "r")
   (setq killed-rectangle (extract-rectangle start end)))
 
(global-set-key (kbd "C-x r M-w") 'my-copy-rectangle)

;; Just in case you are behind a proxy
;; (setq url-proxy-services '(("https" . "127.0.0.1:3129")
;;                            ("http" . "127.0.0.1:3129")))

;; -------------
;; flyspell-mode
;; -------------

(use-package flyspell
  :ensure t
  :init
  (progn
    (flyspell-mode 1))
  :config
  (progn 
    (setq ispell-program-name "aspell")
    (setq ispell-list-command "--list") ;; run flyspell with aspell, not ispell
    ))

;; Octave-mode
(use-package octave
  :ensure t
  :mode "\\.m\\'")

;; emms
(use-package emms
  :ensure t
  :config
  (progn
    (emms-standard)
    (emms-default-players)))

(use-package magit
  :ensure t
  :init
  (progn
    (global-set-key (kbd "C-c g") 'magit-status))
  :config
  (progn
    (magit-auto-revert-mode)))

(setq gc-cons-threshold 20000000)

;;Projectile related config
(use-package projectile
  :ensure t
  :init 
  (progn
    (projectile-global-mode))
  :config
  (progn
    (setq projectile-enable-caching t)))

(use-package helm-projectile
  :ensure t)

;;Helm related config
(use-package helm-config
  :ensure helm
  :init
  (progn
    (helm-mode 1))
  :config
  (progn
    (global-set-key (kbd "C-c h") 'helm-command-prefix)
    (global-unset-key (kbd "C-x c"))
    (define-key helm-map (kbd "<tab>") 'helm-execute-persistent-action) ; rebind tab to run persistent action
    (define-key helm-map (kbd "C-i") 'helm-execute-persistent-action) ; make TAB works in terminal
    (define-key helm-map (kbd "C-z") 'helm-select-action) ; list
                                        ; actions using C-z
    (when (executable-find "curl")
      (setq helm-google-suggest-use-curl-p t))
    (setq helm-split-window-in-side-p           t ; open helm buffer inside current window, not occupy whole other window
          helm-buffers-fuzzy-matching           t ; fuzzy matching buffer names when non--nil
          helm-move-to-line-cycle-in-source     t ; move to end or beginning of source when reaching top or bottom of source.
          helm-ff-search-library-in-sexp        t ; search for library in `require' and `declare-function' sexp.
          helm-scroll-amount                    8 ; scroll 8 lines other window using M-<next>/M-<prior>
          helm-ff-file-name-history-use-recentf t)
    (global-set-key (kbd "M-x") 'helm-M-x)
    (global-set-key "\C-x\C-m" 'helm-M-x)
    (global-set-key (kbd "M-y") 'helm-show-kill-ring)
    (global-set-key (kbd "C-x b") 'helm-mini)
    (global-set-key (kbd "C-x C-f") 'helm-find-files)
    (global-set-key (kbd "C-c h o") 'helm-occur)
    ))

(use-package doc-view
  :ensure t
  :config
  (progn
    (add-hook 'doc-view-mode-hook 'auto-revert-mode)))

(use-package ace-window
  :ensure t
  :init
  (progn
    (global-set-key (kbd "C-x o") 'ace-window)))


(use-package smart-mode-line
  :ensure t
  :init
  (progn
    (setq sml/no-confirm-load-theme t)
    (sml/setup)
    ))

(use-package smart-mode-line-powerline-theme
  :ensure t
  :init
  (progn
    (setq sml/theme 'powerline)
    (setq powerline-arrow-shape 'curve)
    (setq powerline-default-separator-dir '(right . left))
    ))

;; Enable clipboard
(setq x-select-enable-clipboard t)

;; Dired is better with human readable format
(setq dired-listing-switches "-alh")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; Custom splitting functions ;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defun vsplit-last-buffer ()
  (interactive)
  (split-window-vertically)
  (other-window 1 nil)
  (switch-to-next-buffer)
  )
(defun hsplit-last-buffer ()
  (interactive)
  (split-window-horizontally)
  (other-window 1 nil)
  (switch-to-next-buffer)
  )

(global-set-key (kbd "C-x 2") 'vsplit-last-buffer)
(global-set-key (kbd "C-x 3") 'hsplit-last-buffer)

;; Use shell-like backspace C-h, rebind help to F1
(define-key key-translation-map [?\C-h] [?\C-?])
(global-set-key (kbd "<f1>") 'help-command)
