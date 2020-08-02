; -*- mode: emacs-lisp -*-
;; Load VM easily
;; ____________________________________________________________________________
;; Aquamacs custom-file warning:
;; Warning: After loading this .emacs file, Aquamacs will also load
;; customizations from `custom-file' (customizations.el). Any settings there
;; will override those made here.
;; Consider moving your startup settings to the Preferences.el file, which
;; is loaded after `custom-file':
;; ~/Library/Preferences/Aquamacs Emacs/Preferences
;; _____________________________________________________________________________


;; Added by Package.el.  This must come before configurations of
;; installed packages.  Don't delete this line.  If you don't want it,
;; just comment it out by adding a semicolon to the start of the line.
;; You may delete these explanatory comments.

(add-to-list 'load-path (expand-file-name "~/emacs/lisp"))
(add-to-list 'load-path (expand-file-name "~/emacs/lisp/vm-8.2.0b/lisp"))
(add-to-list 'load-path (expand-file-name "~/emacs/lisp/auctex-12.2"))
(add-to-list 'load-path (expand-file-name "~/emacs/lisp/elisp/bbdb-2.34/lisp"))
(add-to-list 'load-path "/usr/local/share/emacs/site-lisp")

(add-to-list 'exec-path "/usr/local/bin")
(add-to-list 'exec-path "/usr/texbin")
(add-to-list 'exec-path "/Library/TeX/texbin/")

;; (load "vm-autoloads")
(setq user-full-name "Henrik I. Christensen")
(setq user-mail-address "henrik@hichirstensen.com")

(show-paren-mode 1)
;;Tell Emacs to use GNUTLS instead of STARTTLS
;;to authenticate when sending mail.
(autoload 'feedmail-send-it "feedmail")
(autoload 'feedmail-run-the-queue "feedmail")
(autoload 'feedmail-run-the-queue-no-prompts "feedmail")
(autoload 'feedmail-queue-reminder "feedmail")
(setq feedmail-buffer-eating-function 'feedmail-buffer-to-smtpmail)
(setq auto-mode-alist (cons '("\\.fqm$" . mail-mode) auto-mode-alist))
(setq feedmail-enable-queue t) ; optional
(setq feedmail-queue-chatty t) ; optional
(feedmail-queue-reminder 'after-immediate) ;; remind us to send queued messages

 ;; Default smtpmail.el configurations.
(require 'cl)
(require 'smtpmail)
(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      mail-from-style nil
      smtpmail-debug-info t
      smtpmail-debug-verb t)

(defun set-smtp (mech server port user password)
  "Set related SMTP variables for supplied parameters."
  (setq smtpmail-smtp-server server
	smtpmail-smtp-service port
	smtpmail-auth-credentials (list (list server port user password))
	smtpmail-auth-supported (list mech)
	smtpmail-starttls-credentials nil)
  (message "Setting SMTP server to `%s:%s' for user `%s'."
	   server port user))

(defun set-smtp-ssl (server port user password  &optional key cert)
  "Set related SMTP and SSL variables for supplied parameters."
  (setq starttls-use-gnutls t
	starttls-gnutls-program "gnutls-cli"
	starttls-extra-arguments nil
	smtpmail-smtp-server server
	smtpmail-smtp-service port
	smtpmail-auth-credentials (list (list server port user password))
	smtpmail-starttls-credentials (list (list server port key cert)))
  (message
   "Setting SMTP server to `%s:%s' for user `%s'. (SSL enabled.)"
   server port user))

(defun change-smtp ()
  "Change the SMTP server according to the current from line."
  (save-excursion
    (loop with from = (save-restriction
			(message-narrow-to-headers)
			(message-fetch-field "from"))
	  for (auth-mech address . auth-spec) in smtp-accounts
	  when (string-match address from)
	  do (cond
	      ((memq auth-mech '(cram-md5 plain login))
	       (return (apply 'set-smtp (cons auth-mech auth-spec))))
	      ((eql auth-mech 'ssl)
	       (return (apply 'set-smtp-ssl auth-spec)))
	      (t (error "Unrecognized SMTP auth. mechanism: `%s'." auth-mech)))
	  finally (error "Cannot infer SMTP information."))))

(setq starttls-use-gnutls t)

;;Tell Emacs about your mail server and credentials
(setq send-mail-function 'smtpmail-send-it
      message-send-mail-function 'smtpmail-send-it
      smtpmail-starttls-credentials
      '(("smtp.1and1.com" 587 nil nil))
      smtpmail-auth-credentials
      (expand-file-name "~/.authinfo")
      smtpmail-default-smtp-server "smtp.1and1.com"
      smtpmail-smtp-server "smtp.1and1.com"
      smtpmail-smtp-service 587
      smtpmail-debug-info t)

(setq feedmail-confirm-outgoing t)
(setq send-mail-function 'feedmail-send-it)

(setq message-send-mail-function 'smtpmail-send-it     ;; for gnus/message
      send-mail-function 'smtpmail-send-it)            ;; for `mail'

(setq
 vm-forwarding-subject-format "Forward from %F - %s"
;;  vm-forwarding-digest-type "rfc934"
;;  vm-in-reply-to-format nil
;;  vm-included-text-attribution-format “On %w, %m %d, %y at %h (%z), %F wrote:\n”
;;  vm-reply-subject-prefix “Re: ”
 vm-mail-header-from "Henrik I. Christensen  <henrik@hichristensen.com>"
)

(require 'bbdb)
;;(cond ((not (emacs-is-really-xemacs))
(bbdb-initialize 'vm 'sendmail)
;;        )
;;       )

(add-hook 'bbdb-load-hook 'my-bbdb-load-hook)

;;{{{ BBDB

;;; ............................................................ &bbdb ...

;;; ----------------------------------------------------------------------
;;; 

(define-key mail-mode-map [(control c)(control q)] 'bbdb-complete-name)

(defun my-bbdb ()
  (message "inside my-bbdb")
  "Start BBDB."
  ;;  Is BBDB installed?
  (message "start bbdb")
  (when (and (memq 'bbdb-insinuate-sendmail mail-setup-hook)
	     (boundp 'mail-mode-map))
    (defvar mail-mode-map  nil)
    (define-key mail-mode-map [(control c)(control q)] 'bbdb-complete-name)
    )
  (when (boundp 'vm-mode-map)
    (bbdb-initialize 'vm)
    (message "vm bbdb initialized")
    )

  (when (boundp 'message-mode-map)
    (bbdb-initialize 'message)
    (bbdb-insinuate-message)
    (defvar message-mode-map  nil)
    (define-key message-mode-map [(f12)] 'bbdb/rmail-show-sender)
    )

  )

;;; ----------------------------------------------------------------------
;;;
(message "before my-bbdb-load-hook")
(defun my-bbdb-load-hook  ()
  (interactive)
  (cond ((not (emacs-is-really-xemacs))

	 (defvar bbdb-mode-map nil)
	 (define-key bbdb-mode-map "a" 'bbdb-insert-new-field)
	 (define-key bbdb-mode-map "s" 'bbdb-display)
  ))
;;  (when-package 'bbdb nil		;install only if BBDB is present

    (eval-and-compile
      (autoload 'bbdb-initialize		"bbdb")
      (autoload 'bbdb-insinuate-sendmail	"bbdb")
      
      (autoload 'bbdb			        "bbdb-com" t t)
      (autoload 'bbdb-name		        "bbdb-com" t t)
      (autoload 'bbdb-company		        "bbdb-com" t t)
      (autoload 'bbdb-net		        "bbdb-com" t t)
      (autoload 'bbdb-notes		        "bbdb-com" t t)      
      )

    (add-hook 'mail-setup-hook	    'bbdb-insinuate-sendmail)
    (add-hook 'vm-mode-hook         'bbdb-insinuate-vm)
    ;; full-names and user-ids in the bbdb-database
    ;; See also 'net
    
 ;;   (defconst bbdb-completion-type nil)
    
    
    (setq       
      bbdb-offer-save 1
      bbdb-define-all-aliases-mode 'all
      bbdb-default-label-list '("home" "mobile" "job") 
      bbdb-phones-label-list  bbdb-default-label-list
      bbdb-addresses-label-list bbdb-default-label-list
      bbdb-default-country ""
      bbdb-address-editing-function 'bbdb-address-edit-continental
      ;; popup/elided display settings 
      bbdb-pop-up-target-lines 3
      bbdb-use-pop-up 'horiz            ; nil
      )
    ;;  Don't ask from me.
    
    (defconst bbdb-use-alternate-names	t)
    (defconst bbdb-auto-revert-p	t)
    (defconst bbdb-offer-save		'always-save-without-ask)
    
    ;;  Add person's new address automatically
    
    (defconst bbdb-always-add-addresses t)
    (defconst bbdb-new-nets-always-primary 'add-to-the-end)
    (defconst bbdb-message-caching-enabled t)    
    (defconst bbdb-time-display-format "%Y-%m-%d")
    
    (defconst bbdb-dwim-net-address-allow-redundancy t)
    
    
    (defconst bbdb-pop-up-target-lines 4)
    
    (defconst bbdb-quiet-about-name-mismatches t)
    ;; (defconst bbdb-file "~/.bbdb")
    
    (add-hook 'bbdb-change-hook 'bbdb-timestamp-hook)
        
    (defconst bbdb-canonicalize-net-hook 'my-bbdb-canonicalize-net-hook)
        
    (add-hook 'mail-setup-hook   'my-bbdb)
    (add-hook 'message-mode-hook 'my-bbdb)
    (add-hook 'vm-mode-hook      'my-bbdb)
    
    
    (if (featurep 'bbdb)
        (my-bbdb-load-hook))
    
    
    ;; (name net)
    
    ;; ) ;; when-package 'bbdb
  )
;;}}}


(setenv "PATH" (concat "/Library/TeX/texbin:/usr/local/bin:" (getenv "PATH")))
(load "auctex.el" nil t t)
(load "preview-latex.el" nil t t)
(require 'tex-site)  ;; -- auctex installed through homebrew. 

;; AucTeX
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)
(add-hook 'LaTeX-mode-hook 'visual-line-mode)
(add-hook 'LaTeX-mode-hook 'flyspell-mode)
(add-hook 'LaTeX-mode-hook 'LaTeX-math-mode)
(add-hook 'LaTeX-mode-hook 'turn-on-reftex)
(setq reftex-plug-into-AUCTeX t)
(setq TeX-PDF-mode t)

;; Use Skim as viewer, enable source <-> PDF sync
;; make latexmk available via C-c C-c
;; Note: SyncTeX is setup via ~/.latexmkrc (see below)
(add-hook 'LaTeX-mode-hook (lambda ()
  (push
    '("latexmk" "latexmk -pdf %s" TeX-run-TeX nil t
      :help "Run latexmk on file")
    TeX-command-list)))
(add-hook 'TeX-mode-hook '(lambda () (setq TeX-command-default "latexmk")))

;; use Skim as default pdf viewer
;; Skim's displayline is used for forward search (from .tex to .pdf)
;; option -b highlights the current line; option -g opens Skim in the background  
(setq TeX-view-program-selection '((output-pdf "PDF Viewer")))
(setq TeX-view-program-list
     '(("PDF Viewer" "/Applications/Skim.app/Contents/SharedSupport/displayline -b -g %n %o %b")))

(autoload 'markdown-mode "markdown-mode.el" "Major mode for editing Markdown files" t) 
(setq auto-mode-alist (cons '("\\.text" . markdown-mode) auto-mode-alist))
(setq auto-mode-alist (cons '("\\.md" . markdown-mode) auto-mode-alist))
(add-hook 'markdown-mode-hook
          (lambda () 
	    (add-hook 'after-save-hook 'langtool-check nil 'make-it-local)))

(dolist (hook '(text-mode-hook))
  (add-hook hook (lambda () (flyspell-mode 1))))
(add-hook 'python-mode-hook
    (lambda ()
    (flyspell-prog-mode)
    ))

(setq reftex-bibpath-environment-variables (expand-file-name "~/Dropbox/bibliography/"))
(setq reftex-file-extensions  '(("nw" "tex" ".tex" ".ltx") ("bib" ".bib")))

;; (custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
;; '(LaTeX-command "latex")
;; )

;; (set-default-font "-apple-dejavu sans mono-medium-r-normal--0-0-0-0-m-0-mac-roman")

(require 'package)

(add-to-list 'package-archives
	     '("melpa-stable" . "https://stable.melpa.org/packages/")
	     )
(add-to-list 'package-archives
	     '("melpa" . "https://melpa.org/packages/")
	     )

(package-initialize)

;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.

(global-set-key (kbd "C-x g") 'magit-status)

;; (require 'sublimity)
;; (require 'sublimity-scroll)
;; (require 'sublimity-map) ;; experimental
;; (require 'sublimity-attractive)
;; (require 'rainbow-delimiters)

;; (sublimity-mode nil)

(require 'auto-package-update)

(require 'all-the-icons)

(require 'neotree)
(setq neo-theme (if (display-graphic-p) 'icons 'arrow))

(require 'doom-themes)

;; ;; Global settings (defaults)
(setq doom-themes-enable-bold t    ; if nil, bold is universally disabled
      doom-themes-enable-italic t) ; if nil, italics is universally disabled

;; ;; Load the theme (doom-one, doom-molokai, etc); keep in mind that each theme
;; ;; may have their own settings.
(load-theme 'doom-one t)

;; ;; Enable flashing mode-line on errors
(doom-themes-visual-bell-config)

;; Enable custom neotree theme (all-the-icons must be installed!)
(doom-themes-neotree-config)

;; or for treemacs users
(doom-themes-treemacs-config)

;; Corrects (and improves) org-mode's native fontification.
(doom-themes-org-config)

;; AUCtex related 
(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq-default TeX-master nil)

;; Add linenumber to buffer

(require 'linum)
(unless window-system
  (add-hook 'linum-before-numbering-hook
	    (lambda ()
	      (setq-local linum-format-fmt
			  (let ((w (length (number-to-string
					    (count-lines (point-min) (point-max))))))
			    (concat "%" (number-to-string w) "d"))))))

(defun linum-format-func (line)
  (concat
   (propertize (format linum-format-fmt line) 'face 'linum)
   (propertize " " 'face 'mode-line)))

(unless window-system
  (setq linum-format 'linum-format-func))
(global-linum-mode 1)
(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   (quote
    ("a24c5b3c12d147da6cef80938dca1223b7c7f70f2f382b26308eba014dc4833a" default)))
 '(display-time-mode t)
 '(ein:output-area-inlined-images t)
 '(package-selected-packages
   (quote
    (flyspell-correct langtool elpygen ein ebib rainbow-mode elpy material-theme neotree magit doom-themes auto-package-update auto-complete-auctex auctex)))
 '(show-paren-mode t)
 '(size-indication-mode t))

(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(linum ((t (:inherit default :foreground "#3f44" :strike-through nil :underline nil :slant normal :weight normal)))))

;; (require 'org)
;; (define-key global-map "\C-cl" 'org-store-link)
;; (define-key global-map "\C-ca" 'org-agenda)
;; (setq org-log-done t)
;; (setq org-agenda-files (list "~/org/work.org"
;;                              "~/org/home.org"))

(load-theme 'material t) ;; load material theme
(global-linum-mode t) ;; enable line numbers globally
(elpy-enable)
