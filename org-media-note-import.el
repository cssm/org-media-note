;;; package --- org-media-note-import.el -*- lexical-binding: t; -*-


;;; Commentary:
;;

(require 'org-media-note-core)


;;; Code:

;;;; import from pbf (potplayer bookmark):
(defun org-media-note-insert-note-from-pbf ()
  "Insert note from PBF file."
  (interactive)
  (let ((key (org-media-note--current-org-ref-key))
        pbf-file
        media-link-type
        media-file)
    (if (org-media-note-ref-cite-p)
        (progn
          (setq source-media (org-media-note-get-media-file-by-key key))
          (setq media-link-type (format "%scite"
                                        (org-media-note--file-media-type source-media)))
          (setq media-file key)
          (setq pbf-file (concat (file-name-sans-extension source-media)
                                 ".pbf")))
      (progn
        ;; TODO need more test
        (setq media-file (read-file-name "Find media file:"))
        (setq media-link-type (org-media-note--file-media-type media-file))
        (setq pbf-file (concat (file-name-sans-extension media-file)
                               ".pbf"))))
    (message pbf-file)
    (if (not (file-exists-p pbf-file))
        (setq pbf-file (read-file-name "Find pbf file:")))
    (insert (org-media-note--convert-from-pbf pbf-file
                                              media-link-type media-file))
    (if (y-or-n-p "Delete the PBF File? ")
        (delete-file pbf-file))))

(defun org-media-note--convert-from-pbf (pbf-file media-link-type media-file)
  "Return link for MEDIA-FILE of MEDIA-LINK-TYPE from PBF-FILE."
  (with-temp-buffer
    (insert-file-contents pbf-file)
    (replace-string "[Bookmark]\n"
                    ""
                    nil
                    (point-min)
                    (point-max))
    (replace-regexp "^[[:digit:]]+=$"
                    ""
                    nil
                    (point-min)
                    (point-max))
    (goto-char (point-min))
    (while (re-search-forward "^[[:digit:]]+=\\([[:digit:]]+\\)\\*\\([^\\*]+\\)\\*.+"
                              nil t)
      (let* ((millisecs (buffer-substring (match-beginning 1)
                                          (match-end 1)))
             (note (buffer-substring (match-beginning 2)
                                     (match-end 2)))
             (beg (match-beginning 0))
             (end (match-end 0))
             (hms (org-media-note--millisecs-to-timestamp millisecs))
             (new-text (format "- [[%s:%s#%s][%s]] %s" media-link-type
                               media-file hms hms note)))
        (goto-char beg)
        (delete-region beg end)
        (insert new-text)))
    (buffer-string)))

;;;; import from srt:
(defun org-media-note-insert-note-from-srt ()
  "Insert note from SRT file."
  (interactive)
  (let ((key (org-media-note--current-org-ref-key))
        (timestamp-format (ido-completing-read "Select timestamp format: " '("time1" "time1-time2")))
        srt-file
        media-link-type
        media-file)
    (if (org-media-note-ref-cite-p)
        (progn
          (setq source-media (org-media-note-get-media-file-by-key key))
          (setq media-link-type (format "%scite"
                                        (org-media-note--file-media-type source-media)))
          (setq media-file key)
          (setq srt-file (concat (file-name-sans-extension source-media)
                                 ".srt")))
      (progn
        ;; TODO need more test
        (setq media-file (read-file-name "Find media file:"))
        (setq media-link-type (org-media-note--file-media-type media-file))
        (setq srt-file (concat (file-name-sans-extension media-file)
                               ".srt"))))
    (message srt-file)
    (if (not (file-exists-p srt-file))
        (setq srt-file (read-file-name "Find srt file:")))
    (insert (org-media-note--convert-from-srt srt-file timestamp-format
                                              media-link-type media-file))
    (if (y-or-n-p "Delete the SRT File? ")
        (delete-file srt-file))))

(defun org-media-note--convert-from-srt (srt-file timestamp-format media-link-type media-file)
  "Return link for MEDIA-FILE of MEDIA-LINK-TYPE from SRT-FILE."
  (with-temp-buffer
    (insert-file-contents srt-file)
    (goto-char (point-min))
    (while (re-search-forward (concat "[[:digit:]]+\n" org-media-note--hmsf-timestamp-pattern "--> " org-media-note--hmsf-timestamp-pattern "\n\\(.+\\)\n")  nil t)
      (let* ((time-a (buffer-substring (match-beginning 1)
                                          (match-end 1)))
             (time-b (buffer-substring (match-beginning 3)
                                     (match-end 3)))
             (note (buffer-substring (match-beginning 5)
                                     (match-end 5)))
             (beg (match-beginning 0))
             (end (match-end 0))
             timestamp
             new-text)
        (cond
          ((eq org-media-note-timestamp-pattern 'hms)
           (setq time-a (car (split-string time-a ",")))
           (setq time-b (car (split-string time-b ",")))
           )
          ((eq org-media-note-timestamp-pattern 'hmsf)
           (setq time-a (s-replace-regexp "," "." time-a))
           (setq time-b (s-replace-regexp "," "." time-b))
           ))
        (cond
         ((string= timestamp-format "time1")
          (setq timestamp time-a))
         ((string= timestamp-format "time1-time2")
          (setq timestamp (format "%s-%s" time-a time-b))))
        (setq new-text (format "- [[%s:%s#%s][%s]] %s" media-link-type media-file timestamp timestamp note))
        (goto-char beg)
        (delete-region beg end)
        (insert new-text)))
    (buffer-string)))

;;;; import from noted:
(defun org-media-note-insert-note-from-noted ()
  "Insert note from noted txt."
  (interactive)
  (let ((key (org-media-note--current-org-ref-key))
        noted-txt
        media-link-type
        media-file)
    (setq noted-txt (read-file-name "Find exported Noted txt:"))
    (if (org-media-note-ref-cite-p)
        (progn
          (setq media-file key)
          (setq media-link-type (concat (org-media-note--file-media-type (org-media-note-get-media-file-by-key key))
                                        "cite")))
      (progn
        ;; TODO  need more test
        (setq media-file (read-file-name "Find media file:"))
        (setq media-link-type (org-media-note--file-media-type media-file))))
    (insert (org-media-note--convert-from-noted noted-txt
                                                media-link-type media-file))
    (if (y-or-n-p "Delete Noted txt? ")
        (delete-file noted-txt))))

(defun org-media-note--convert-from-noted (noted-file media-link-type media-file)
  "Return converted link for MEDIA-FILE of MEDIA-LINK-TYPE from NOTED-FILE."
  (with-temp-buffer
    (insert-file-contents noted-file)
    (replace-string "￼"
                    ""
                    nil
                    (point-min)
                    (point-max))
    ;; replace unordered list
    (replace-regexp "[•◦▫]"
                    "-"
                    nil
                    (point-min)
                    (point-max))
    (goto-char (point-min))
    (while (re-search-forward "^\\[\\([:0-9]+\\)\\]\\([[:blank:]]+\\)-[[:blank:]]+"
                              nil t)
      (let* ((hms (buffer-substring (match-beginning 1)
                                    (match-end 1)))
             (blank-indent (buffer-substring (match-beginning 2)
                                             (match-end 2))))
        (replace-match (concat blank-indent "- [[" media-link-type
                               ":" media-file "#" hms "][" hms "]] ")
                       t)))
    ;; replace ordered list

    (goto-char (point-min))
    (while (re-search-forward "^\\[\\([:0-9]+\\)\\]\\([[:blank:]]+\\)\\([[:digit:]]\\. \\)"
                              nil t)
      (let* ((hms (buffer-substring (match-beginning 1)
                                    (match-end 1)))
             (blank-indent (buffer-substring (match-beginning 2)
                                             (match-end 2)))
             (number-bullet (buffer-substring (match-beginning 3)
                                              (match-end 3))))
        (replace-match (concat blank-indent number-bullet "[[" media-link-type
                               ":" media-file "#" hms "][" hms "]] ")
                       t)))
    ;; replace timestamped text

    (goto-char (point-min))
    (while (re-search-forward "^\\[\\([:0-9]+\\)\\]\\([[:blank:]]+\\)"
                              nil t)
      (let* ((hms (buffer-substring (match-beginning 1)
                                    (match-end 1)))
             (blank-indent (buffer-substring (match-beginning 2)
                                             (match-end 2))))
        (replace-match (concat blank-indent "- [[" media-link-type
                               ":" media-file "#" hms "][" hms "]] ")
                       t)))
    ;; format

    (replace-regexp "\\]\\] +"
                    "]] "
                    nil
                    (point-min)
                    (point-max))
    (buffer-string)))

;;;; import org-timer:
(defun org-media-note-convert-from-org-timer ()
  "Convert `org-timer' to media link."
  (interactive)
  (let* ((key (org-media-note--current-org-ref-key))
         (source-media (org-media-note-get-media-file-by-key key))
         (media-file source-media)
         (media-link-type (org-media-note--file-media-type source-media)))
    (if (org-media-note-ref-cite-p)
        (progn
          (setq media-file key)
          (setq media-link-type (format "%scite" media-link-type))))
    (save-excursion
      (org-narrow-to-subtree)
      (goto-char (point-min))
      (while (re-search-forward (concat org-media-note--hms-timestamp-pattern "::[ \t]+")
                                nil t)
        (let* ((hms (buffer-substring (match-beginning 1)
                                      (match-end 1))))
          (replace-match (format "[[%s:%s#%s][%s]] " media-link-type
                                 media-file hms hms)
                         'fixedcase)))
      (widen))))

;;;; Footer
(provide 'org-media-note-import)

;;; org-media-note-import.el ends here
