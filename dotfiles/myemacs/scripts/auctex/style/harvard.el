;; Support for Harvard Citation style package for AUC-TeX
;;      Harvard citation style is from Peter Williams
;;      available on the CTAN servers

;; Version: $Id: harvard.el,v 1.7 1999/07/16 13:48:17 abraham Exp $

;; Copyright (C) 1994 Berwin Turlach <berwin@core.ucl.ac.be>
;; Copyright (C) 1997 Berwin Turlach <berwin.turlach@anu.edu.au>

;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation; either version 1, or (at your option)
;; any later version.
;; 
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;; 
;; You should have received a copy of the GNU General Public License
;; along with this program; if not, write to the Free Software
;; Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

;;; Code:

(TeX-add-style-hook "harvard"
 (function
  (lambda ()

    (LaTeX-add-environments
     '("thebibliography" LaTeX-env-harvardbib ignore))

    (TeX-add-symbols
     "harvardand"
     '("citeasnoun"
       (TeX-arg-conditional TeX-arg-cite-note-p ([ "Note" ]) nil)
       TeX-arg-cite)
     '("possessivecite"
       (TeX-arg-conditional TeX-arg-cite-note-p ([ "Note" ]) nil)
       TeX-arg-cite)
     '("citeaffixed"
       (TeX-arg-conditional TeX-arg-cite-note-p ([ "Note" ]) nil)
       TeX-arg-cite "Affix")
     '("citeyear"
       (TeX-arg-conditional TeX-arg-cite-note-p ([ "Note" ]) nil)
       TeX-arg-cite)
     '("citename"
       (TeX-arg-conditional TeX-arg-cite-note-p ([ "Note" ]) nil)
       TeX-arg-cite)
     '("citationstyle"
       (TeX-arg-eval completing-read "Citation style: " '(("agsm") ("dcu"))))
     '("citationmode"
       (TeX-arg-eval completing-read "Citation mode: "
                     '(("full") ("abbr") ("default"))))
     '("harvardparenthesis"
       (TeX-arg-eval completing-read "Harvardparenthesis: "
                     '(("round") ("curly") ("angle") ("square"))))
     '("bibliographystyle"
       (TeX-arg-eval
	completing-read "Bibliography style: "
        '(("agsm") ("apsr") ("dcu") ("jmr") ("jphysicsB") ("kluwer") ("nederlands") ("econometrica")))
       ignore)
     '("harvarditem" [ "Short citation" ]
       "Complete citation" "Year" TeX-arg-define-cite))

    (setq TeX-complete-list
	  (append '(("\\\\citeasnoun\\[[^]\n\r\\%]*\\]{\\([^{}\n\r\\%,]*\\)"
                     1 LaTeX-bibitem-list "}")
                    ("\\\\citeasnoun{\\([^{}\n\r\\%,]*\\)" 1
                     LaTeX-bibitem-list "}")
                    ("\\\\possessivecite\\[[^]\n\r\\%]*\\]{\\([^{}\n\r\\%,]*\\)" 
                     1 LaTeX-bibitem-list "}")
                    ("\\\\possessivecite{\\([^{}\n\r\\%,]*\\)" 1
                     LaTeX-bibitem-list "}")
                    ("\\\\citename\\[[^]\n\r\\%]*\\]{\\([^{}\n\r\\%,]*\\)"
                     1 LaTeX-bibitem-list "}")
                    ("\\\\citename{\\([^{}\n\r\\%,]*\\)" 1
                     LaTeX-bibitem-list "}")
                    ("\\\\citeaffixed\\[[^]\n\r\\%]*\\]{\\([^{}\n\r\\%,]*\\)"
                     1 LaTeX-bibitem-list "}")
                    ("\\\\citeaffixed{\\([^{}\n\r\\%,]*\\)" 1
                     LaTeX-bibitem-list "}") 
                    ("\\\\citeaffixed{\\([^{}\n\r\\%]*,\\)\\([^{}\n\r\\%,]*\\)"
                     2 LaTeX-bibitem-list)
                    ("\\\\citeyear\\[[^]\n\r\\%]*\\]{\\([^{}\n\r\\%,]*\\)"
                     1 LaTeX-bibitem-list "}")
                    ("\\\\citeyear{\\([^{}\n\r\\%,]*\\)" 1
                     LaTeX-bibitem-list "}") 
                    ("\\\\citeyear{\\([^{}\n\r\\%]*,\\)\\([^{}\n\r\\%,]*\\)"
                     2 LaTeX-bibitem-list))
		  TeX-complete-list))

    (setq LaTeX-auto-regexp-list
          (append '(("\\\\harvarditem{\\([a-zA-Z][^%#'()={}]*\\)}{\\([0-9][^, %\"#'()={}]*\\)}{\\([a-zA-Z][^, %\"#'()={}]*\\)}" 3 LaTeX-auto-bibitem)
                    ("\\\\harvarditem\\[[^][\n\r]+\\]{\\([a-zA-Z][^%#'()={}]*\\)}{\\([0-9][^, %\"#'()={}]*\\)}{\\([a-zA-Z][^, %\"#'()={}]*\\)}" 3 LaTeX-auto-bibitem)
                    )
                  LaTeX-auto-regexp-list))
    
    (setq LaTeX-item-list
	  (cons '("thebibliography" . LaTeX-item-harvardbib)
		LaTeX-item-list)))))

(defun LaTeX-env-harvardbib (environment &optional ignore)
  "Insert ENVIRONMENT with label for harvarditem."
  (LaTeX-insert-environment environment
			    (concat TeX-grop "xx" TeX-grcl))
  (end-of-line 0)
  (delete-char 1)
  (delete-horizontal-space)
  (LaTeX-insert-item))

;; Analog to LaTeX-item-bib from latex.el
(defun LaTeX-item-harvardbib ()
  "Insert a new harvarditem."
  (TeX-insert-macro "harvarditem"))

;; harvard.el ends here
