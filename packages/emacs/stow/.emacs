(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-enabled-themes '(dracula))
 '(custom-safe-themes
   '("603a831e0f2e466480cdc633ba37a0b1ae3c3e9a4e90183833bc4def3421a961" default))
 '(package-selected-packages '(org-download dracula-theme evil)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

;; Package management
(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(package-initialize)

;; Install evil if not already installed
(unless (package-installed-p 'evil)
  (package-refresh-contents)
  (package-install 'evil))

;; Enable Evil mode
(require 'evil)
(evil-mode 1)

(set-face-attribute 'default nil :family "MesloLGS Nerd Font Mono" :height 190)

(use-package org-download
               :ensure t
                 :after org
                   :config
                     (add-hook 'dired-mode-hook 'org-download-enable))
