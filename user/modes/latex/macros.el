(setq TeX-auto-save t)
(setq TeX-parse-self t)
(setq TeX-save-query nil)
;; (setq TeX-PDF-mode t)

(eval-after-load 'latex 
  `(progn
     (define-key TeX-mode-map ,(kbd "C-c p")
       ,(lambda nil (interactive)
          (progn
            (TeX-save-document (TeX-master-file))
            (TeX-command "LaTeX" (quote TeX-master-file) -1)
            )
          )
       )
     (define-key TeX-mode-map ,(kbd "C-c v")
        ,(lambda nil (interactive)
           (TeX-command "View" (quote TeX-master-file) -1)
           )
        )
     (define-key TeX-mode-map ,(kbd "C-c f")
       ,(lambda nil (interactive)
          (let (
                (caption (read-string "Caption "))
                (address (read-string "Address "))
                (width (read-string "Width "))
                )
            (insert "\\begin{figure}[H]\n")
            (insert "  \\caption{" caption "}\n")
            (insert "  \\vspace{0.2cm}\n")
            (insert "  \\centerline{\\includegraphics[width=" width "]{" address "}}\n")
            (insert "\\end{figure}\n")
            )
          )
       )
     )
  )
 
