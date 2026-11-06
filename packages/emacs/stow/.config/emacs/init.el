(setq custom-file
      (locate-user-emacs-file "custom.el"))

(when (file-exists-p custom-file)
  (load custom-file))

; ; Package management
; (require 'package)
; (add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
; (package-initialize)
;
; ; Install evil if not already installed
; (unless (package-installed-p 'evil)
;   (package-refresh-contents)
;   (package-install 'evil))
;
; ; Enable Evil mode
; (require 'evil)
; (evil-mode 1)

(set-face-attribute 'default nil :family "MesloLGS Nerd Font Mono" :height 190)

(use-package org-download
               :ensure t
                 :after org
                   :config
                     (add-hook 'dired-mode-hook 'org-download-enable))

