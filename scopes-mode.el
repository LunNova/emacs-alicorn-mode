;;; scopes-mode.el --- Major mode for editing Scopes code. -*- coding: utf-8; lexical-binding: t; -*-

;; Copyright © 2019, by Westerbly (radgeRayden) Snaydley

;; Author: Westerbly Snaydley (westerbly@gmail.com)
;; Version: 0.1.0
;; Created: 2019-11-10
;; Keywords: languages

;; Homepage: https://github.com/radgeRayden/emacs-scopes-mode/

;; This file is not part of GNU Emacs.

;;; License:
;; This is free and unencumbered software released into the public domain.

;; Anyone is free to copy, modify, publish, use, compile, sell, or
;; distribute this software, either in source code form or as a compiled
;; binary, for any purpose, commercial or non-commercial, and by any
;; means.

;; In jurisdictions that recognize copyright laws, the author or authors
;; of this software dedicate any and all copyright interest in the
;; software to the public domain. We make this dedication for the benefit
;; of the public at large and to the detriment of our heirs and
;; successors. We intend this dedication to be an overt act of
;; relinquishment in perpetuity of all present and future rights to this
;; software under copyright law.

;; THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
;; EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
;; MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
;; IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
;; OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
;; ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
;; OTHER DEALINGS IN THE SOFTWARE.

;; For more information, please refer to <https://unlicense.org>

;;; Commentary:

;; Major mode for the Scopes programming language. Know more at http://scopes.rocks/.

;;; Code:

;; Symbols are generated by generator.sc and stored in `scopes-symbols.el'.
(load-library "scopes-symbols.el")

;; Emacs doesn't highlight numbers by default; as such I didn't want to impose a standard face.
(defcustom scopes-number-font-face font-lock-constant-face
  "Font face to use for number highlighting."
  :type 'face
  :group 'scopes)

(defvar scopes-font-lock-keywords
    (let* (
        (scopes-keywords-regexp (regexp-opt scopes-symbols-keywords 'symbols))
        (scopes-functions-regexp (regexp-opt scopes-symbols-functions 'symbols))
        (scopes-operators-regexp (regexp-opt scopes-symbols-operators 'symbols))
        (scopes-types-regexp (regexp-opt scopes-symbols-types 'symbols))
        (scopes-sugar-macros-regexp (regexp-opt scopes-symbols-sugar-macros 'symbols))
        (scopes-spice-macros-regexp (regexp-opt scopes-symbols-spice-macros 'symbols))
        (scopes-global-symbols-regexp (regexp-opt scopes-symbols-global-symbols 'symbols))
        (scopes-special-constants-regexp (regexp-opt scopes-symbols-special-constants 'symbols)))
      `(
        ;; block strings
        (,(rx
           (group-n 1 (* "    ")) "\"\"\"\""
            (* any) (or "\n" eol)
            (*
              (or
                (: (* whitespace) "\n")
                (group (backref 1) "    " (* any) (or "\n" eol))))) . font-lock-string-face)
        ;; comments
        (,(rx
            (group-n 1 line-start (* " ")) "#" (* any) (or "\n" eol)
            (*
              (or
                (: (* whitespace) (or "\n" eol))
                (group (backref 1) " " (* any) (or "\n" eol))))) . font-lock-comment-face)
        (,(rx "#" (* any) eol) . font-lock-comment-face)

        ;; it's less common for strings to contain comments, so I'm adding them last.
        ;; FIXME: use a parsing function instead of regexes, as every approach has been flawed somehow.
        ;; for example, here we can't highlight escapes inside strings without jumping through hoops, but could be done with a function.
        ;; inline strings
        ;; to make things easier, empty string is a special case.
        (,(rx "\"\"") . font-lock-string-face)
        (,(rx (: "\"" (+ (: (*? not-newline) (opt "\\\"")))  "\"")) . font-lock-string-face)

        ;; number literals
        (,(rx
           symbol-start
           (opt (any "+-"))
           (or
            (:
              ;; no fractional part
              (or
                ;; decimal
                (+ digit)
                ;; binary
                (: "0b" (+ (any "01")))
                ;;octal
                (: "0o" (+ (any "0-7")))
                ;;hex
                (: "0x" (+ hex-digit)))
              (opt (: "e" (opt (any "+-")) (+ digit)))
              (opt (: ":" (or (: "f" (or "32" "64"))  (: (any "ui") (or "8" "16" "32" "64")) "usize"))))
            (:
            ;; floats with fractional part
             (or
              ;; decimal prefix
              (or (: (+ digit) ".") (: "." (+ digit)) (: (+ digit) "." (+ digit)))
              ;; binary prefix
              (: "0b" (or (: (+ (any "01")) ".") (: "." (+ (any "01"))) (: (+ (any "01")) "." (+ (any "01")))))
              ;; octal prefix
              (: "0o" (or (: (+ (any "0-7")) ".") (: "." (+ (any "0-7"))) (: (+ (any "0-7")) "." (+ (any "0-7")))))
              ;; hex prefix
              (: "0x" (or (: (+ hex-digit) ".") (: "." (+ hex-digit)) (: (+ hex-digit) "." (+ hex-digit)))))
             (opt (: "e" (opt (any "+-")) (+ digit)))
             (opt (or ":f32" ":f64"))))
            symbol-end) . scopes-number-font-face)

        ;; symbols and method calls
        (,(rx (: "'" (+ (not (any ",()[]{} \n"))))) . font-lock-preprocessor-face)
        (,scopes-functions-regexp . font-lock-function-name-face)
        (,scopes-global-symbols-regexp . font-lock-variable-name-face)
        (,scopes-spice-macros-regexp . font-lock-keyword-face)
        (,scopes-sugar-macros-regexp . font-lock-builtin-face)
        (,scopes-types-regexp . font-lock-type-face)
        (,scopes-operators-regexp . font-lock-builtin-face)
        (,scopes-special-constants-regexp . font-lock-constant-face)
        (,scopes-keywords-regexp . font-lock-builtin-face))))

(defvar scopes-mode-syntax-table
  (let ((table (make-syntax-table)))
    (modify-syntax-entry ?@  "_" table)
    (modify-syntax-entry ?|  "_" table)
    (modify-syntax-entry ?:  "_" table)
    (modify-syntax-entry ?.  "_" table)
    (modify-syntax-entry ?#  "<" table)
    (modify-syntax-entry ?\; "." table)
    table))

(defvar scopes-new-code-block-regexp
  (rx
   (or
    ;; wish this could be generated! It requires manual cherry picking anyways.
    ;; of course for a few like `if' it would be useful to check if there isn't a multiline
    ;; parentheses going on, but I'll leave that to some other time.
    (: line-start (* whitespace) (or "if"
                                     "else"
                                     "elseif"
                                     "then"
                                     "case"
                                     "pass"
                                     "default"
                                     "except"
                                     "fn"
                                     "inline"
                                     "label"
                                     "do"
                                     "embed"
                                     "try"
                                     "loop"
                                     "for"
                                     "fold"
                                     "while"
                                     "spice-quote"
                                     "enum"
                                     "struct"
                                     "::"))
    ;; dangling equal sign
    (: "=" (* " ") line-end))))

(defvar scopes-end-code-block-regexp
  (rx (: line-start
         (* whitespace)
         (or
          "return"
          "break"
          "repeat"
          "continue"
          "merge")
         (or ";" (: (+ whitespace) (not whitespace))))))

(defun scopes-indent-line ()
  "Indent code in multiples of four spaces.
Will align column to next multiple of four, up to previous line indentation + 4."
  (interactive "*")
  (let* ((prev-indent (save-excursion
                        (beginning-of-line)
                        (if (not (bobp))
                            (progn
                              (re-search-backward "[^ \n]" nil t)
                              (current-indentation))
                            0)))
         (cur-indent (save-excursion (forward-to-indentation 0)))
         (blank-line-p (save-excursion (beginning-of-line) (looking-at "[[:space:]]*$")))
         (column-before-indent (current-column)))
    ;;is this the first line? just indent everything to 0.
    (if (save-excursion (beginning-of-line) (bobp))
      (indent-line-to 0)
      (let* ((next-align (+ cur-indent (- 4 (% cur-indent 4))))
            (aligned-p (save-excursion
                        (forward-to-indentation 0)
                        (= (current-column) next-align)))
            (max-indent (+ prev-indent 4))
            (closest-lower-indent
             (let
                 ((lower-than-prev (- prev-indent 4)))
                  (if (>= lower-than-prev 0)
                      lower-than-prev
                      0))))
       
        ;; are we indenting an already written line?
        (if (not blank-line-p)
          ;; then we don't assume intention, and understand that the user might want to indent
          ;; to anywhere between where the text currently is and previous line indentation
          ;; + 4.
          ;; are we past indentation limit?
          (if (>= cur-indent max-indent)
            (indent-line-to max-indent)
            ;; add a level if we're already aligned, or align it.
            (if aligned-p
                (indent-line-to (+ cur-indent 4))
                (indent-line-to next-align)))

          ;; are we on an entirely new line?
          (if (= column-before-indent 0)
              ;; Check if new block or continue previous block.
              (let* ((prev-line-end-point (save-excursion
                                          (forward-line -1)
                                          (end-of-line)
                                          (point)))
                    (new-block-p (save-excursion
                                  (forward-line -1)
                                  (beginning-of-line)
                                  (re-search-forward scopes-new-code-block-regexp prev-line-end-point t)))
                    (end-block-p (save-excursion
                                  (forward-line -1)
                                  (beginning-of-line)
                                  (re-search-forward scopes-end-code-block-regexp prev-line-end-point t))))
                (cond
                (new-block-p (indent-line-to max-indent))
                (end-block-p (indent-line-to closest-lower-indent))
                (t           (progn (indent-line-to prev-indent)))))

              ;; otherwise, align or indent forward.
              (if (>= cur-indent max-indent)
                (indent-line-to max-indent)
                ;; add a level if we're already aligned, or align it.
                (if aligned-p
                    (indent-line-to (+ cur-indent 4))
                    (indent-line-to next-align))))))))
    (if (< (current-column) (current-indentation))
        (forward-to-indentation 0)))

;;;autoload
(define-derived-mode scopes-mode scheme-mode "Scopes"
  "Major mode for editing Scopes code."

  (set-syntax-table scopes-mode-syntax-table)
  (setq-local comment-start "#")
  (setq-local comment-start-skip "#+ *")
  (setq-local comment-end "")
  (setq-local comment-add 0)
  (setq-local comment-use-syntax nil)
  (setq-local electric-indent-inhibit t)
  ;; TODO: change to a custom indent function that behaves differently inside a
  ;; parenthesized expression
  (setq-local indent-line-function 'scopes-indent-line)
  (electric-indent-local-mode -1)
  ;; (setq-)
  (setq font-lock-multiline t
        font-lock-defaults '((scopes-font-lock-keywords) t)))

;;;###autoload
(add-to-list 'auto-mode-alist '("\\.sc\\'" . scopes-mode))

;; add the mode to the `features' list
(provide 'scopes-mode)

;;; scopes-mode.el ends here
