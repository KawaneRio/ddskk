;;; skk-foreword.el --- $BA0=q$-(B
;; Copyright (C) 1997, 1998, 1999 Mikio Nakajima <minakaji@osaka.email.ne.jp>

;; Author: Mikio Nakajima <minakaji@osaka.email.ne.jp>
;; Maintainer: Hideki Sakurada <sakurada@kuis.kyoto-u.ac.jp>
;;             Murata Shuuichirou  <mrt@astec.co.jp>
;;             Mikio Nakajima <minakaji@osaka.email.ne.jp>
;; Version: $Id: skk-foreword.el,v 1.2 1999/08/18 23:20:16 minakaji Exp $
;; Keywords: japanese
;; Last Modified: $Date: 1999/08/18 23:20:16 $

;; This file is not part of SKK yet.

;; SKK is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either versions 2, or (at your option)
;; any later version.

;; SKK is distributed in the hope that it will be useful
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.

;; You should have received a copy of the GNU General Public License
;; along with SKK, see the file COPYING.  If not, write to the Free
;; Software Foundation Inc., 59 Temple Place - Suite 330, Boston,
;; MA 02111-1307, USA.

;;; Commentary:

;; $B$3$N%U%!%$%k$O!"%f!<%6!<JQ?t$N@k8@<+BN$K;HMQ$9$k%^%/%m!"(Bskk-*.el $B$G(B
;; $B;HMQ$9$k%^%/%m$J$I!"JQ?t$N@k8@0JA0!"(Bskk-*.el $B$N:G=i$KDj5A$7$F$*$+$J(B
;; $B$1$l$P$J$i$J$$$b$N$r$^$H$a$?$b$N$G$9!#%f!<%6!<JQ?t$NDj5A$NA0$K!"$4(B
;; $B$A$c$4$A$c$H%f!<%6!<$K6=L#$,$J$$$b$N$,JB$s$G$$$?$N$G$O!"%f!<%6!<%U(B
;; $B%l%s%I%j!<$G$O$J$$$H9M$($k$+$i$G$9!#(B
;;
;; Following people contributed modifications to skk-foreword.el (Alphabetical order):
;;       $B>.Ln(B $B9'CK(B <takao@hirata.nuee.nagoya-u.ac.jp>
;;       Hideki Sakurada <sakurada@kuis.kyoto-u.ac.jp>
;;       Shuhei KOBAYASHI <shuhei-k@jaist.ac.jp>
;;       TSUMURA Tomoaki <tsumura@kuis.kyoto-u.ac.jp>

;;; Change log:

;;; Code:
(cond ((or (and (boundp 'epoch::version) epoch::version)
	   (string< (substring emacs-version 0 2) "18") )
       (error "THIS SKK requires Emacs 19 or later") )
      ((not (featurep 'mule))
       (error "THIS SKK requires MULE features") ))

(eval-when-compile
  (defvar skk-abbrev-cursor-color)
  (defvar skk-abbrev-mode)
  (defvar skk-abbrev-mode-string)
  (defvar skk-current-rule-tree)
  (defvar skk-default-cursor-color)
  (defvar skk-downcase-alist)
  (defvar skk-echo)
  (defvar skk-hankaku-alist)
  (defvar skk-henkan-count)
  (defvar skk-henkan-list)
  (defvar skk-hiragana-cursor-color)
  (defvar skk-hiragana-mode-string)
  (defvar skk-input-mode-string)
  (defvar skk-j-mode)
  (defvar skk-jisx0208-latin-cursor-color)
  (defvar skk-jisx0208-latin-mode)
  (defvar skk-jisx0208-latin-mode-string)
  (defvar skk-kana-input-search-function)
  (defvar skk-kana-start-point)
  (defvar skk-katakana)
  (defvar skk-katakana-cursor-color)
  (defvar skk-katakana-mode-string)
  (defvar skk-last-henkan-data)
  (defvar skk-latin-cursor-color)
  (defvar skk-latin-mode)
  (defvar skk-latin-mode-string)
  (defvar skk-mode)
  (defvar skk-prefix)
  (defvar skk-previous-point)
  (defvar skk-use-numeric-conversion) )

(require 'advice)
(require 'easymenu)
;; APEL 9.20 or later required.
(require 'poe)
(require 'poem)
(require 'pcustom)
(require 'alist)
;; Elib 1.0 is required.
(require 'queue-m)

;;;###autoload
(eval-and-compile
  (defconst skk-emacs-type (cond ((string-match "XEmacs" emacs-version) 'xemacs)
				 ((and (boundp 'mule-version)
				       (string< "4.0" mule-version) 'mule4 ))
				 ((and (boundp 'mule-version)
				       (string< "3.0" mule-version) 'mule3 ))
				 ((and (boundp 'mule-version)
				       (string< "2.0" mule-version) 'mule2 )))))

;; necessary macro and functions to be declared before user variable declarations.

;;;; macros

;; Who uses SKK without compilaition?
;;(eval-when-compile

;; Why I use non-intern temporary variable in the macro --- see comment in
;; save-match-data of subr.el of GNU Emacs. And should we use the same manner
;; in the save-current-buffer, with-temp-buffer and with-temp-file macro
;; definition?
(defmacro skk-save-point (&rest body)
  (` (let ((skk-save-point (point-marker)))
       (unwind-protect
	   (progn (,@ body))
	 (goto-char skk-save-point)
         (skk-set-marker skk-save-point nil) ))))

(defmacro skk-message (japanese english &rest arg)
  ;; skk-japanese-message-and-error $B$,(B non-nil $B$@$C$?$i(B JAPANESE $B$r(B nil $B$G$"$l(B
  ;; $B$P(B ENGLISH $B$r%(%3!<%(%j%"$KI=<($9$k!#(B
  ;; ARG $B$O(B message $B4X?t$NBh#20z?t0J9_$N0z?t$H$7$FEO$5$l$k!#(B
  (append (list 'message (list 'if 'skk-japanese-message-and-error
			       japanese english ))
	  arg ))

(defmacro skk-error (japanese english &rest arg)
  ;; skk-japanese-message-and-error $B$,(B non-nil $B$@$C$?$i(B JAPANESE $B$r(B nil $B$G$"$l(B
  ;; $B$P(B ENGLISH $B$r%(%3!<%(%j%"$KI=<($7!"%(%i!<$rH/@8$5$;$k!#(B
  ;; ARG $B$O(B error $B4X?t$NBh#20z?t0J9_$N0z?t$H$7$FEO$5$l$k!#(B
  (append (list 'error (list 'if 'skk-japanese-message-and-error
			     japanese english ))
	  arg ))

(defmacro skk-yes-or-no-p (japanese english)
  ;; skk-japanese-message-and-error $B$,(B non-nil $B$G$"$l$P!"(Bjapanese $B$r(B nil $B$G$"(B
  ;; $B$l$P(B english $B$r%W%m%s%W%H$H$7$F(B yes-or-no-p $B$r<B9T$9$k!#(B
  ;; yes-or-no-p $B$N0z?t$N%W%m%s%W%H$,J#;($KF~$l9~$s$G$$$k>l9g$O$3$N%^%/%m$r;H(B
  ;; $B$&$h$j%*%j%8%J%k$N(B yes-or-no-p $B$r;HMQ$7$?J}$,%3!<%I$,J#;($K$J$i$J$$>l9g$,(B
  ;; $B$"$k!#(B
  (list 'yes-or-no-p (list 'if 'skk-japanese-message-and-error
				   japanese english )))

(defmacro skk-y-or-n-p (japanese english)
  ;; skk-japanese-message-and-error $B$,(B non-nil $B$G$"$l$P!"(Bjapanese $B$r(B nil $B$G$"(B
  ;; $B$l$P(B english $B$r%W%m%s%W%H$H$7$F(B y-or-n-p $B$r<B9T$9$k!#(B
  (list 'y-or-n-p (list 'if 'skk-japanese-message-and-error
				japanese english )))

(defmacro skk-set-marker (marker position &optional buffer)
  ;; $B%P%C%U%!%m!<%+%kCM$G$"$k(B skk-henkan-start-point, skk-henkan-end-point,
  ;; skk-kana-start-point, $B$"$k$$$O(B skk-okurigana-start-point $B$,(B nil $B$@$C$?$i!"(B
  ;; $B?75,%^!<%+!<$r:n$C$FBeF~$9$k!#(B
  ;;
  ;; skk.el $B$N%P%C%U%!%m!<%+%kCM$N07$$$K$OCm0U$9$Y$-E@$,$"$k!#(B
  ;; $BNc$($P!"$"$k%P%C%U%!(B Buffer A $B$G2<5-$N$h$&$J%U%)!<%`$rI>2A$7$?$H$9$k!#(B
  ;; ---------- Buffer A ---------------+--------------- Buffer B ----------
  ;; (setq test (make-marker))          |
  ;;  -> #<marker in no buffer>         |
  ;;                                    |
  ;; (make-variable-buffer-local 'test) |
  ;;                                    |
  ;; test                               | test
  ;;  -> #<marker in no buffer>         |  -> #<marker in no buffer>
  ;;                                    |
  ;; (set-marker test (point))          |
  ;;                                    |
  ;; test                               | test
  ;;  -> #<marker at 122 in A>          |  -> #<marker at 122 in A>
  ;;
  ;; $B%P%C%U%!%m!<%+%kCM$H$7$F$N@k8@$r$9$kA0$K(B non-nil $BCM$rBeF~$7!"$=$N(B non-nil
  ;; $BCM$rD>@\=q$-JQ$($k$h$&$J%U%)!<%`$rI>2A$9$k$H(B Buffer B $B$+$i8+$($k%G%#%U%)%k(B
  ;; $B%HCM$^$G=q$-JQ$C$F$7$^$&!#>e5-$NNc$O%^!<%+!<$@$,!"2<5-$N$h$&$K%j%9%H$KBP$7(B
  ;; $B$FGK2uE*4X?t$GA`:n$7$?$H$-$bF1MM$N7k2L$H$J$k!#(B
  ;; ---------- Buffer A ---------------+--------------- Buffer B ----------
  ;; (setq test '(A B C))               |
  ;;  -> (A B C)                        |
  ;;                                    |
  ;; (make-variable-buffer-local 'test) |
  ;;                                    |
  ;; test                               | test
  ;;  -> (A B C)                        |  -> (A B C)
  ;;                                    |
  ;; (setcar test 'X)                   |
  ;;                                    |
  ;; test                               | test
  ;;  -> (X B C)                        |  -> (X B C)
  ;;
  ;; $B$3$N8=>]$G0lHV:$$k$N$O!"4A;zEPO?$J$I$G%_%K%P%C%U%!$KF~$C$?$H$-(B
  ;; (skk-henkan-show-candidate $B$N$h$&$KC1$K!V%(%3!<%(%j%"!W$r;HMQ$9$k4X?t$G$O(B
  ;; $B4X78$J$$(B) $B$K!"$b$H$N%P%C%U%!$H%_%K%P%C%U%!$H$G$O$=$l$>$lJL$NJQ49$r9T$J$&(B
  ;; $B$N$,IaDL$G$"$k$N$G!">e5-$N$h$&$KB>$N%P%C%U%!$N%P%C%U%!%m!<%+%kCM$^$G=q$-(B
  ;; $BJQ$($F$7$^$&$H!"JQ49$r5Y;_$7$F$$$kB>$N%P%C%U%!$G@5>o$JJQ49$,$G$-$J$/$J$k(B
  ;; $B>l9g$,$"$k$3$H$G$"$k!#(B
  ;;
  ;; $B$7$+$b(B SKK $B$G$O%j%+!<%7%V%_%K%P%C%U%!$,;HMQ$G$-$k$N$G!"(B *Minibuf-0* $B$H(B
  ;;  *Minibuf-1 $B$N4V(B ($B$"$k$$$O$b$C$H?<$$%j%+!<%7%V%_%K%P%C%U%!F1;N$N4V(B) $B$G%P%C(B
  ;; $B%U%!%m!<%+%kCM$NGK2uE*=q$-JQ$($,9T$J$o$l$F$7$^$$!">e0L$N%_%K%P%C%U%!$KLa$C(B
  ;; $B$?$H$-$K@5>o$JJQ49$,$G$-$J$/$J$k>l9g$,$"$k!#(B
  ;;
  ;; $B$H$3$m$,2<5-$N$h$&$K=i4|CM$r(B nil $B$K$7$F!"%P%C%U%!%m!<%+%kCM$H$7$F$N@k8@8e!"(B
  ;; non-nil $BCM$rBeF~$9$l$P!"0J8e$=$N%P%C%U%!%m!<%+%kCM$KGK2uE*A`:n$r$7$F$b$=$N(B
  ;; $B%P%C%U%!$K8GM-$NCM$7$+JQ2=$7$J$$!#(B
  ;; ---------- Buffer A ---------------+--------------- Buffer B ----------
  ;; (setq test nil)                    |
  ;;                                    |
  ;; (make-variable-buffer-local 'test) |
  ;;                                    |
  ;; test                               | test
  ;;  -> nil                            |  -> nil
  ;;                                    |
  ;; (setq test (make-marker))          |
  ;;  -> #<marker in no buffer>         |
  ;;                                    |
  ;; (set-marker test (point))          |
  ;;                                    |
  ;; test                               | test
  ;;  -> #<marker at 122 in A>          |  -> nil
  ;;
  ;; skk.el 9.3 $B$N;~E@$G$O!"(Bskk-henkan-start-point, skk-henkan-end-point,
  ;; skk-kana-start-point $B5Z$S(B skk-okurigana-start-point $B$N=i4|CM(B
  ;; (make-variable-buffer-local $B$,%3!<%k$5$l$kA0$NCM(B) $B$,(B make-marker $B$NJV$jCM(B
  ;; $B$G$"$k(B #<marker in no buffer> $B$G$"$C$?$N$G!"%j%+!<%7%V%_%K%P%C%U%!$KF~$C(B
  ;; $B$FJQ49$7$?$H$-$K(B "$B"'(B" $B$,>C$($J$$!"$J$I$N%H%i%V%k$,$"$C$?$,!"$3$l$i$N=i4|(B
  ;; $BCM$r(B nil $B$K$7$F;HMQ;~$K(B make-marker $B$NJV$jCM$rBeF~$9$k$h$&$K$7!"$3$NLdBj$r(B
  ;; $B2r7h$7$?!#(B
  (list 'progn
        (list 'if (list 'not marker)
              (list 'setq marker (list 'make-marker)) )
        (list 'set-marker marker position buffer) ))

;; From viper-util.el.  Welcome!
(defmacro skk-deflocalvar (var default-value &optional documentation)
  (` (progn
       (defvar (, var) (, default-value)
	       (, (format "%s\n\(buffer local\)" documentation)))
       (make-variable-buffer-local '(, var))
     )))

;; Message-Id: <19981218224936N.sakurada@kuis.kyoto-u.ac.jp>| Mikio Nakajima <minakaji@osaka.email.ne.jp>
;; From: Hideki Sakurada <sakurada@kuis.kyoto-u.ac.jp>      | $B$N<BAu(B
;; Date: Fri, 18 Dec 1998 22:49:36 +0900 (JST)              | (Mule 4 $B$G$OB?%P%$%HJ8;z$ND9$5$,(B 1 $B$K$J$C$A$c$C$?$N$G!"%+%i%`$,(B
;; $B;32<$5$s(B:                                                 | $B$=$m$o$s$<$h(B...$B%H%[%[!#(BPicture mode $B$N0UL#H>8:(B...)
;; > $B$d$O$j!"%+!<%=%k0\F0$r$7$?>l9g$O(B skk-prefix $B$r%/%j%"$7$F$l(B     |
;; > $BJ}$,$&$l$7$$$h$&$J5$$,$7$^$9!#(B                              | o with-point-move $B$C$FL>A0$O%+%C%3$$$$$7!"$=$N$^$^;H$$$?$+$C$?(B
;; $B$3$N$"$?$j$O$J$s$H$+$7$?$$$H$3$m$N0l$D$G$9$M(B.                   |   $B$s$@$1$I!"B>$N%Q%C%1!<%8$HL>A0$N>WFM$,5/$3$C$F$O$$$1$J$$$N$G!"(B
;; $B%3!<%G%#%s%0$9$k2K$b$J$$$N$GC1$J$k;W$$$D$-$G$9$,(B...              |   `skk-' prefix $B$rIU$1$?!#(B
;;                                                          |
;; (1) pre-command-hook $B$h$j$b(B post-command-hook $B$H(B          |
;; last-command $B$NAH$_$"$o$;$N$[$&$,$$$$5$$,$9$k(B.                |
;; (2) $B!V%+!<%=%k(B($B%]%$%s%H(B)$B$N0\F0!W$rCj>]2=$7$?$[$&$,(B              |
;; $B$$$$5$$,$9$k(B. $B$?$H$($P$3$s$J$+$s$8(B.                           |
;; # 10$BJ,$G=q$$$?$N$G$"$C$5$jGKC>$9$k$+$b(B...                     |
;;                                                          |
;; -- $B]/ED(B                                                  |
;;                                                         |
;; $B2>Dj(B:                                                    |
;;   with-point-move $B$G$O%P%C%U%!$r$^$?$,$k0\F0$O$7$J$$(B          | o $B$3$N2>Dj$r$=$N$^$^A0Ds$H$7$?!#(B
;; TODO:                                                   |
;;   hook/$BJQ?t$r%P%C%U%!%m!<%+%k$K$9$kI,MW$,$"$k(B                  | o skk-previous-point $BJQ?t!"(Bpost-command-hook $B$r$=$l$>$l(B
;;                                                         |   $B%P%C%U%!%m!<%+%kJQ?t!&%U%C%/$K$7$?(B (skk-mode $B$r5/F0$7$?(B
;;                                                          |   $B%P%C%U%!$@$1$GF0:n$5$;$k$?$a(B)$B!#(B
;;                                                          |
;;   with-point-move $B$G$N%(%i!<$,$*$-$?$i(B? (unwinding)         | o $B%P%C%U%!$r$^$?$,$J$$!"$H$$$&2>Dj$r$7$?$N$G!"(Bunwinding $B$K$D(B
;;                                                          |   $B$$$F$O(B skk-previous-point $B$N%;%C%H0J30$O9MN8$7$F$$$J$$!#(B
;;                                                          |
;; SKK$BB&$NJQ99(B:                                              |
;;   skk-kana-input $BEy$O$[$H$s$I(B (with-point-move ...)        | o post-command-hook $B$H$$$&$0$i$$$@$+$i!"(Binteractive command
;;   $B$G0O$`(B                                                  |        ^^^^^^^
;;                                                          |   $B$@$1$KE*$r$7$\$C$F(B skk-with-point-move $B$r;H$C$?!#(B
;;                                                          |
;; point $B$,0\F0$7$?$H$-$KAv$k(B hook                             |
;; (defvar point-move-hook)                                 | o $BJ#?t$N4X?t$r%U%C%/$KF~$l$?$j$7$J$$$N$G!"$3$N%U%C%/$O<BAu$7$J$$!#(B
;;                                                          |
;; $B%]%$%s%H$rJ]B8$9$kJQ?t(B                                      |
;; (defvar previous-point nil)                              | o skk-previous-point $B$r(B skk-deflocalvar $B$G@k8@!#(B
;;                                                          |
;; $B%]%$%s%H$r0\F0$9$k$,%U%C%/$r<B9T$7$F$[$7$/$J$$>l9g$K;H$&(B          |
;;(defmacro with-point-move (&rest form)                    | o `skk-' prefix $B$rIU$1$[$H$s$I$=$N$^$^%Q%/$j!#(B
;;  `(progn                                                 |
;;     ,@form                                               |
;;     (setq previous-point (point))))                      |
;;                                                          |
;;;; $B%]%$%s%H$,0\F0$7$?$i(B point-move-hook $B$r<B9T(B                |
;;(defun point-move-hook-execute ()                         | o skk-after-point-move $B$H$7$F(B inline function $B$H$7$F<BAu!#(B
;;  (if (and point-move-hook                                |   $B%U%C%/$r(B run $B$;$:$K!"4X?t$NCf$GI,MW=hM}$r$3$J$9!#(B
;;         (or (null previous-point)                        |
;;             (not (= previous-point (point)))))           |
;;      (with-point-move                                    |
;;       (run-hooks 'point-move-hook))))                    |
;;                                                          |
;;                                                          |
;;(add-hook 'post-command-hook 'point-move-hook-execute)    | o skk-mode $B$NCf$G%U%C%/$r%m!<%+%k2=$7$F(B skk-after-point-move
;;                                                          |   $B$r%U%C%/$7$?!#(B
;;                                                          |
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;   |
;;
;; $BNc(B
;;
;; (defun foo ()
;;   (message "move !")
;;   (beep))
;;
;; (add-hook 'point-move-hook 'foo)

(defmacro skk-with-point-move (&rest form)
  ;; $B%]%$%s%H$r0\F0$9$k$,%U%C%/$r<B9T$7$F$[$7$/$J$$>l9g$K;H$&!#(B
  (` (unwind-protect
	 (progn (,@ form))
       (setq skk-previous-point (point)) )))

;;) ;eval-when-compile

(put 'skk-deflocalvar 'lisp-indent-function 'defun)

;;(defun-maybe mapvector (function sequence)
;;  "Apply FUNCTION to each element of SEQUENCE, making a vector of the results.
;;The result is a vector of the same length as SEQUENCE.
;;SEQUENCE may be a list, a vector or a string."
;;  (vconcat (mapcar function sequence) nil) )

;;(defun-maybe mapc (function sequence)
;;  "Apply FUNCTION to each element of SEQUENCE.
;;SEQUENCE may be a list, a vector, a bit vector, or a string.
;;--- NOT emulated enough, just discard newly constructed list made by mapcar ---
;;This function is like `mapcar' but does not accumulate the results,
;;which is more efficient if you do not use the results."
;;  (mapcar function sequence)
;;  sequence )

(defun skk-terminal-face-p ()
  (and (not window-system)
       (fboundp 'frame-face-alist) ;; $BJQ?tL>$_$?$$$J4X?t$@$J(B...$B!#(B
       (fboundp 'selected-frame) ))

(defsubst skk-lower-case-p (char)
  ;; CHAR $B$,>.J8;z$N%"%k%U%!%Y%C%H$G$"$l$P!"(Bt $B$rJV$9!#(B
  (and (<= ?a char) (>= ?z char) ))

;;;; inline functions
(defsubst skk-downcase (char)
  (or (cdr (assq char skk-downcase-alist)) (downcase char)) )

(defsubst skk-mode-off ()
  (setq skk-mode nil
        skk-abbrev-mode nil
        skk-latin-mode nil
        skk-j-mode nil
        skk-jisx0208-latin-mode nil
        ;; j's sub mode.
        skk-katakana nil )
  ;; initialize
  (setq skk-input-mode-string skk-hiragana-mode-string)
  (skk-set-cursor-color skk-default-cursor-color)
  (force-mode-line-update)
  (remove-hook 'pre-command-hook 'skk-pre-command 'local) )

(defsubst skk-j-mode-on (&optional katakana)
  (setq skk-mode t
        skk-abbrev-mode nil
        skk-latin-mode nil
        skk-j-mode t
        skk-jisx0208-latin-mode nil
        ;; j's sub mode.
        skk-katakana katakana )
  ;; mode line
  (if katakana
      (progn
        (setq skk-input-mode-string skk-katakana-mode-string)
        (skk-set-cursor-color skk-katakana-cursor-color) )
    (setq skk-input-mode-string skk-hiragana-mode-string)
    (skk-set-cursor-color skk-hiragana-cursor-color) )
  (force-mode-line-update) )

(defsubst skk-latin-mode-on ()
  (setq skk-mode t
        skk-abbrev-mode nil
        skk-latin-mode t
        skk-j-mode nil
        skk-jisx0208-latin-mode nil
        ;; j's sub mode.
        skk-katakana nil
        skk-input-mode-string skk-latin-mode-string )
  (skk-set-cursor-color skk-latin-cursor-color)
  (force-mode-line-update) )

(defsubst skk-jisx0208-latin-mode-on ()
  (setq skk-mode t
        skk-abbrev-mode nil
        skk-latin-mode nil
        skk-j-mode nil
        skk-jisx0208-latin-mode t
        ;; j's sub mode.
        skk-katakana nil
        skk-input-mode-string skk-jisx0208-latin-mode-string )
  (skk-set-cursor-color skk-jisx0208-latin-cursor-color)
  (force-mode-line-update) )

(defsubst skk-abbrev-mode-on ()
  (setq skk-mode t
        skk-abbrev-mode t
        skk-latin-mode nil
        skk-j-mode nil
        skk-jisx0208-latin-mode nil
        ;; j's sub mode.
        skk-katakana nil
        skk-input-mode-string skk-abbrev-mode-string )
  (skk-set-cursor-color skk-abbrev-cursor-color)
  (force-mode-line-update) )

(defsubst skk-in-minibuffer-p ()
  ;; $B%+%l%s%H%P%C%U%!$,%_%K%P%C%U%!$+$I$&$+$r%A%'%C%/$9$k!#(B
  (window-minibuffer-p (selected-window)) )

(defsubst skk-insert-prefix (&optional char)
  ;; skk-echo $B$,(B non-nil $B$G$"$l$P%+%l%s%H%P%C%U%!$K(B skk-prefix $B$rA^F~$9$k!#(B
  (and skk-echo
       ;; skk-prefix $B$NA^F~$r%"%s%I%%$NBP>]$H$7$J$$!#A^F~$7$?%W%l%U%#%C%/%9$O!"(B
       ;; $B$+$JJ8;z$rA^F~$9$kA0$KA4$F>C5n$9$k$N$G!"$=$N4V!"(Bbuffer-undo-list $B$r(B
       ;; t $B$K$7$F%"%s%I%%>pJs$rC_$($J$/$H$bLdBj$,$J$$!#(B
       (let ((buffer-undo-list t))
         (insert-and-inherit (or char skk-prefix)) )))

(defsubst skk-erase-prefix (&optional clean)
  ;; skk-echo $B$,(B non-nil $B$G$"$l$P%+%l%s%H%P%C%U%!$KA^F~$5$l$?(B skk-prefix $B$r>C(B
  ;; $B$9!#%*%W%7%g%J%k0z?t$N(B CLEAN $B$,;XDj$5$l$k$H!"JQ?t$H$7$F$N(B skk-prefix $B$r(B
  ;; null $BJ8;z$K!"(Bskk-current-rule-tree $B$r(B nil $B=i4|2=$9$k!#(B
  ;;
  ;; $B$+$JJ8;z$NF~NO$,$^$@40@.$7$F$$$J$$>l9g$K$3$N4X?t$,8F$P$l$?$H$-$J$I$O!"%P%C(B
  ;; $B%U%!$KA^F~$5$l$F$$$k(B skk-prefix $B$O:o=|$7$?$$$,!"JQ?t$H$7$F$N(B skk-prefix $B$O(B
  ;; null $BJ8;z$K$7$?$/$J$$!#(B
  (and skk-echo skk-kana-start-point
       (not (string= skk-prefix "")) ; fail safe.
       ;; skk-prefix $B$N>C5n$r%"%s%I%%$NBP>]$H$7$J$$!#(B
       (let ((buffer-undo-list t)
	     (start (marker-position skk-kana-start-point)) )
	 (and start (delete-region start (+ start (length skk-prefix)))) ))
  (and clean (setq skk-prefix ""
		   skk-current-rule-tree nil ))) ; fail safe

(defsubst skk-string<= (str1 str2)
  ;; STR1 $B$H(B STR2 $B$H$rHf3S$7$F!"(Bstring< $B$+(B string= $B$G$"$l$P!"(Bt $B$rJV$9!#(B
  (or (string< str1 str2) (string= str1 str2)) )

(defsubst skk-do-auto-fill ()
  ;; auto-fill-function $B$KCM$,BeF~$5$l$F$*$l$P!"(Bdo-auto-fill $B$r%3!<%k$9$k!#(B
  (and auto-fill-function (funcall auto-fill-function)) )

;;;; from dabbrev.el.  Welcome!
;; $BH=Dj4V0c$$$rHH$9>l9g$"$j!#MW2~NI!#(B
(defsubst skk-minibuffer-origin ()
  (nth 1 (buffer-list)) )

(defsubst skk-current-insert-mode ()
  (cond (skk-abbrev-mode 'abbrev)
	(skk-latin-mode 'latin)
	(skk-jisx0208-latin-mode 'jisx0208-latin)
	(skk-katakana 'katakana)
	(skk-j-mode 'hiragana) ))

(defsubst skk-numeric-p ()
  (and skk-use-numeric-conversion (require 'skk-num) skk-num-list) )

(defsubst skk-substring-head-character (string)
  (char-to-string (string-to-char string)) )

(defsubst skk-get-current-candidate-simply (&optional noconv)
  (if (> skk-henkan-count -1)
      ;; (nth -1 '(A B C)) $B$O!"(BA $B$rJV$9$N$G!"Ii$G$J$$$+$I$&$+%A%'%C%/$9$k!#(B
      (let ((word (nth skk-henkan-count skk-henkan-list)))
        (and word
             (if (and (skk-numeric-p) (consp word))
                 (if noconv (car word) (cdr word))
               word )))))

;; convert skk-rom-kana-rule-list to skk-rule-tree.
;; The rule tree follows the following syntax:
;; <branch-list>    ::= nil | (<tree> . <branch-list>)
;; <tree>         ::= (<char> <prefix> <nextstate> <kana> <branch-list>)
;; <kana>         ::= (<$B$R$i$,$JJ8;zNs(B> . <$B%+%?%+%JJ8;zNs(B>) | nil
;; <char>         ::= <$B1Q>.J8;z(B>
;; <nextstate>    ::= <$B1Q>.J8;zJ8;zNs(B> | nil

;; $B%D%j!<$K%"%/%;%9$9$k$?$a$N%$%s%?!<%U%'!<%9(B

(defsubst skk-make-rule-tree (char prefix nextstate kana branch-list)
  (list char
	prefix
	(if (string= nextstate "") nil nextstate)
	kana
	branch-list ))

(defsubst skk-get-char (tree)
  (car tree) )

(defsubst skk-set-char (tree char)
  (setcar tree char) )

(defsubst skk-set-prefix (tree prefix)
  (setcar (nthcdr 1 tree) prefix) )

(defsubst skk-get-prefix (tree)
  (nth 1 tree) )

(defsubst skk-get-nextstate (tree)
  (nth 2 tree) )

(defsubst skk-set-nextstate (tree nextstate)
  (if (string= nextstate "") (setq nextstate nil))
  (setcar (nthcdr 2 tree) nextstate) )

(defsubst skk-get-kana (tree)
  (nth 3 tree) )

(defsubst skk-set-kana (tree kana)
  (setcar (nthcdr 3 tree) kana) )

(defsubst skk-get-branch-list (tree)
  (nth 4 tree) )

(defsubst skk-set-branch-list (tree branch-list)
  (setcar (nthcdr 4 tree) branch-list) )

;; tree procedure for skk-kana-input.
(defsubst skk-add-branch (tree branch)
  (skk-set-branch-list tree (cons branch (skk-get-branch-list tree))) )

(defsubst skk-select-branch (tree char)
  (assq char (skk-get-branch-list tree)) )

(defsubst skk-kana-cleanup (&optional force)
  (let ((data (or
	       (and skk-current-rule-tree
		    (null (skk-get-nextstate skk-current-rule-tree))
		    (skk-get-kana skk-current-rule-tree) )
	       (and skk-kana-input-search-function
		    (car (funcall skk-kana-input-search-function)) )))
	kana )
	(if (or force data)
	    (progn
	      (skk-erase-prefix 'clean)
	      (setq kana (if (functionp data) (funcall data nil) data))
	      (if (consp kana)
		  (setq kana (if skk-katakana (car kana) (cdr kana))) )
	      (if (stringp kana) (skk-insert-str kana))
	      (skk-set-marker skk-kana-start-point nil)
	      t ))))

(defsubst skk-pre-command ()
  (and (memq last-command '(skk-insert skk-previous-candidate))
       (null (memq this-command
		   '(skk-delete-backward-char
		     skk-insert
		     skk-previous-candidate
		     vip-del-backward-char-in-insert
		     viper-del-backward-char-in-insert )))
       (skk-kana-cleanup t) ))

(defsubst skk-make-raw-arg (arg)
  (cond ((= arg 1) nil)
	((= arg -1) '-)
	((numberp arg) (list arg)) ))

(defsubst skk-unread-event (event)
  ;; Unread single EVENT.
  (setq unread-command-events (nconc unread-command-events (list event))) )

(defsubst skk-after-point-move ()
  (and (or (not skk-previous-point) (not (= skk-previous-point (point))))
       (skk-get-prefix skk-current-rule-tree)
       (skk-with-point-move (skk-erase-prefix 'clean)) ))

;;(defsubst skk-get-current-henkan-data (key)
;;  (cdr (assq key skk-current-henkan-data)) )

;;(defsubst skk-put-current-henkan-data (key val)
;;  (setq skk-current-henkan-data (put-alist key val skk-current-henkan-data)) )

(defsubst skk-get-last-henkan-data (key)
  (cdr (assq key skk-last-henkan-data)) )

(defsubst skk-put-last-henkan-data (key val)
  (setq skk-last-henkan-data (put-alist key val skk-last-henkan-data)) )

;;;; aliases
;; for backward compatibility.
(define-obsolete-function-alias 'skk-zenkaku-mode 'skk-jisx0208-latin-mode)
(define-obsolete-function-alias 'skk-zenkaku-mode-on 'skk-jisx0208-latin-mode-on)
(define-obsolete-function-alias 'skk-zenkaku-insert 'skk-jisx0208-latin-insert)
(define-obsolete-function-alias 'skk-zenkaku-region 'skk-jisx0208-latin-region)
(define-obsolete-function-alias 'skk-zenkaku-henkan 'skk-jisx0208-latin-henkan)
(define-obsolete-function-alias 'skk-ascii-mode-on 'skk-latin-mode-on)
(define-obsolete-function-alias 'skk-ascii-mode 'skk-latin-mode)
(define-obsolete-function-alias 'skk-ascii-region 'skk-latin-region)
(define-obsolete-function-alias 'skk-ascii-henkan 'skk-latin-henkan)
(define-obsolete-function-alias 'skk-convert-ad-to-gengo 'skk-ad-to-gengo)
(define-obsolete-function-alias 'skk-convert-gengo-to-ad 'skk-gengo-to-ad)
(define-obsolete-function-alias 'skk-isearch-forward 'isearch-forward)
(define-obsolete-function-alias 'skk-isearch-forward-regexp 'isearch-forward-regexp)
(define-obsolete-function-alias 'skk-isearch-backward 'isearch-backward)
(define-obsolete-function-alias 'skk-isearch-backward-regexp 'isearch-backward-regexp)

(defconst skk-background-mode
  ;; from font-lock-make-faces of font-lock.el  Welcome!
  (cond
   ((eq skk-emacs-type 'xemacs)
    (if (< (apply '+ (color-rgb-components
                      (face-property 'default 'background) ))
           (/ (apply '+ (color-rgb-components
                         (make-color-specifier "white"))) 3))
        'dark
      'light ))
   ((and window-system (x-display-color-p))
    (let ((bg-resource (x-get-resource ".backgroundMode"
                                       "BackgroundMode"))
          params )
      (if bg-resource
          (intern (downcase bg-resource))
        (setq params (frame-parameters))
        (cond ((cdr (assq 'background-mode params)));; Emacs20.x (Meadow)
	      ;; Mule for Win32 $B$r(B Windows 95 $B$GF0$+$7$F$$$k$H$-$O!"(B
	      ;; system-type $B$O!)(B  -> windows-nt $B$G$7$?!#(B
	      ((and (eq system-type 'windows-nt);; Mule for Win32
                    (fboundp 'win32-color-values) )
               (< (apply '+ (win32-color-values
                             (cdr (assq 'background-color params)) ))
                  (/ (apply '+ (win32-color-values "white")) 3) )
               'dark )
              ((and (memq system-type '(ms-dos windows-nt))
                    (fboundp 'x-color-values) )
               (if (string-match "light"
                                 (cdr (assq 'background-color params)) )
                   'light
                 'dark ))
              ((< (apply '+ (x-color-values
                             (cdr (assq 'background-color params)) ))
                  (/ (apply '+ (x-color-values "white")) 3) )
               'dark )
              (t 'light) ))))
   (t 'mono) ))

;;;; version specific matter.
(eval-and-compile
  ;; Emacs ver. $B$K$h$kJ,N`(B
  (cond ((eq skk-emacs-type 'xemacs)
	 (defalias 'skk-char-to-string 'char-to-string)
	 (defalias 'skk-read-event 'next-command-event)
	 )
	(t
	 ;; for Mule/GNU Emacs
         (defalias 'skk-read-event 'read-event)

	 (if (string< "20" emacs-version)
	     ;; for Emacs 20.x
	     (defun skk-char-to-string (char)
	       (condition-case nil (char-to-string char) (error nil)) )
	   ;; for Emacs 19.x
	   (defalias 'skk-char-to-string 'char-to-string) )))

  ;; Mule ver. $B$K$h$kJ,N`(B
  (cond ((eq skk-emacs-type 'xemacs)
	 (defsubst skk-ascii-char-p (char)
	   ;; CHAR $B$,(B ascii $BJ8;z$@$C$?$i(B t $B$rJV$9!#(B
	   (eq (char-charset char) 'ascii) )
	 (defalias 'skk-charsetp (cond ((fboundp 'charsetp) 'charsetp)
				       ;; Is there XEmacs that doesn't have
				       ;; `charsetp'?
				       (t 'find-charset) ))
	 (defun skk-make-char (charset n1 n2)
	   (make-char charset
		      (logand (lognot 128) n1)
		      (logand (lognot 128) n2) ))
	 (defsubst skk-jisx0208-p (char)
	   (eq (char-charset char) 'japanese-jisx0208) )
	 (defun skk-jisx0208-to-ascii (string)
	   (require 'japan-util)
	   (let ((char
		  (get-char-code-property (string-to-char string) 'ascii) ))
	     (and char (char-to-string char)) ))
	 (defalias 'skk-str-length 'length)
	 (defalias 'skk-str-ref 'aref)
	 (defalias 'skk-substring 'substring)
	 )

	((eq skk-emacs-type 'mule4)
	 (defsubst skk-ascii-char-p (char)
	   ;; CHAR $B$,(B ascii $BJ8;z$@$C$?$i(B t $B$rJV$9!#(B
	   (eq (char-charset char) 'ascii) )
	 (defalias 'skk-charsetp 'charsetp)
	 (defalias 'skk-make-char 'make-char)
	 (defsubst skk-jisx0208-p (char)
	   (eq (char-charset char) 'japanese-jisx0208) )
	 (defun skk-jisx0208-to-ascii (string)
	   (require 'japan-util)
	   (let ((char
		  (get-char-code-property (string-to-char string) 'ascii) ))
	     (and char (char-to-string char)) ))
	 (defalias 'skk-str-length 'length)
	 (defalias 'skk-str-ref 'aref)
	 (defalias 'skk-substring 'substring)
	 )

	((eq skk-emacs-type 'mule3)
 	 (defsubst skk-ascii-char-p (char)
 	   ;; CHAR $B$,(B ascii $BJ8;z$@$C$?$i(B t $B$rJV$9!#(B
 	   (eq (char-charset char) 'ascii) )
	 (defalias 'skk-charsetp 'charsetp)
	 (defalias 'skk-make-char 'make-char)
	 (defsubst skk-jisx0208-p (char)
	   (eq (char-charset char) 'japanese-jisx0208) )
	 (defun skk-jisx0208-to-ascii (string)
	   (require 'japan-util)
	   (let ((char
		  (get-char-code-property (string-to-char string) 'ascii) ))
	     (and char (char-to-string char)) ))
	 (defun skk-str-length (str)
	   (length (string-to-vector str)) )
	 (defun skk-str-ref (str pos)
	   (aref (string-to-vector str) pos ) )
	 (defun skk-substring (str pos1 pos2)
	   (if (< pos1 0)
	       (setq pos1 (+ (skk-str-length str) pos1)) )
	   (if (< pos2 0)
	       (setq pos2 (+ (skk-str-length str) pos2)) )
	   (if (>= pos1 pos2)
	       ""
	     (let ((sl (nthcdr pos1 (string-to-char-list str))))
	       (setcdr (nthcdr (- pos2 pos1 1) sl) nil)
	       (concat sl) )))
	 )

	((eq skk-emacs-type 'mule2)
	 (defsubst skk-ascii-char-p (char)
	   ;; CHAR $B$,(B ascii $BJ8;z$@$C$?$i(B t $B$rJV$9!#(B
	   (= (char-leading-char char) 0) )
	 (defalias 'skk-charsetp 'character-set)
	 (defalias 'skk-make-char 'make-chararacter)
	 (defsubst skk-jisx0208-p (char)
	   (= (char-leading-char char) lc-jp) )
	 (defun skk-jisx0208-to-ascii (string)
	   (let ((char
		  (let* ((ch (string-to-char string))
			 (ch1 (char-component ch 1)) )
		    (cond ((eq 161 ch1)	; ?\241
			   (cdr (assq (char-component ch 2) skk-hankaku-alist)) )
			  ((eq 163 ch1)	; ?\243
			   (- (char-component ch 2) 128) ; ?\200
			   )))))
	     (and char (char-to-string char)) ))
	 (defun skk-str-length (str)
	   (length (string-to-char-list str)) )
	 (defun skk-str-ref (str pos)
	   (nth pos (string-to-char-list str)) )
	 (defun skk-substring (str pos1 pos2)
	   (if (< pos1 0)
	       (setq pos1 (+ (skk-str-length str) pos1)) )
	   (if (< pos2 0)
	       (setq pos2 (+ (skk-str-length str) pos2)) )
	   (if (>= pos1 pos2)
	       ""
	     (let ((sl (nthcdr pos1 (string-to-char-list str))))
	       (setcdr (nthcdr (- pos2 pos1 1) sl) nil)
	       (mapconcat 'char-to-string sl "") )))
	 )))

(eval-after-load "hilit19"
  '(mapcar (function
            (lambda (pattern)
              (hilit-add-pattern
               (car pattern) (cdr pattern)
               (cond ((eq skk-background-mode 'mono)
                      'bold )
                     ((eq skk-background-mode 'light)
                      'RoyalBlue )
                     (t 'cyan) )
               'emacs-lisp-mode )))
           '(("^\\s *(skk-deflocalvar\\s +\\S +" . "")) ))

(eval-after-load "font-lock"
  '(cons '("^(\\(skk-deflocalvar\\)[ \t'\(]*\\(\\sw+\\)?"
	   (1 font-lock-keyword-face)
	   (2 font-lock-variable-name-face) )
	 lisp-font-lock-keywords-2 ))

(defun skk-define-menu-bar-map (map)
  ;; SKK $B%a%K%e!<$N%H%C%W$K=P8=$9$k%3%^%s%I$N%a%K%e!<$X$NDj5A$r9T$J$&!#(B
  (easy-menu-define
   skk-menu map
   "Menu used in SKK mode."
   '("SKK"
     ("Convert Region and Echo"
      ("Gyakubiki"
       ["to Hiragana" skk-gyakubiki-message
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Hiragana, All Candidates"
        ;; $B$"$l$l!"(Blambda $B4X?t$ODj5A$G$-$J$$$N$+!)!)!)(B  $BF0$+$J$$$>(B...$B!#(B
        (function (lambda (start end) (interactive "r")
                    (skk-gyakubiki-message start end 'all-candidates) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana" skk-gyakubiki-katakana-message
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana, All Candidates"
        (function (lambda (start end) (interactive "r")
                    (skk-gyakubiki-katakana-message
                     start end 'all-candidates ) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       )
      ("Hurigana"
       ["to Hiragana" skk-hurigana-message
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Hiragana, All Candidates"
        (function (lambda (start end) (interactive "r")
                    (skk-hurigana-message start end 'all-candidates) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana" skk-hurigana-katakana-message
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana, All Candidates"
        (function (lambda (start end) (interactive "r")
                    (skk-hurigana-katakana-message
                     start end 'all-candidates) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       )
      )
     ("Convert Region and Replace"
      ["Ascii" skk-ascii-region
       (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
      ("Gyakubiki"
       ["to Hiragana" skk-gyakubiki-region
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Hiragana, All Candidates"
        (function (lambda (start end) (interactive "r")
                    (skk-gyakubiki-region start end 'all-candidates) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana" skk-gyakubiki-katakana-region
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana, All Candidates"
        (function (lambda (start end) (interactive "r")
                    (skk-gyakubiki-katakana-region
                     start end 'all-candidates ) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       )
      ["Hiragana" skk-hiragana-region
       (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
      ("Hurigana"
       ["to Hiragana" skk-hurigana-region
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Hiragana, All Candidates"
        (function (lambda (start end) (interactive "r")
                    (skk-hurigana-region start end 'all-candidates) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana" skk-hurigana-katakana-region
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       ["to Katakana, All Candidates" (function
                                       (lambda (start end) (interactive "r")
                                         (skk-hurigana-katakana-region
                                          start end 'all-candidates) ))
        (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
       )
      ["Katakana" skk-katakana-region
       (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
      ["Romaji" skk-romaji-region
       (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
      ["Zenkaku" skk-jisx0208-latin-region
       (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
      )
     ["Count Jisyo Candidates" skk-count-jisyo-candidates
      (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
     ["Save Jisyo" skk-save-jisyo
      (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
     ["Undo Kakutei" skk-undo-kakutei
      (or (not (boundp 'skktut-problem-count)) (eq skktut-problem-count 0)) ]
     ["Version" skk-version
      (or (not (boundp 'skktut-problem-count))
          (eq skktut-problem-count 0)) ]
     )))

(provide 'skk-foreword)
;;; Local Variables:
;;; eval: (put 'skk-deflocalvar 'lisp-indent-hook 'defun)
;;; End:
;;; skk-forwords.el ends here
