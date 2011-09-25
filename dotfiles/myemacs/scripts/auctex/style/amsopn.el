;;; amsopn.el --- Style hook for the AMS-LaTeX amsopn package.
;;;
;;; AUTHOR: Carsten Dominik <dominik@strw.leidenuniv.nl>

;;; Code:

(TeX-add-style-hook "amsopn"
 (function
  (lambda ()
    (TeX-add-symbols
     '("DeclareMathOperator"  "Operator (with \\)" "Text")
     '("DeclareMathOperator*" "Operator (with \\)" "Text")
     "mod" "bmod" "pmod" "pod"
     ))))

;;; amsopn.el ends here.
