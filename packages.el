;;; packages.el --- saburto-java layer packages file for Spacemacs.
;;
;; Copyright (c) 2012-2022 Sylvain Benner & Contributors
;;
;; Author: Sebastian Aburto <saburto@saburto-XPS-13-9310>
;; URL: https://github.com/syl20bnr/spacemacs
;;
;; This file is not part of GNU Emacs.
;;
;; This program is free software; you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or
;; (at your option) any later version.
;;
;; This program is distributed in the hope that it will be useful,
;; but WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
;; GNU General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with this program.  If not, see <http://www.gnu.org/licenses/>.

;;; Commentary:

;; See the Spacemacs documentation and FAQs for instructions on how to implement
;; a new layer:
;;
;;   SPC h SPC layers RET
;;
;;
;; Briefly, each package to be installed or configured by this layer should be
;; added to `saburto-java-packages'. Then, for each package PACKAGE:
;;
;; - If PACKAGE is not referenced by any other Spacemacs layer, define a
;;   function `saburto-java/init-PACKAGE' to load and initialize the package.

;; - Otherwise, PACKAGE is already referenced by another Spacemacs layer, so
;;   define the functions `saburto-java/pre-init-PACKAGE' and/or
;;   `saburto-java/post-init-PACKAGE' to customize the package as it is loaded.

;;; Code:

(defconst saburto-java-packages
  '((java-ts-mode :location built-in)
    (lsp-java :requires lsp-mode)))

(defun saburto-java/init-java-ts-mode ()
  (use-package java-ts-mode
    :defer t
    :mode (("\\.java\\'" . java-ts-mode))
    :hook ((java-ts-mode . (lambda () (setq c-basic-offset 4 tab-width 4))))))

(defun saburto-java/init-lsp-java()

  (use-package lsp-java
    :init
    (setq lsp-java-jdt-download-url "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz")
    (setq lsp-java-vmargs '("-noverify" "-Xmx4G"  "-XX:+UseG1GC" "-XX:+UseStringDeduplication" "-javaagent:/home/saburto/.m2/repository/org/projectlombok/lombok/1.18.24/lombok-1.18.24.jar" ))
    :hook ((java-ts-mode . lsp-deferred))))
