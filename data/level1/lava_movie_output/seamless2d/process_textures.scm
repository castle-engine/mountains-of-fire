;; Simple GIMP scripts to process all textures to seamless.
;;
;; ---------------------------------------------------------------------------
;;   Copyright 2014 Michalis Kamburelis.
;;   Based on my own script in "The Castle".
;;
;;   This file is part of "Mountains Of Fire".
;;
;;   "Mountains Of Fire" is free software; you can redistribute it and/or modify
;;   it under the terms of the GNU General Public License as published by
;;   the Free Software Foundation; either version 2 of the License, or
;;   (at your option) any later version.
;;
;;   "Mountains Of Fire" is distributed in the hope that it will be useful,
;;   but WITHOUT ANY WARRANTY; without even the implied warranty of
;;   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;;   GNU General Public License for more details.
;;
;;   You should have received a copy of the GNU General Public License
;;   along with "Mountains Of Fire"; if not, write to the Free Software
;;   Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
;;

;;;; Filename functions ------------------------------------------------------

;; Removes extension part of the FILENAME (".ext" part).
(define (kam-file-name-delete-ext filename)

  ;; * I swear I'm going to stab in the face next guy that tries to persuade
  ;;   me that Lisp syntax is readable. *
  ;;
  ;; This cludge below means (in normal, human-readable language:)
  ;;
  ;; for i := length(filename) - 1 downto 0 do
  ;;   if filename[i] = '.' then
  ;;     Break;

  (let* ((len (string-length filename))
         (i (- len 1)))
     (while (and (>= i 0)
                 (not (char=? (string-ref filename i) #\.)))
       (set! i (- i 1)))

    ;; We're here, so i < 0 (no '.' in filename) or filename[i] = '.'
    (if (< i 0)
        filename
      (substring filename 0 i)))
)

;; Replaces extension part of the FILENAME (".ext" part) with NEW-EXTENSION.
;; In the usual case, you want to include trailing dot in NEW-EXTENSION.
;; If filename has no extension part, just adds NEW-EXTENSION to it.
(define (kam-file-name-change-ext filename new-extension)
  (string-append (kam-file-name-delete-ext filename) new-extension))

;; Assuming FILENAME is a nice file name, inserts another subdirectory name
;; at the end of it's path. (Note: assumes path delimiter is '/',
;; i.e. Unix-like; I don't know how GIMP filenames behave on Windows).
(define (kam-file-name-insert-subdir filename subdir)
  (let* ((len (string-length filename))
         (i (- len 1)))
     (while (and (>= i 0)
                 (not (char=? (string-ref filename i) #\/)))
       (set! i (- i 1)))

    ;; We're here, so i < 0 (no '/' in filename) or filename[i] = '.'
    (if (< i 0)
        (string-append subdir "/" filename)
      (string-append (substring filename 0 i)
                     "/" subdir
                     (substring filename i len))))
)

;;;; seamless2d generation -----------------------------------------------------

(define (kam-seamless2d input-filename)
  (let* ((output-filename
          ;; Place output in seamless_2d subdir, and always in PNG format.
          (kam-file-name-change-ext
            (kam-file-name-insert-subdir input-filename "seamless2d") ".png"))

         (image (car (gimp-file-load RUN-NONINTERACTIVE
                                         input-filename input-filename)))
         (drawable (car (gimp-image-get-active-layer image))))

    ;; tests:
    (gimp-message (string-append input-filename " goes to " output-filename))

    (plug-in-make-seamless RUN-NONINTERACTIVE image drawable)

    (gimp-file-save RUN-NONINTERACTIVE
      image drawable output-filename output-filename)
    (gimp-image-delete image))
)

(define (kam-batch-seamless2d)

  (let* ((filelist (cadr (file-glob "../*.png" 1))))
    (while (not (null? filelist))
       (let* ((filename (car filelist)))
         (kam-seamless2d filename)
         (set! filelist (cdr filelist)))))
)
