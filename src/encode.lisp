(in-package #:openapi-protocol)

(defun encode (document &key stream (format :json))
  "Write DOCUMENT (hash-table) via json-protocol or yaml-protocol."
  (case format
    (:json (json-protocol:encode document :stream stream))
    (:yaml (yaml-protocol:encode document :stream stream))
    (otherwise
     (error 'unknown-format
            :format format
            :message (format nil "unknown OpenAPI format ~S" format)))))

(defun decode (source &key (format :json))
  "Read an OpenAPI document. :auto uses yaml-protocol (JSON ⊂ YAML)."
  (case format
    (:json (json-protocol:decode source))
    (:yaml (yaml-protocol:decode source))
    (:auto (yaml-protocol:decode source))
    (otherwise
     (error 'unknown-format
            :format format
            :message (format nil "unknown OpenAPI format ~S" format)))))
