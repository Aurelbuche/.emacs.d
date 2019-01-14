;; =================================================================================
;; @project Autodoc
;; 
;; @acronym AUTODOC
;; 
;; @summary Emacs Lisp tool to generate documentation automatically
;; 
;; @abstract autodoc is an open source documentation generator using emacs-lisp to generate a .tex documentation file and can print it as a .pdf file using pdftex. autodoc is fully configurable and can be used with many languages and many templates.
;; 
;; @date 30 August 2018
;; 
;; @authors A. Buchet
;; 
;; @contact au.buchet@gmail.com
;; =================================================================================

;; =================================================================================
;; @file autodoc.el
;; 
;; @doc This File contains all the functions and scripts in order to generate the latex template and the pdf from a file
;; =================================================================================

;; ------------------------------------------------------------
;; @fun read-lines
;; 
;; @doc Return a list of lines of the file described by filePath
;; 
;; @arg filePath
;; @@type string
;; @@doc String containing the path of the file
;; 
;; @out 
;; @@type list 
;; ------------------------------------------------------------
(defun read-lines (filePath)
  ;; copied the 6 september 2018
  ;; from http://ergoemacs.org/emacs/elisp_read_file_content.html
  "Return a list of lines of a file at filePath."
  (with-temp-buffer
    (insert-file-contents filePath)
    (split-string (buffer-string) "\n" t)))

;; ------------------------------------------------------------
;; @fun commentp
;; 
;; @doc Return t if object is a string describing a comment
;; 
;; @arg object
;; @@type any
;; @@doc Object to check
;; 
;; @out
;; @@type boolean
;; ------------------------------------------------------------
;; Need to change this function so it can be used with any language
(defun commentp (object)
  (and (stringp object) (equal (substring object 0 1) ";")))

;; =================================================================================
;; Functions to manipulate plists
;; =================================================================================

(defun plist-val (
    plist ;property list ;property list from which the property defined by args will be extracted if it exists
    &rest args ;symbol list ;can contain an unlimited number of symbols describing a property to extract in property list hierarchy
  )
  "Allows the use of plist-get with multiple arguments"
  (let ((plist plist))
    (while args
      (setq plist (plist-get plist (pop args)))
    )
    plist))

;; #example
;; (setq plist (list 'name "property list" 'properties '(a "prop a" b "prop b")))
;; (plist-val plist 'name)
;; => "property list"
;; (plist-val plist 'properties)
;; => (a "prop a" b "prop b")
;; (plist-val plist 'properties 'a)
;; => "prop a"
;; #

(defmacro check-string (symbol)
  "Checks if symbol is bound to a string and if it's not associates "" to the symbol"
  `(if (and (boundp ',symbol) ,symbol (stringp ,symbol))
    ,symbol (setq ,symbol "")))

(defun functionToTexString (function)
  "Takes a plist describing a function in argument and return the minted latex code to print it properly"
  (let ((name    (plist-get function 'name))
      (arguments (plist-get function 'arguments)) args
      (doc       (plist-get function 'doc))
      (outputs   (plist-get function 'outputs)) outs
    )
    ;; checking if function uses arguments or nil
    (if arguments
      ;; function has arguments
      (setq args
        ;; concatening arguments name with spaces between them
        (mapconcat '(lambda (argument) (plist-get argument 'name))
          arguments " "))
      ;; function has no arguments
      (setq args "nil"))
    ;; checking if function has outputs
    (if outputs
      ;; function has outputs
      (setq outs
        ;; concatening arguments name with spaces between them
        (mapconcat' (lambda (output) (plist-get output 'name))
          outputs " "))
      ;; function has no outputs
      (setq outs "nil"))
    ;; creating the latex string to insert
    (concat
      "\\nonumsubsubsection{" name "}\n"
      doc "\n"
      "\\begin{minted}{emacs-lisp}\n"
      "(defun " name " (" args ") ... )\n"
      "=> " outs "\n"
      "\\end{minted}\n\n")
    ;(concat "\\function{" name "}{" args "}{" outs "}{" doc "}\n")
  );let
);defun

;(functionToTexString function)

(defun fileToTexString (file)
  "Takes a plist describing a file in argument and returns the corresponding latex code ready to be inserted in a documentation file"
  (let ((name     (plist-get file 'name))
       (functions (plist-get file 'functions))
       (doc       (plist-get file 'doc))
       (res ""))
     ;; creating the latex string to insert
     (setq res (concat res "\\file{" name "}{" doc "}\n\n"))
     ;; printing each function
     (dolist (function functions)
       (setq res (concat res (functionToTexString function))))
     (concat res "\\newpage\n\n")
  );let
);defun

;(fileToTexString file)

(defun filesToTexString (files)
  (let ((res ""))
    (dolist (file files)
      (setq res (concat res (fileToTexString file))))
    res
  );let
);defun

(defun generateTemplate (directory file plist)
  "Generates a file.tex in directory using the property list"
  (let
    ;; fetching project parameters
    (buffer
      ;; strings
      (project       (plist-val plist 'project 'name))
      (date          (plist-val plist 'project 'date))
      (logo          (plist-val plist 'project 'logo)) titlepagelogo 
      (summary       (plist-val plist 'project 'summary))
      (authors       (plist-val plist 'project 'authors))
      (contact       (plist-val plist 'project 'contact))
      (abstract      (plist-val plist 'project 'abstract))
      (readme        (plist-val plist 'project 'readme))
      (prerequisites (plist-val plist 'project 'prerequisites))
      (installation  (plist-val plist 'project 'installation))
      ;; files
      (files         (plist-val plist 'project 'files))
    )
    ;; checking entries
    ;; project, date, logo, summary, authors, contact, abstract
    (dolist (symbol '(project date logo summary authors contact abstract readme prerequisites installation))
      (eval `(check-string ,symbol)))
    (when (equal project "") (warn "project name is empty"))
    ;; logo (also checks if logo file exists and is readable)
    (when (file-readable-p logo)
      (setq titlepagelogo (concat "\\includegraphics[height=8cm]{" logo "}"))
      (setq logo (concat "\\includegraphics[height=2cm]{" logo "}")))
    ;; opening tex file and erasing it
    (when (setq buffer (find-file (concat directory "/" file ".tex")))
      (erase-buffer)
      ;; inserting tex code
      (insert 
        ;; setup packages
        "\\documentclass[a4paper, 11pt]{article}\n"
        "\\usepackage[utf8]{inputenc}\n"
        "\\usepackage[english]{babel}\n"
        "\\usepackage[labelformat=empty]{caption}\n"
        "\\usepackage{geometry}\n"
        "\\usepackage{graphicx}\n"
        "\\usepackage{float}\n"
        "\\usepackage{fancyhdr}\n"
        "\\usepackage{lastpage}\n"
        "\\usepackage{titlesec}\n"
        "\\usepackage{hyperref}\n"
        "\\usepackage{minted}\n\n"
        ;; hypersetup
        "\\hypersetup{\n"
        " colorlinks=true, urlcolor=black, linkcolor=black,\n"
        " breaklinks=true, %permet le retour à la ligne dans les liens trop longs\n"
        " bookmarksopen=false, %si les signets Acrobat sont créés,\n"
        " % les afficher complètement.\n"
        " pdftitle={" project "}, %informations apparaissant dans\n"
        " pdfauthor={Autodoc generated document}, %les informations du document\n"
        " pdfsubject={Documentation} %sous Acrobat.\n"
        "}\n\n"
        ;; section, subsection and subsubsection spacing
        "\\titlespacing\\section{0mm}{8mm}{0mm}"
        "\\titlespacing\\subsection{4mm}{-8mm}{0mm}"
        "\\titlespacing\\subsubsection{8mm}{-12mm}{0mm}"
        ;; geometry, headers and footers setup
        "\\geometry{hmargin=15mm,vmargin=25mm}\n"
        "\\setlength{\\topmargin}{-30pt}\n"
        "\\setlength{\\parindent}{0em}\n"
        "\\setlength{\\parskip}{5mm}\n"
        "\\pagestyle{fancy}\n"
        "\\renewcommand{\\headrulewidth}{1pt}\n"
        "\\lhead{" project "}\n"
        "\\chead{" date "} \n"
        "\\rhead{" logo "}\n"
        "\\renewcommand{\\footrulewidth}{1pt}\n"
        "\\lfoot{\\leftmark}\n"
        "\\cfoot{}\n"
        "\\rfoot{\\thepage\\ / \\pageref{LastPage}}\n\n"
        ;; creating sections without numbers
        "\\newcommand{\\nonumsection}[1]{\n"
        "\\newpage\\paragraph{}"
        "\\phantomsection\n"
        "\\addcontentsline{toc}{section}{#1}\n"
        "\\markboth{\\uppercase{#1}}{}\n"
        "\\section*{#1}}\n\n"
        ;; creating subsections without numbers
        "\\newcommand{\\nonumsubsection}[1]{\n"
        "\\paragraph{}"
        "\\phantomsubsection\n"
        "\\addcontentsline{toc}{subsection}{#1}\n"
        "\\subsection*{#1}}\n\n"
        ;; creating subsubsections without numbers
        "\\newcommand{\\nonumsubsubsection}[1]{\n"
        "\\paragraph{}"
        "\\phantomsubsubsection\n"
        "\\addcontentsline{toc}{subsubsection}{#1}\n"
        "\\subsubsection*{#1}}\n\n"
        ;; creating \file
        "\\newcommand{\\file}[2]{\n"
        "\\nonumsubsection{#1}"
        "#2}\n\n"
        ;; beginning of document
        "\\begin{document}\n"
        ;; inserting titlepage
        "\\begin{titlepage}\n"
        "\\begin{center}\n"
        titlepagelogo "\\\\[1cm]\n"
        "{\\huge \\bfseries " project "}\\\\[8mm]\n"
        "{\\large " date "}\\\\[16mm]\n"
        "\\begin{flushleft} \\large " summary " \\end{flushleft}\\\\[-5mm]\n"
        "\\rule{\\linewidth}{1pt}\\\\[5mm]\n"
        "\\begin{flushright} \\Large\n"
        authors "\\\\[3mm]\n\\large " contact 
        "\\end{flushright}\\\\[2cm]\n"
        "\\end{center}\n"
        abstract "\n"
        "\\vfill\n"
        "\\end{titlepage}\n\n"
        ;; table of contents (paragraph to place contents title properly)
        "\\newpage\\paragraph{}\\tableofcontents\\phantomsection\n"
        "\\markboth{CONTENTS}{}\\newpage\n\n"
        ;; printing readme, prerequisites and installation when they exist
        (if (equal readme "") "" (concat
            "\\nonumsection{Readme}\n" readme "\n\n"))
        (if (equal prerequisites "") ""
          (concat "\\nonumsection{Prerequisites}\n" prerequisites "\n\n"))
        (if (equal installation "") "" 
          (concat "\\nonumsection{Installation}\n" installation "\n\n"))
        (if (not files) ""
          (concat "\\nonumsection{Files}\n" (filesToTexString files) "\n"))
        ;; end of document
        "\\end{document}\n")
      ;; saving buffer and killing it
      (save-buffer buffer)
      (kill-buffer buffer)
    );when
  );let
);defun

(defun generatePDF (directory file plist)
  "Generates a pdf in directory using the property list"
  ;; generating .tex template
  (generateTemplate directory file plist)
  ;; generating PDF
  (let ((command (format
          "CURRENTDIR=\"$(pwd)\" && cd %s ; pdflatex -interaction nonstopmode -shell-escape %s.tex ; pdflatex -interaction nonstopmode -shell-escape %s.tex ; rm %s.aux %s.log %s.out %s.toc %s.pyg ; cd $CURRENTDIR"
          directory file file file file file file file)))
  (shell-command command)
  command))

;(generatePDF "/home/aurelien/git/.emacs.d.git/trunk/user/tools/autodoc" "test" DPL)

(defun printPDF (directory file)
  "Print the pdf file using a shell command"
  ;; Move to directory, print PDF using pdflatex 2 times for references then removes generated files and comes back to initial directory
  (let ((command
         (format
          "CURRENTDIR=\"$(pwd)\" && cd %s && pdflatex -interaction nonstopmode -shell-escape %s && pdflatex -interaction nonstopmode -shell-escape %s ; cd $CURRENTDIR"
          directory
          (concat file ".tex") (concat file ".tex")
          file file file file)))
    (shell-command command)
    command))









































