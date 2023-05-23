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
    (lsp-java :requires (lsp-mode dap-mode))
    (java-snippets
      :requires yasnippet
      :location (recipe :fetcher github
                        :files ("*.el" "snippets")
                                     :repo "saburto/yasnippet-java-mode"))
    mvn
    maven-test-mode
    smartparens
    flycheck
    ))

(defun saburto-java/post-init-flycheck ())))

(defun saburto-java/post-init-smartparens ()
  (with-eval-after-load 'smartparens
    (sp-local-pair 'java-ts-mode "/** " " */" :trigger "/**")))

(defun saburto-java/init-mvn ()
  (use-package mvn
    :defer t
    :init
    (when (configuration-layer/package-used-p 'java-ts-mode)
      (add-hook 'java-ts-mode-hook 'maven-test-mode)
      (spacemacs/declare-prefix-for-mode 'java-ts-mode "mm" "maven")
      (spacemacs/set-leader-keys-for-major-mode 'java-ts-mode
        "mm"    'mvn
        "ml"    'mvn-last
        "mc"    'mvn-compile
        "mC"   'mvn-clean))
    ))

(defun saburto-java/init-maven-test-mode ()
  (use-package maven-test-mode
    :defer t
    :init
    (when (configuration-layer/package-used-p 'java-ts-mode)
      (add-hook 'java-ts-mode-hook 'maven-test-mode)
      (spacemacs/declare-prefix-for-mode 'java-ts-mode "mtg" "goto to tests")
      (spacemacs/declare-prefix-for-mode 'java-ts-mode "mmt" "maven tests"))
    :config
    (progn
      (spacemacs|hide-lighter maven-test-mode)
      (spacemacs/set-leader-keys-for-minor-mode 'maven-test-mode
        "tga"    'maven-test-toggle-between-test-and-class
        "tgA"    'maven-test-toggle-between-test-and-class-other-window
        "mta"    'maven-test-all
        "mt C-a" 'maven-test-clean-test-all
        "mtb"    'maven-test-file
        "mti"    'maven-test-install
        "mtt"    'maven-test-method))))

(defun saburto-java/init-java-ts-mode ()
  (use-package java-ts-mode
    :defer t
    :mode (("\\.java\\'" . java-ts-mode))
    :init (add-hook 'java-ts-mode-local-vars-hook #'saburto-java--java-setup-lsp)
    :hook ((java-ts-mode . (lambda () (setq c-basic-offset 4 tab-width 4))))))

(defun saburto-java/init-lsp-java ()

  (use-package lsp-java
    :init
    (setq lsp-java-jdt-download-url "https://download.eclipse.org/jdtls/snapshots/jdt-language-server-latest.tar.gz")
    (setq lsp-java-vmargs '("-noverify" "-Xmx4G"  "-XX:+UseG1GC" "-XX:+UseStringDeduplication" "-javaagent:/home/saburto/.m2/repository/org/projectlombok/lombok/1.18.24/lombok-1.18.24.jar" ))
    (setq lsp-java--download-root (concat "file://" (expand-file-name "install/" (file-name-directory (symbol-file 'saburto-java/init-lsp-java)))))
    :hook ((java-ts-mode . lsp-deferred))
    :config
    (progn
      (dolist (prefix '(("mc" . "compile/create")
                        ("mgk" . "type hierarchy")
                        ("mt" . "test")))
        (spacemacs/declare-prefix-for-mode
          'java-ts-mode (car prefix) (cdr prefix)))

      (spacemacs/set-leader-keys-for-major-mode 'java-ts-mode
        "wu"  'lsp-java-update-project-configuration

        "ro" 'lsp-java-organize-imports

        "cc"  'lsp-java-build-project

        "gkk" 'lsp-java-type-hierarchy
        "gku" 'spacemacs/lsp-java-super-type
        "gks" 'spacemacs/lsp-java-sub-type
        )
      (add-to-list 'spacemacs--dap-supported-modes 'java-ts-mode)
      (require 'dap-java)
      (spacemacs/set-leader-keys-for-major-mode 'java-ts-mode
        ;; debug
        "ddj" 'dap-java-debug
        "dtt" 'dap-java-debug-test-method
        "dtc" 'dap-java-debug-test-class
        ;; run
        "tl" 'recompile
        "tt" 'saburto-java/run-class-test-method
        "tc" 'saburto-java/run-class-test)
    )))

(defun saburto-java/init-java-snippets ()
  (use-package java-snippets
    :defer t))
