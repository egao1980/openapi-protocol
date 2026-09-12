(in-package #:openapi-protocol)

(define-condition openapi-error (error)
  ((message :initarg :message :reader openapi-error-message :initform nil))
  (:report (lambda (c s)
             (format s "OpenAPI error~@[: ~A~]" (openapi-error-message c)))))

(define-condition unknown-schema (openapi-error)
  ((name :initarg :name :reader unknown-schema-name :initform nil))
  (:report (lambda (c s)
             (format s "Unknown schema~@[ ~S~]~@[: ~A~]"
                     (unknown-schema-name c)
                     (openapi-error-message c)))))

(define-condition unknown-format (openapi-error)
  ((format :initarg :format :reader unknown-format-format :initform nil))
  (:report (lambda (c s)
             (format s "Unknown OpenAPI format~@[ ~S~]"
                     (unknown-format-format c)))))
