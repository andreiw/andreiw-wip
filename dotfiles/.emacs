;;; Time-stamp: <2011-09-24 03:26:52 andreiw>
;;; Andrey Warkentin's .emacs file
;;; Modified from Eugen Warkentin's .emacs file
;;; ---------------------------------------------
;;; This file was born the November 1995

;;; Make the .emacs self compiling
(defvar init-top-level t)
(if init-top-level
    (let ((init-top-level nil))
      (if (file-newer-than-file-p "~/.emacs" "~/.emacs.elc")
          (progn                                                 
            (byte-compile-file "~/.emacs")
            (load "~/.emacs.elc"))
        (load "~/.emacs.elc")))
  (progn    

;;; No hide on C-Z.
;;;    (global-set-key "\C-z" nil)
    
;;; Debugger mode
    (setq debug-on-error nil)
    
;;; Emacs Load Path: adding private directories
    (setq load-path (cons "~/myemacs/scripts" load-path))
    
;;; Default font
;;; This font is pretty good for emacs under windows
;;; (set-frame-font "-raster-Fixedsys-normal-r-normal-normal-15-112-96-96-c-*-iso10646-1")
    (set-frame-font "-*-lucidatypewriter-*-r-*-*-17-*-*-*-m-*-*-*")
    
;;; Automatic time stamping on file save  
    (add-hook 'write-file-hooks 'time-stamp)
    
;;; Text mode and Auto Fill mode
    (global-font-lock-mode t)
    (setq major-mode 'text-mode)
    (add-hook 'text-mode-hook 'turn-on-auto-fill)
    (add-hook 'c-mode-hook 'turn-on-font-lock)
    (add-hook 'c++-mode-hook 'turn-on-font-lock)
    (add-hook 'python-mode 'turn-on-font-lock)
    (add-hook 'makefile-mode-hook 'turn-on-font-lock)
    (setq font-lock-maximum-decoration t)

;;; TeX mode is AUCTeX
    (require 'tex-site)
    
;;; Auto spelling check for text and latex modes
    (defun turn-on-flyspell-mode ()
      (flyspell-mode 1)) 
    (add-hook 'LaTeX-mode-hook 'turn-on-flyspell-mode)
    (add-hook 'latex-mode-hook 'turn-on-flyspell-mode)
    (add-hook 'message-mode-hook 'turn-on-flyspell-mode)
    
;;; Load up a2ps stuff so we can print, but not on OS X.
;;; (load "a2ps-print")

;;; Mouse wheel stuff, which works only on Emacs >= 21
    (cond
     ((<= 21 emacs-major-version)
      (mouse-wheel-mode 1)
      (setq mouse-wheel-follow-mouse t)
      ))
 
;;; Prevent Extraneous Tabs
;;;
;;; I.e. turn off Indent Tabs mode, so Emacs will use spaces, not tabs when
;;; it formats a region. Note, that setq-default rather than the setq command
;;; is used, so values will be set only in buffers that do not have their own
;;; local values for the variable
    (setq-default indent-tabs-mode nil)
    
;;; All backup files go into our myemacs/backup
    (require 'backup-dir)
    (setq bkup-backup-directory-info
          '((t "~/myemacs/backups/" full-path prepend-name)))

;;; Load the Shell-Toggle script
    (autoload 'shell-toggle "shell-toggle" 
      "Toggles between the *shell* buffer and whatever buffer you are editing." t)
    (autoload 'shell-toggle-cd "shell-toggle" 
      "Pops up a shell-buffer and insert a \"cd <file-dir>\" command." t)
    (global-set-key [C-f1] 'shell-toggle-cd)

;;; C-Sharp mode.
    (autoload 'csharp-mode "csharp-mode" 
      "Major mode for editing C# code." t)
    (setq auto-mode-alist (cons '( "\\.cs\\'" . csharp-mode ) auto-mode-alist)) 

;;; Python mode
    (autoload 'python-mode "python-mode"
      "Python editing mode." t)

;;; Haskell mode.
    (load "haskell-mode/haskell-site-file")
    (add-hook 'haskell-mode-hook 'font-lock-mode)
    (add-hook 'haskell-mode-hook 'turn-on-haskell-doc-mode)
    (add-hook 'haskell-mode-hook 'turn-on-haskell-indent)

;;; Ruby mode
    (autoload 'ruby-mode "ruby-mode"
      "Ruby editing mode." t)
                                
;;; Keybinding to compare windows
;;;
;;; compare-windows is a nifty command that compares the text in your current
;;; window with the text in the next window. It makes the comparision by
;;; starting at point in each window, moving over text in each window as far
;;; as they match. As for the keybinding itself: C-c w. This set of keys,
;;; C-c followed by a single character, is strictly reserved for individuals'
;;; own use. 
    (global-set-key "\C-cw" 'compare-windows)
    
;;; Keybinding for 'occur'
;;;
;;; The occur command shows all the lines in the current buffer that contain
;;; a match for a regular expression. Matching lines are shown in a buffer
;;; called '*Occur*'. That buffer serves as a menu to jump to occurences.
    (global-set-key "\C-co" 'occur)
    
;;; Unbind C-x f
;;;
;;; I found I inadvertently typed C-x f when I meant to type C-x C-f. Rather
;;; than find a file, as I intended, I accidentally set the width for filled
;;; text. Since I hardly ever reset my default width, I simply unbound the key.
    (global-unset-key "\C-xf")
    
;;; Rebind C-x C-b for buffer-menu
;;;
;;; By default, C-x C-b runs the list-buffers command. This command lists your
;;; buffers in another window. Since I almost always want to do something in
;;; that window, I prefer the buffer-menu command, which not only lists the
;;; buffers, but moves point into that window.
    (global-set-key "\C-x\C-b" 'buffer-menu)
    
;;; Rebind C-x l to the goto-line
    (global-set-key "\C-xl" 'goto-line)
    
;;; A modified Mode Line
;;;
;;; Replace 'Emacs: '  with host name;
;;; list the current directory
;;; specify the line point is on, with 'Line' spelled out.
;;; I set the default mode line format so as to permit various modes, such as
;;; Info to override it. mode-line-modified is a variable that tells whether
;;; the buffer has been modified, mode-name tells the name of the mode. The
;;; "%14b" displays the current buffer name (using the buffer-name function.)
;;; When a name has fewer characters, whitespace is added to fill out to this
;;; number. '%[' and '%]' cause a pair of sqare brackets to appear for each
;;; recursive aditing level. '%n' says 'Narrow' when narrowing is in effect.
;;; '%P' tells you the the percentage of the buffer that is above the bottom
;;; of the window, or 'Top', 'Bottom', or 'All'. (A lower case 'p' tell you
;;; the percentage above the top of the window.) '%-' inserts enough dashes
;;; to fill out the line.
    (setq mode-line-system-identification
          (substring (system-name) 0
                     (string-match "\\..+" (system-name))))
    
    (setq mode-line-format
          (list ""
                'mode-line-modified
                "<"
                'mode-line-system-identification
                ">"
                "%14b"
                " "
                'default-directory
                " "
                "%[("
                'mode-name
                'minor-mode-alist
                "%n"
                'mode-line-process
                ")%]--"
                "(L:%l,C:%c)--"
                '(-3 . "%P")
                "-%-"))
    
;;; Start with new default
    (setq mode-line-format mode-line-format)
    
;;; What to edit files as
    (setq auto-mode-alist
          (append
           '(("\\.y$"  . c-mode)
             ("\\.l$"  . c-mode)
             ("\\.py$" . python-mode)
             ("Makefile"    . makefile-mode)
             ("Makefile\\." . makefile-mode)
             ("makefile"    . makefile-mode)
             ("makefile\\." . makefile-mode)
             ("lowmake"     . makefile-mode)
             ("hostmake"    . makefile-mode)
             ("submake"     . makefile-mode)
             ) auto-mode-alist))
    
    (setq interpreter-mode-alist
          (cons '("python" . python-mode)
                interpreter-mode-alist))

    (defun linux-c-mode ()
      "C mode with adjusted defaults for use with the Linux kernel."
      (interactive)
      (c-mode)
      (c-set-style "K&R")
      (setq tab-width 8)
      (setq indent-tabs-mode t)
      (setq c-basic-offset 8)
      (setq show-trailing-whitespace t))

      ;; Draw tabs with the same color as trailing whitespace  

      (add-hook 'font-lock-mode-hook  
                (lambda ()  
                  (font-lock-add-keywords  
                   nil  
                   '(("\t" 0 'trailing-whitespace prepend)))))

;;; Of course there are lots of other indentation features that I
;;; haven't touched on here.  Until the texinfo is complete, you're
;;; going to have to explore these on your own.  Here's a sample .emacs
;;; file that might help you along the way.  Just hit "C-x C-p", then
;;; "ESC w" to copy this region, then paste it into your .emacs file
;;; with "C-y".  You may want to change some of the actual values.
    (setq c-basic-offset 2)
    
;;; header auto-inserts
    (add-hook 'find-file-hooks 'auto-insert)
    (load-library "autoinsert")
    (setq auto-insert-directory "~/myemacs/inserts/")
    (setq auto-insert-alist
          (append '( (asm-mode          . "insert.s")
                     ("\\.h\\'"         . "insert.h")
                     ("[Mm]akefile\\'"  . "insert.make")
                     (sh-mode           . "insert.sh")
                     (c-mode            . "insert.c")
                     (c++-mode          . "insert.cpp")
                     (text-mode         . "insert.txt")
                     (latex-mode        . "insert.latex")
                     (python-mode       . "insert.py")
                     )
                  auto-insert-alist
                  ))
    
;;; Emacs faces
    (set-face-background 'default "black")
    (set-face-foreground 'default "linen")
    
    (set-face-background 'cursor "red")
    (set-face-background 'mouse "red")
    (set-face-foreground 'mouse "yellow")
    
    (set-face-background 'border "black")
    (set-face-foreground 'border "yellow")
    
    (set-face-foreground 'font-lock-builtin-face  "DeepSkyBlue")
    (set-face-foreground 'font-lock-comment-face  "salmon1")
    (set-face-foreground 'font-lock-constant-face "green")
    (set-face-foreground 'font-lock-doc-face "violet")
    (set-face-foreground 'font-lock-function-name-face "deep pink")
    (set-face-foreground 'font-lock-keyword-face "gray75")
    (set-face-foreground 'font-lock-string-face "pale green")
    (set-face-background 'font-lock-string-face "gray20")
    (set-face-foreground 'font-lock-type-face "gray75")
    (set-face-foreground 'font-lock-variable-name-face "orange")
    (set-face-foreground 'font-lock-warning-face "gold")
    (set-face-background 'font-lock-warning-face "sienna")
    
    (make-face 'show-paren-match-face)
    (make-face 'show-paren-mismatch-face)
    (set-face-background 'show-paren-match-face "blue")
    (set-face-foreground 'show-paren-match-face "white")
    (set-face-background 'show-paren-mismatch-face "magenta")
    (set-face-foreground 'show-paren-mismatch-face "yellow")

    (set-face-background 'region "gold4")
    (set-face-foreground 'region "white")
    
    (set-face-background 'tool-bar "gray50")
    (set-face-background 'modeline "firebrick4")
    (set-face-foreground 'modeline "wheat")
    (make-face-bold 'modeline)
    
    (set-face-foreground 'highlight "black")
    (set-face-background 'highlight "gold3")
    (make-face-bold 'highlight)
    
    (make-face 'info-node)
    (make-face 'info-xref)
    
    (set-face-foreground 'info-node "green")
    (set-face-foreground 'info-xref "green")
    (make-face-unitalic 'info-node)
        
;;; Turn on highlight for search strings:
    (setq search-highlight t)
    
;;; Set every frame to show a menu bar and to come forward when you
;;; move the mouse onto it:
    (setq default-frame-alist
          '((menu-bar-lines . 1)
            (auto-lower . t)
            (auto-raise . t)))
    
    (custom-set-variables
     '(inhibit-startup-screen t)
     '(case-fold-search t)
     '(show-paren-mode t nil (paren))
     
;;; Do not show crappy windowy shit like menus and toolbars
     '(tool-bar-mode nil nil (tool-bar))
     '(menu-bar-mode nil nil (menu-bar))
     '(scroll-bar-mode nil nil (scroll-bar))
     '(current-language-environment "Latin-1"))

;;; This ends the compile-the-.emacs
))
