(defsystem "openapi-protocol"
  :version "0.1.0"
  :description "OpenAPI 3.x emit from schema-protocol + Clack; JSON/YAML envelope (stack-openapi)"
  :author "egao1980"
  :license "MIT"
  :depends-on ("schema-protocol" "schema-protocol-json" "json-protocol" "yaml-protocol")
  :properties (:cl-repo (:ci (:with ("json-backend-jzon"))))
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "document")
               (:file "encode")
               (:file "clack"))
  :in-order-to ((test-op (test-op "openapi-protocol/tests"))))

(defsystem "openapi-protocol/tests"
  :depends-on ("openapi-protocol" "json-backend-jzon" "schema-protocol" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "document-test")
               (:file "encode-test")
               (:file "clack-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
