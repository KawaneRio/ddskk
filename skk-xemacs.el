;;; skk-xemacs.el -- XEmacs support for SKK.
;; Copyright (C) 2000 Tetsuo Tsukamoto <czkmt@remus.dti.ne.jp>

;; Author: Tetsuo Tsukamoto <czkmt@remus.dti.ne.jp>
;; Maintainer: SKK Development Team <skk@ring.gr.jp>
;; Keywords: japanese

;; This file is part of Daredevil SKK.

;; Daredevil SKK is free software; you can redistribute it and/or modify it
;; under the terms of the GNU General Public License as published by the Free
;; Software Foundation; either versions 2, or (at your option) any later
;; version.

;; Daredevil SKK is distributed in the hope that it will be useful but WITHOUT
;; ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
;; FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
;; more details.

;; You should have received a copy of the GNU General Public License along with
;; Daredevil SKK, see the file COPYING.  If not, write to the Free Software
;; Foundation Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'static))

(eval-and-compile
  (require 'skk-macs)
  ;;
  (autoload 'Info-goto-node "info")
  (autoload 'browse-url "browse-url"))

(static-when
    (and (eq skk-emacs-type 'xemacs)
	 (< emacs-major-version 21))
  ;; From Naoki Wakamatsu <naoki-w@ht-net21.ne.jp>
  ;;
  ;; XEmacs 20.4 (Mule) includes SKK 10.38 and loads skk-leim.el on dump,
  ;; and skk/auto-autoloads.el on initialization.
  ;;
  ;; For overriding those, the following files needs to be loaded.
  (unless (featurep 'skk-setup)
    (load "skk-autoloads")
    (load "skk-leim")))

;; Variables.
(defvar skk-xemacs-extent-alist
  (list
   (cons 'default (make-extent nil nil))
   (cons 'hiragana (make-extent nil nil))
   (cons 'katakana (make-extent nil nil))
   (cons 'jisx0208-latin (make-extent nil nil))
   (cons 'latin (make-extent nil nil))
   (cons 'jisx0201 (make-extent nil nil))
   (cons 'abbrev (make-extent nil nil))))

(defvar skk-xemacs-modeline-menu-items
  '("Daredevil SKK Menu"
    ["Hiragana"
     (skk-j-mode-on)
     :selected (and skk-j-mode (not skk-katakana))
     :style radio
     :keys nil]
    ["Katakana"
     (skk-j-mode-on t)
     :selected (and skk-j-mode skk-katakana)
     :style radio
     :keys nil]
    ["Hankaku alphabet"
     skk-latin-mode
     :selected skk-latin-mode
     :style radio
     :keys nil]
    ["Zenkaku alphabet"
     skk-jisx0208-latin-mode
     :selected skk-jisx0208-latin-mode
     :style radio
     :keys nil]
    "--"
    ["Read Manual" skk-xemacs-info t]
    ["Start Tutorial" skk-tutorial t]
    ["Customize Daredevil SKK" skk-xemacs-customize t]
    ["Send a Bug Report"
     (let (skk-japanese-message-and-error)
       (skk-submit-bug-report)) t]
    "--"
    ["About Daredevil SKK..." skk-version t]
    ["Visit Daredevil SKK Home..." skk-xemacs-visit-openlab t]))

;; Functions.

(defun skk-xemacs-modeline-menu ()
  (interactive)
  ;; Find keys
  (aset (nth 1 skk-xemacs-modeline-menu-items)
	7
	(if skk-j-mode
	    (if skk-katakana
		(skk-xemacs-find-func-keys 'skk-toggle-kana)
	      "")
	  (skk-xemacs-find-func-keys 'skk-kakutei)))
  (aset (nth 2 skk-xemacs-modeline-menu-items)
	7
	(if skk-j-mode
	    (if skk-katakana
		""
	      (skk-xemacs-find-func-keys 'skk-toggle-kana))
	  ""))
  (aset (nth 3 skk-xemacs-modeline-menu-items)
	7
	(if skk-j-mode
	    (skk-xemacs-find-func-keys 'skk-latin-mode)
	  ""))
  (aset (nth 4 skk-xemacs-modeline-menu-items)
	7
	(if skk-j-mode
	    (skk-xemacs-find-func-keys 'skk-jisx0208-latin-mode)
	  ""))
  ;;
  (popup-menu skk-xemacs-modeline-menu-items))

(defun skk-xemacs-info ()
  (interactive)
  (Info-goto-node "(skk)"))

(defun skk-xemacs-customize ()
  (interactive)
  (customize-group "skk"))

(defun skk-xemacs-visit-openlab ()
  (interactive)
  (browse-url "http://openlab.ring.gr.jp/skk/index-j.html"))

;;;###autoload
(defun skk-xemacs-prepare-modeline-properties ()
  (let (extent face)
    (when (featurep 'window-system)
      (defvar skk-xemacs-modeline-map
	(let ((map (make-sparse-keymap)))
	  (define-key map
	    [button2]
	    (eval '(make-modeline-command-wrapper
		    'skk-xemacs-modeline-menu)))
	  map)))
    (dolist (mode '(hiragana
		    katakana
		    jisx0208-latin
		    latin
		    jisx0201
		    abbrev))
      (setq extent (cdr (assq mode
			      skk-xemacs-extent-alist)))
      (setq face (intern (format "skk-xemacs-%s-face"
				 mode)))
      (make-face face)
      (set-face-parent face 'modeline nil
		       (if (> emacs-major-version 20)
			   '(default)))
      (when (featurep 'window-system)
	(set-extent-keymap extent
			   skk-xemacs-modeline-map)
	(set-extent-property
	 extent
	 'help-echo
	 "$B%^%&%9$N(B button 2 -> Daredevil SKK $B$N%a%K%e!](B")
	(when (> emacs-major-version 20)
	  (set-face-foreground face
			       (symbol-value
				(intern (format
					 "skk-cursor-%s-color"
					 mode)))
			       nil
			       '(default color win))
	  (set-face-font face [bold] nil
			 '(default mono win))
	  (set-face-font face [bold] nil
			 '(default grayscale win))))
      (set-extent-face extent face))))

(defun skk-xemacs-find-func-keys (func)
  (let ((keys
	 (or (do ((spec (nth 4 skk-rule-tree) (cdr spec))
		  (list nil (car spec))
		  (str nil (when (eq (nth 3 list)
				     func)
			     (nth 1 list))))
		 ((or str (null spec))
		  (when (stringp str)
		    (if (string= str "\C-j")
			[(control j)]
		      str))))
	     (where-is-internal func skk-j-mode-map))))
    (if keys
	(sorted-key-descriptions keys)
      "")))

;; Hooks.

;;; Not necessary, but...
;;;###autoload (add-hook 'before-init-hook
;;;###autoload	  #'(lambda ()
;;;###autoload	      (define-key ctl-x-map "\C-j" 'skk-mode)))

;; Advice.

(skk-defadvice minibuffer-keyboard-quit (around skk-xemacs-ad activate)
  ;; XEmacs has `minibuffer-keyboard-quit'
  ;; that has nothing to do with delsel.
  (skk-remove-minibuffer-setup-hook
   #'skk-j-mode-on #'skk-setup-minibuffer
   #'(lambda ()
       (add-hook 'pre-command-hook 'skk-pre-command nil
		 'local)))
  (cond ((not skk-mode)
	 ad-do-it)
	((not skk-henkan-on)
	 (cond ((skk-get-prefix skk-current-rule-tree)
		(skk-erase-prefix 'clean))
	       (t
		ad-do-it)))
	(skk-henkan-active
	 (setq skk-henkan-count 0)
	 (if (and skk-delete-okuri-when-quit
		  skk-henkan-okurigana)
	     (let ((count (/ (length skk-henkan-okurigana)
			     skk-kanji-len)))
	       (skk-previous-candidate)
	       ;; $B$3$3$G$O(B `delete-backward-char' $B$K(B
	       ;; $BBhFs0z?t$rEO$5$J$$J}$,%Y%?!<!)(B
	       (delete-backward-char count))
	   (skk-previous-candidate)))
	(t
	 (skk-erase-prefix 'clean)
	 (if (> (point) skk-henkan-start-point)
	     (delete-region (point)
			    skk-henkan-start-point))
	 (skk-kakutei))))

;;

(require 'product)
(product-provide (provide 'skk-xemacs) (require 'skk-version))

;; skk-xemacs.el ends here
