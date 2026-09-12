(in-package #:openapi-protocol)

;;; Document = hash-table (json-protocol mapping). Schemas come from
;;; schema-protocol-json. No second CLOS model layer.

(defun stringify-key (k)
  (cond
    ((stringp k) k)
    ((or (keywordp k) (symbolp k)) (string-downcase (symbol-name k)))
    (t (princ-to-string k))))

(defun %ht (&rest kvs)
  (let ((ht (make-hash-table :test #'equal)))
    (loop for (k v) on kvs by #'cddr
          when (and k v)
            do (setf (gethash (stringify-key k) ht) v))
    ht))

(defun component-key (schema)
  (string-downcase
   (symbol-name
    (cond
      ((symbolp schema) schema)
      ((typep schema 'schema-protocol:schema-class)
       (class-name schema))
      ((typep schema 'schema-protocol:schema-object)
       (class-name (class-of schema)))
      (t (error 'unknown-schema
                :name schema
                :message "schema designator must be a name, schema-class, or instance"))))))

(defun schema-ref (schema)
  (%ht "$ref" (format nil "#/components/schemas/~A" (component-key schema))))

(defun %defs-prefix-p (string)
  (let ((prefix "#/$defs/"))
    (and (stringp string)
         (>= (length string) (length prefix))
         (string= string prefix :end1 (length prefix)))))

(defun rewrite-ref-string (string)
  (if (%defs-prefix-p string)
      (concatenate 'string "#/components/schemas/" (subseq string 8))
      string))

(defun rewrite-refs (node)
  (cond
    ((stringp node)
     (rewrite-ref-string node))
    ((hash-table-p node)
     (maphash (lambda (k v)
                (setf (gethash k node) (rewrite-refs v)))
              node)
     node)
    ((and (vectorp node) (not (stringp node)))
     (map-into node #'rewrite-refs node))
    (t node)))

(defun %emit-json-schema (schema)
  (restart-case
      (handler-case (schema-protocol-json:emit schema)
        (schema-protocol:schema-unknown (e)
          (error 'unknown-schema
                 :name (schema-protocol:schema-unknown-name e)
                 :message (schema-protocol:schema-error-message e))))
    (use-value (value)
      :report "Use a supplied JSON Schema hash-table"
      value)))

(defun component-schema (schema)
  "Emit one schema-protocol model as an OpenAPI component hash (no $schema)."
  (let ((js (%emit-json-schema schema)))
    (unless (hash-table-p js)
      (error 'openapi-error :message "schema emit did not return a hash-table"))
    (remhash "$schema" js)
    js))

(defun %merge-defs (out defs)
  (when (hash-table-p defs)
    (maphash (lambda (k v)
               (unless (gethash k out)
                 (when (hash-table-p v)
                   (remhash "$schema" v))
                 (setf (gethash k out) v)))
             defs)))

(defun component-schemas (schemas)
  "SCHEMA designators → components.schemas hash. Hoists $defs and rewrites $ref."
  (let ((out (make-hash-table :test #'equal)))
    (dolist (schema (if (listp schemas) schemas (list schemas)))
      (let* ((js (component-schema schema))
             (defs (gethash "$defs" js))
             (key (component-key schema)))
        (remhash "$defs" js)
        (setf (gethash key out) js)
        (%merge-defs out defs)))
    (rewrite-refs out)))

(defun status-key (status)
  (cond
    ((stringp status) status)
    ((eq status :default) "default")
    ((integerp status) (princ-to-string status))
    (t (stringify-key status))))

(defun responses (alist)
  (let ((ht (make-hash-table :test #'equal)))
    (dolist (pair alist)
      (setf (gethash (status-key (car pair)) ht)
            (if (consp pair) (cdr pair) pair)))
    ht))

(defun response (&key (description "") schema (content-type "application/json"))
  (let ((ht (%ht "description" description)))
    (when schema
      (setf (gethash "content" ht)
            (%ht content-type (%ht "schema" (if (hash-table-p schema)
                                                schema
                                                (schema-ref schema))))))
    ht))

(defun request-body (&key schema (content-type "application/json") (required t))
  (%ht "required" required
       "content" (%ht content-type
                      (%ht "schema" (if (hash-table-p schema)
                                        schema
                                        (schema-ref schema))))))

(defun operation (&key operation-id summary description tags request-body responses)
  (let ((ht (%ht "operationId" operation-id
                 "summary" summary
                 "description" description
                 "tags" (and tags (coerce tags 'vector))
                 "requestBody" request-body)))
    (when responses
      (setf (gethash "responses" ht)
            (if (hash-table-p responses)
                responses
                (responses responses))))
    ht))

(defun path-item (&rest ops)
  (let ((ht (make-hash-table :test #'equal)))
    (loop for (method op) on ops by #'cddr
          do (setf (gethash (stringify-key method) ht) op))
    ht))

(defun ensure-paths (paths)
  (cond
    ((hash-table-p paths) paths)
    ((listp paths)
     (let ((ht (make-hash-table :test #'equal)))
       (dolist (pair paths)
         (setf (gethash (car pair) ht) (cdr pair)))
       ht))
    (t (error 'openapi-error :message "paths must be a hash-table or alist"))))

(defun make-document (&key (openapi "3.1.0")
                           title (version "0.1.0") description
                           paths schemas
                           info)
  (let ((doc (%ht "openapi" openapi
                  "info" (or info
                             (%ht "title" (or title "API")
                                  "version" version
                                  "description" description)))))
    (when paths
      (setf (gethash "paths" doc) (ensure-paths paths)))
    (when schemas
      (setf (gethash "components" doc)
            (%ht "schemas" (component-schemas schemas))))
    doc))
