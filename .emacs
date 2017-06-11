(setq inhibit-startup-message 't)

(setq-default fill-column 79)

(defun prepend-path ( my-path )
  (setq load-path (cons (expand-file-name my-path) load-path)))

(prepend-path (concat (getenv "HOME") "/bin/emacs"))

; RHEL systems autoclean files in /var/tmp that haven't been accessed
; for more than 30 days.  On other systems this dir may need to be
; cleaned out periodically.
(add-to-list 'backup-directory-alist
	     (cons "." "/var/tmp/mfrank/emacs-backups/"))

(global-set-key "\C-xg" 'goto-line)
(global-set-key "\C-x\C-e" 'compile)
(global-set-key "\C-x\C-n" 'next-error)
(global-set-key [?\M-\C-%] 'query-replace-regexp)
;; Make Shift-Backspace work like backspace:
(global-set-key [S-delete] 'delete-backward-char)

(defun server-shutdown ()
  "Save buffers, Quit, and Shutdown (kill) server"
  (interactive)
  (save-some-buffers)
  (kill-emacs))

(defun shell-command-to-useful-string ( command-string )
  (replace-regexp-in-string
   "\n\\'" ""
   (shell-command-to-string command-string)))

;; Perforce checkout hack
(defun perforce-checkout ()
  "`p4 edit` the current buffer"
  (interactive)
  (if buffer-read-only
      (progn
	(message "%s" (shell-command-to-useful-string
		       (concat "p4 edit " buffer-file-name)))
	(revert-buffer 't 't))	; reload to make writable
    (message "failed: %s is already writable" buffer-file-name)))

(global-set-key "\C-x4" `perforce-checkout)


;(load-library "mycompile")		; directory aware compile function
;(global-set-key "\C-c\C-e" 'set-default-compilation-directory)
;(global-set-key "\C-c\C-l" 'set-buffer-local-compilation-directory)

;; make horizontal windows wrap rather than truncate
(setq truncate-partial-width-windows '())

;; this is an example of how to make an interactive command
;; basically, just define a function, but give it a help string and
;; then mark it with (interactive)

(defun prev-window ()
  "runs (other-window -1)"
  (interactive)
  (other-window -1))

(global-set-key "\C-xp" 'prev-window)

;; Turns out this already exists:
;;
;(defun enlarge-window ()
;  "expand the current window vertically by one line"
;  (interactive)
;  (shrink-window -1))

;; Make Ctrl-PgUp and Ctrl-PgDn change window sizes
(global-set-key [C-next] 'enlarge-window)
(global-set-key [C-prior] 'shrink-window)

(defun write-date ()
  "print the current date at point"
  (interactive)
  (insert (format-time-string "%Y-%b-%d" (current-time))))

(defun write-date-long ()
  "print the current date at point"
  (interactive)
  (insert (format-time-string "%Y-%b-%d %H:%M:%S %Z" (current-time))))

(defun write-eighty-chars ()
  "print out 80 characters so I can adjust window sizes"
  (interactive)
  (insert "01234567890123456789012345678901234567890123456789012345678901234567890123456789"))

(global-set-key "\C-cm" 'write-date)
(global-set-key "\C-c\C-m" 'write-date-long)
(global-set-key "\C-c8" 'write-eighty-chars)

(defun write-big-comment-framework ()
  "insert a big 'ol comment at point"
  (interactive)
  (insert "/****************************************************************************\n")
  (insert " * \n")
  (insert " ***************************************************************************/")
  (newline)
  (forward-line -2)
  (end-of-line))

(global-set-key [?\M-\C-\;] 'write-big-comment-framework)

;; Date: Wed, 7 Dec 1994 11:57:50 -0600
;; From: blob@syl.dl.nec.com (David Blob)
;; Subject: Self-extracting emacs elisp code
;; 
;; With all this talk about self extracting mail "viruses", a friend
;; showed me that in emacs (which I use to read mail, along with vm)
;; has the ability to self-extract elisp code. This feature seems to
;; be turned on by default, and it not only applies to mail read with
;; emacs, but rather every file visited (when the feature is on, of
;; course).
;; 
;; The way it works is by having a line which reads "Local Variables:"
;; followed by the lisp variables you would like to set...well, it may
;; seem petty, but you can execute programs, make connections and much
;; more through cleverly written elisp code contained within.
;; 
;; It's simple to turn off, at any rate...
;; 
;; (setq enable-local-variables  f) ;; turns off feature  (in emacs 19)
;; (setq enable-local-variables  1) ;; makes it ask first (in emacs 19)
;; (setq inhibit-local-variables t) ;; turns off feature  (in emacs 18)
;; 
;; Anyhow, I think the risks here speak for themselves...
;;
(setq enable-local-variables '())

;; lose the useless decorations
(menu-bar-mode -1)
(cond
 (window-system
  (tool-bar-mode -1)
  (scroll-bar-mode -1)
  (setq visible-bell 't)
  ))

;; .sass mode
(load "sass-mode")
;; bison mode (also good for Flex/Lex/Yacc)
(load "bison-mode")

;; handle camelCase
(add-hook 'prog-mode-hook 'subword-mode)

(defun my-c-mode-common-hook ()
  ;; start with Ellemtel style for all C and C++ code
  (c-set-style "ellemtel")
  (setq c-basic-offset 4)
  (setq tab-width 8
	;; this will make sure spaces are used instead of tabs
	indent-tabs-mode nil)
  ;; then we add our own customizations ...
;;  (setq fill-column 79)
  (c-set-offset 'innamespace '0)
  ;; try this out interactively by using c-set-offset (C-c C-o)
  ;; the real documentation is on the variable 'c-offsets-alist
  ;; (C-h v c-offsets-alist)
  )

;; use my style modifications for all C, C++ and Java code
(add-hook 'c-mode-common-hook 'my-c-mode-common-hook)

(defun my-java-mode-hook ()
  ;; switch back to the java style
  (c-set-style "java")
)

(add-hook 'java-mode-hook 'my-java-mode-hook)

;; for scheme I want to use scheme48

;; mapping from file extensions to modes. Most common modes (C, Perl,
;; Tex) are handled by built-in defaults In these regexes "\\." means
;; literal dot.  "\\'" is end of buffer.  (better choice than "$"
;; which is the empty string before a newline or end-of-string.)  the
;; buffer starts with a directory path, so to match at beginning of
;; word you start them with "/" instead of "\\`" (start of buffer)
(setq auto-mode-alist
      (append
       (list (cons "\\.make\\'" 'makefile-mode)
	     (cons "\\.mk\\'" 'makefile-mode)
	     (cons "/makefile[^/]*\\'" 'makefile-gmake-mode)
	     (cons "/Makefile[^/]*\\'" 'makefile-gmake-mode)
	     (cons "\\.m4\\'" 'c-mode)
	     (cons "\\.l\\'" 'bison-mode) ;'fundamental-mode might be preferable
	     (cons "\\.h\\'" 'c++-mode)
	     (cons "\\.cu\\'" 'c++-mode)
	     (cons "\\.log\\'" 'indented-text-mode)
	     (cons "\\.php\\'" 'sgml-mode)
	     (cons "\\.py\\'" 'python-mode)
	     (cons "\\.parts\\'" 'python-mode)
	     (cons "SConstruct\\'" 'python-mode)
	     (cons "SConscript\\'" 'python-mode)
	     (cons "\\.lg\\'" 'latex-mode))
       auto-mode-alist))

(global-font-lock-mode 't)

(unless (window-system)
  (require 'mouse)
  (xterm-mouse-mode 't)
  (global-set-key [mouse-4] (lambda()
			      (interactive)
			      (scroll-down 1)))
  (global-set-key [mouse-5] (lambda()
			      (interactive)
			      (scroll-up 1)))
  (add-to-list 'load-path "~/.emacs.d/elpa/xclip-1.3/")
  (require 'xclip)
  (xclip-mode 1)
  )

;(load-theme 'wombat)
