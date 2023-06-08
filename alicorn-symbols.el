;;; alicorn-symbols.el --- initial symbols for Alicorn syntax highlighting. -*- lexical-binding: t; -*-
;;; Commentary:
;; Lists all keywords and symbols to be matched exactly by font-locking.
;;; Code:

(defvar alicorn-symbols-keywords '(
   "fn"
   "if"
   "else"
   "val"
   "var"))
(defvar alicorn-symbols-functions '())
(defvar alicorn-symbols-operators '(
   "~"
   "=="
   "!="
   "<"
   "<="
   ">"
   ">="
   "+"
   "-"
   "*"
   "/"
   "%"
   "^"
   "="))
(defvar alicorn-symbols-types '())
(defvar alicorn-symbols-sugar-macros '())
(defvar alicorn-symbols-spice-macros '())
(defvar alicorn-symbols-global-symbols '())
(defvar alicorn-symbols-special-constants '())
;;; alicorn-symbols.el ends here
