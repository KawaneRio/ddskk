;;; skk-develop.el --- support SKK developper -*- coding: iso-2022-jp -*-

;; Copyright (C) 1999, 2000 NAKAJIMA Mikio <minakaji@osaka.email.ne.jp>

;; Author: NAKAJIMA Mikio <minakaji@osaka.email.ne.jp>
;; Maintainer: SKK Development Team <skk@ring.gr.jp>
;; Keywords: japanese, mule, input method

;; This file is part of Daredevil SKK.

;; Daredevil SKK is free software; you can redistribute it and/or
;; modify it under the terms of the GNU General Public License as
;; published by the Free Software Foundation; either version 2, or
;; (at your option) any later version.

;; Daredevil SKK is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with Daredevil SKK, see the file COPYING.  If not, write to
;; the Free Software Foundation Inc., 51 Franklin Street, Fifth Floor,
;; Boston, MA 02110-1301, USA.

;;; Commentary:

;;; Code:

(eval-when-compile
  (require 'skk-macs)
  (require 'skk-vars)
  (require 'url))

(eval-when-compile
  (defvar skk-exserv-list))

;;;###autoload
(defun skk-submit-bug-report ()
  "SKK $B$N%P%0%l%]!<%H$r=q$/%a!<%k%P%C%U%!$rMQ0U$9$k!#(B
mail-user-agent $B$r@_Dj$9$k$3$H$K$h$j9%$_$N%a!<%k%$%s%?!<%U%'%$%9$r;HMQ$9$k$3$H(B
$B$,$G$-$k!#Nc$($P!"(BWanderlust $B$r;HMQ$7$?$$>l9g$O2<5-$N$h$&$K@_Dj$9$k!#(B

    \(setq mail-user-agent 'wl-user-agent\) "
  (interactive)
  (require 'reporter)
  (when (skk-y-or-n-p
	 "SKK $B$K$D$$$F$N%P%0%l%]!<%H$r=q$-$^$9$+!)(B "
	 "Do you really want to write a bug report on SKK? ")
    (reporter-submit-bug-report
     skk-ml-address
     (concat (skk-version 'with-codename)
	     ", "
	     (cond
	      ((or (and (boundp 'skk-servers-list)
			skk-servers-list)
		   (or (and (boundp 'skk-server-host)
			    skk-server-host)
		       (getenv "SKKSERVER"))
		   ;; refer to DEFAULT_JISYO when skk-server-jisyo is nil.
		   ;;(or (and (boundp 'skk-server-jisyo) skk-server-jisyo)
		   ;;    (getenv "SKK_JISYO"))))
		   )
	       (require 'skk-server)
	       (concat "skkserv; "
		       (skk-server-version)
		       (when (getenv "SKKSERVER")
			 (concat ",\nSKKSERVER; "
				 (getenv "SKKSERVER")))
		       (when (getenv "SKKSERV")
			 (concat ", SKKSERV; "
				 (getenv "SKKSERV")))))
	      ((and (boundp 'skk-exserv-list)
		    skk-exserv-list)
	       (require 'skk-exserv)
	       (skk-server-version))))
     (let ((base (list 'window-system
		       'isearch-mode-hook
		       'isearch-mode-end-hook
		       'skk-auto-okuri-process
		       'skk-auto-start-henkan
		       'skk-egg-like-newline
		       'skk-henkan-okuri-strictly
		       'skk-henkan-strict-okuri-precedence
		       'skk-kakutei-early
		       'skk-process-okuri-early
		       'skk-search-prog-list
		       'skk-share-private-jisyo
		       'skk-use-viper)))
       (when (boundp 'skk-server-host)
	 (setq base (append base '(skk-server-host))))
       (when (boundp 'skk-server-prog)
	 (setq base (append base '(skk-server-prog))))
       (when (boundp 'skk-servers-list)
	 (setq base (append base '(skk-servers-list))))
       (when (boundp 'skk-exserv-list)
	 (setq base (append base '(skk-exserv-list))))
       base)))
  (message ""))

(defun skk-get-mkdir (dir)
  "DIR."
  (when (file-exists-p dir)
    (delete-directory dir t))
  (mkdir dir))

(defun skk-get-download (dir)
  "DIR."
  (let ((files (list "SKK-JISYO.JIS2.gz"
		     "SKK-JISYO.JIS2004.gz"
		     "SKK-JISYO.JIS3_4.gz"
		     "SKK-JISYO.L.gz"
		     "SKK-JISYO.assoc.gz"
		     "SKK-JISYO.edict.tar.gz"
		     "SKK-JISYO.fullname.gz"
		     "SKK-JISYO.geo.gz"
		     "SKK-JISYO.itaiji.gz"
		     "SKK-JISYO.jinmei.gz"
		     "SKK-JISYO.law.gz"
		     "SKK-JISYO.lisp.gz"
		     "SKK-JISYO.mazegaki.gz"
		     "SKK-JISYO.okinawa.gz"
		     "SKK-JISYO.propernoun.gz"
		     "SKK-JISYO.pubdic+.gz"
		     "SKK-JISYO.station.gz"
		     "zipcode.tar.gz"))
	(url "http://openlab.ring.gr.jp/skk/dic/")
	fn)
    (dolist (f files)
      (setq fn (expand-file-name f dir))
      (unless (file-exists-p fn)
	(url-copy-file (format "%s%s" url f) fn)))))

(defun skk-get-gzip (dir)
  "DIR."
  (dolist (f (directory-files dir t "gz"))
    (shell-command (format "gzip -d %s"
			   (convert-standard-filename f)))))

(defun skk-get-tar (dir)
  "DIR."
  (dolist (f (convert-standard-filename
	      (directory-files dir t "tar")))
    (shell-command (format "tar -xf %s -C %s && rm %s"
			   f dir f))))

;;;###autoload
(defun skk-get (&optional dir)
  "DIR."
  (interactive "P")
  (let ((jisyo-dir (if dir
			(expand-file-name dir)
		     (expand-file-name skk-get-jisyo-direcroty))))
    (skk-get-mkdir jisyo-dir)
    (skk-get-download jisyo-dir)
    (skk-get-gzip jisyo-dir)
    (skk-get-tar jisyo-dir)))

;;;###autoload
(add-hook
 'before-init-hook
 (lambda ()
   (eval-after-load "font-lock"
     ;; `lisp-font-lock-keywords-2' is an alias for `lisp-el-font-lock-keywords-2'.
     ;; `lisp-font-lock-keywords-2' is obsolete since 24.4;
     ;;                             use `lisp-el-font-lock-keywords-2' instead.
     '(set (if (boundp 'lisp-el-font-lock-keywords-2)
	       'lisp-el-font-lock-keywords-2
	     'lisp-font-lock-keywords-2)
	    (nconc
	     (list (list (concat "(\\(\\(skk-\\)?def\\("
				 ;; Function type declarations.
				 "\\(un-cond\\|subst-cond\\|advice\\|"
				 "macro-maybe\\|alias-maybe\\|un-maybe\\)\\|"
				 ;; Variable type declarations.
				 "\\(var\\|localvar\\)"
				 "\\)\\)\\>"
				 ;; Any whitespace and defined object.
				 "[ \t'\(]*"
				 "\\(\\sw+\\)?")
			 '(1 font-lock-keyword-face)
			 '(6 (cond ((match-beginning 4) font-lock-function-name-face)
				   ((match-beginning 5) font-lock-variable-name-face))
			     nil t)))

	     (list (list (concat "("
				 (regexp-opt '("skk-save-point"
					       "skk-with-point-move"
					       "skk-loop-for-buffers")
					     t)
				 "\\>")
			 '(1 font-lock-keyword-face)))

	     (list (list "(\\(skk-error\\)\\>"
			 '(1 font-lock-warning-face)))

	     (symbol-value (if (boundp 'lisp-el-font-lock-keywords-2)
			       'lisp-el-font-lock-keywords-2
			     'lisp-font-lock-keywords-2))

	     )))
   ;;
   (put 'skk-deflocalvar 'doc-string-elt 3)
   (put 'skk-defadvice 'doc-string-elt 3)
   ))

(provide 'skk-develop)

;;; skk-develop.el ends here
