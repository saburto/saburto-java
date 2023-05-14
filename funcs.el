(defun saburto-java--filter-package (node)
  (equal "package_declaration" (treesit-node-type node)))

(defun saburto-java--filter-scoped-identifier (node)
  (equal "scoped_identifier" (treesit-node-type node)))

(defun saburto-java--filter-class-declaration (node)
  (pcase (treesit-node-type node)
    ("class_declaration" t)
    ("record_declaration" t)))

(defun saburto-java--filter-identifier (node)
  (equal "identifier" (treesit-node-type node)))

(defun saburto-java--filter-method-declaration (node)
  (equal "method_declaration" (treesit-node-type node)))

(defun saburto-java--find-first-by-filter (root-node filter)
  (car (treesit-filter-child root-node filter t)))

(defun saburto-java--find-class-nodes (root-node)
  (treesit-filter-child root-node 'saburto-java--filter-class-declaration t))

(defun saburto-java/return-package-name (&optional root-node)
  (interactive)
  (-> (or root-node (treesit-buffer-root-node 'java))
      (saburto-java--find-first-by-filter 'saburto-java--filter-package)
      (saburto-java--find-first-by-filter 'saburto-java--filter-scoped-identifier)
      (treesit-node-text t)))

(defun saburto-java/return-class-name (&optional root-node first-one)
  (interactive)
  (let* ((names
          (->> (or root-node (treesit-buffer-root-node 'java))
              (saburto-java--find-class-nodes)
              (-mapcat (lambda (n) (treesit-filter-child 'saburto-java--filter-identifier)))
              (-map (lambda (n) (treesit-node-text n t)))))
         (name  (if (or (length= names 1) first-one)
                    (car names)
                  (completing-read "Class: " names))))
    name))

(defun saburto-java--return-class-name-at (node &optional class-name)

  (let* ((parent-class-node (treesit-parent-until node 'saburto-java--filter-class-declaration nil))
         (new-class-id (car (treesit-filter-child parent-class-node 'saburto-java--filter-identifier)))
         (new-class-name (treesit-node-text new-class-id t)))
    (if new-class-name
        (saburto-java--return-class-name-at parent-class-node
                                            (if class-name
                                                (format "%s$%s" new-class-name class-name )
                                              new-class-name))
      class-name)
    ))


(defun saburto-java/get-fqcn ()
  (interactive)
  (let* ((root-node (treesit-buffer-root-node 'java))
         (package-name (saburto-java/return-package-name root-node))
         (class-name (saburto-java/return-class-name root-node t)))
    (if (and package-name class-name)
        (format "%s.%s" package-name class-name)
      (error "Error trying to find package and class name"))))

(defun saburto-java/get-fqcn-at-point ()
  (interactive)
  (let* ((node-at-point (treesit-node-at (point) 'java))
         (package-name (saburto-java/return-package-name))
         (class-name (saburto-java--return-class-name-at node-at-point)))
    (if (and package-name class-name)
        (format "%s.%s" package-name class-name)
      (error "Error trying to find package and class name"))))

(defun saburto-java/get-method-at-point ()
  (interactive)
  (-> (treesit-node-at (point) 'java)
       (treesit-parent-until 'saburto-java--filter-method-declaration t)
       (saburto-java--find-first-by-filter 'saburto-java--filter-identifier)
       (treesit-node-text t)))

(defun saburto-java/get-classpath-by-scope (scope)
  (plist-get
   (lsp-send-execute-command "java.project.getClasspaths"
                             (vector (lsp--path-to-uri (buffer-file-name))
                                     (json-encode `(( "scope" . ,scope)))))
   :classpaths))


(defun saburto-java/parrot-animate-when-compile-success (buffer result)
  (if (string-match-p "exited abnormally with code" result)
      (message "❌ FAILED")
    (message "✅ SUCCESSFUL")))

(define-derived-mode saburto-java/junit5-compilation-mode compilation-mode "Junit Test Runner Compilation"
  "Compilation mode for Maven output."
  (set (make-local-variable 'compilation-error-regexp-alist)
       (append '(java-src-stack-trace)
	             compilation-error-regexp-alist))
  (set (make-local-variable 'compilation-scroll-output) t)

  (set (make-local-variable 'compilation-error-regexp-alist-alist)
       (append '((java-src-stack-trace "at \\(\\(?:[[:alnum:]]+\\.\\)+\\)+[[:alnum:]]+\\.[[:alnum:]]+(\\([[:alnum:]]+\\Test.java\\):\\([[:digit:]]+\\))$"
		                                   maven-test-java-tst-stack-trace-regexp-to-filename 3))
               compilation-error-regexp-alist-alist)))


(defun saburto-java--run-test-by-fqcn (test-name)
  "Run a according the test-name "
  (let* ((cp (saburto-java/get-classpath-by-scope "test")))
    (setenv "JUNIT_CLASSPATH" (s-join path-separator cp))

    (compile
     (concat "java -jar "
             dap-java-test-runner
             (if (string-match-p "#" test-name)
                 " -m "
               " -c ")
             (format "'%s'" test-name)
             " --disable-banner "
             " --details=verbose "
             " --fail-if-no-tests "
             " -class-path $JUNIT_CLASSPATH "
             " ")
     'saburto-java/junit5-compilation-mode)))

(defun saburto-java/run-class-test ()
  "Run a test class."
  (interactive)
  (saburto-java--run-test-by-fqcn (saburto-java/get-fqcn-at-point)))

(defun saburto-java/run-class-test-method ()
  "Run a test method at the point."
  (interactive)
  (let* ((fqcn (saburto-java/get-fqcn-at-point))
         (method (saburto-java/get-method-at-point))
         (test-name (if method (format "%s#%s" fqcn method) fqcn)))
    (saburto-java--run-test-by-fqcn test-name)))

