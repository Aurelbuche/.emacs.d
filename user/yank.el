;; =============================================================================================================
;; Using C-mouse to select and paste secondary selection at point
;; 
;; Author: Aurélien Buchet
;; =============================================================================================================

;; Using C-M-y to yank
(global-set-key (kbd "C-M-y") 'yank)

;; Using C-insert to yank
(global-set-key (kbd "<C-insert>") 'yank)

;; Using S-insert to yank primary
(global-set-key (kbd "<S-insert>")
                (lambda nil (interactive) (push-mark) (insert-for-yank (gui-get-primary-selection))))

;; Using secondary selection with ctrl and yank at point with crl-mouse 2 or 3
(global-set-key (kbd "<S-down-mouse-1>") 'mouse-buffer-menu)
(global-set-key (kbd "<C-down-mouse-1>") 'mouse-drag-secondary)
(global-set-key (kbd "<C-drag-mouse-1>") 'mouse-set-secondary)

(global-set-key (kbd "<C-mouse-2>") 'mouse-yank-secondary-at-point)
(global-set-key (kbd "<C-mouse-3>") 'mouse-yank-secondary-at-point)
(global-set-key (kbd "<C-down-mouse-3>") nil)

(setq-default mouse-yank-at-point nil)

(require 'cl)
(lexical-let (secondary)
  (defun mouse-yank-secondary-at-point (click)
    "Insert the secondary selection at point.
Move point to the end of the inserted text."
    (interactive "e")
    ;; Give temporary modes such as isearch a chance to turn off.
    (run-hooks 'mouse-leave-buffer-hook)
    (let ((selection (gui-get-selection 'SECONDARY)))
      (if (equal "" selection) (setq selection nil)
        (setq secondary (or selection secondary))))
    (if (not secondary) (error "No secondary selection"))
    ;; Yank secondary selection
    (insert-for-yank secondary)
    ;; Remove secondary selection
    (mouse-set-secondary nil)
    ))

(defun mouse-yank-secondary (click)
  "Insert the secondary selection at the position clicked on.
Move point to the end of the inserted text.
If `mouse-yank-at-point' is non-nil, insert at point
regardless of where you click."
  (interactive "e")
  ;; Give temporary modes such as isearch a chance to turn off.
  (run-hooks 'mouse-leave-buffer-hook)
  (or mouse-yank-at-point (mouse-set-point click))
  (let ((secondary (gui-get-selection 'SECONDARY)))
    (if secondary
        (insert-for-yank secondary)
      (error "No secondary selection"))))



