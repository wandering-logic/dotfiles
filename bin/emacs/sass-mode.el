;;; Code:
(defvar sass-mode-hook nil)
(defvar sass-mode-map
  (let ((sass-mode-map (make-keymap)))
    (define-key sass-mode-map "\C-j" 'newline-and-indent)
    sass-mode-map)
  "Keymap for SASS major mode")

(add-to-list 'auto-mode-alist '("\\.sass\\'" . sass-mode))

(defvar sass-font-lock-keywords
  (list
   '("!!SPA[2345]\.[0-9]" . font-lock-type-face)
   (cons (regexp-opt (list "END" ".def" ".DEF" ".option" ".OPTION" ".literal" ".LITERAL"
                           ".align" ".ALIGN" ".REPEATED.LITERAL" ".repeated.literal"
                           ".declare" ".DECLARE" ".thread_type" ".THREAD_TYPE")) 'font-lock-type-face)
   '("^[ \t]*\\(@[!]?P[0-7T]\\)?[ \t]+\\([A-Za-z.0-9_]+\\)[; \t]" 2 font-lock-keyword-face)
   '("[a-zA-Z0-9_]+:" . font-lock-function-name-face)
   '("[$]\\([A-Za-z0-9_]+\\)" 1 font-lock-variable-name-face)
   '("[?]\\([A-Z_0-9]+\\)" 1 font-lock-constant-face)
   '("&\\(req\\|rd\\|wr\\)" 1 font-lock-constant-face)
   )
  "Default highlighting expressions for SASS mode.")

(defvar sass-mode-syntax-table
  (let ((sass-mode-syntax-table (make-syntax-table)))
	(modify-syntax-entry ?# "<" sass-mode-syntax-table)
	(modify-syntax-entry ?\n ">" sass-mode-syntax-table)
    (modify-syntax-entry ?\; "." sass-mode-syntax-table)
	sass-mode-syntax-table)
  "Syntax table for sass-mode")
  
(defun sass-mode ()
  (interactive)
  (use-local-map sass-mode-map)
  (set-syntax-table sass-mode-syntax-table)
  ;; Set up font-lock
  (set (make-local-variable 'font-lock-defaults) '(sass-font-lock-keywords))
  (font-lock-fontify-buffer)

  (require 'asm-mode)
  (set (make-local-variable 'indent-line-function) 'asm-indent-line)  
  (setq major-mode 'sass-mode)
  (setq mode-name "SASS")
  (run-hooks 'sass-mode-hook))

(provide 'sass-mode)

