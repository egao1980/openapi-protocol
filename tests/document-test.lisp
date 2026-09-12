(in-package #:openapi-protocol/tests)

(defun %ensure-json ()
  (json-backend-jzon:use-jzon-backend))

(deftest emit-object-component
  (%ensure-json)
  (defschema %oa-addr ()
    (city string))
  (defschema %oa-user ()
    (name string :min-length 1)
    (age integer :minimum 0 :optional t)
    (address %oa-addr)
    (:extra :forbid))
  (let* ((schemas (component-schemas '(%oa-user)))
         (user (gethash "%oa-user" schemas))
         (addr (gethash "%oa-addr" schemas))
         (props (gethash "properties" user)))
    (ok (hash-table-p user))
    (ok (null (gethash "$schema" user)))
    (ok (null (gethash "$defs" user)))
    (ok (hash-table-p addr))
    (ok (equal "#/components/schemas/%oa-addr"
               (gethash "$ref" (gethash "address" props))))))

(deftest emit-tagged-discriminator
  (%ensure-json)
  (defschema %oa-shape ()
    (kind keyword)
    (:tag kind))
  (defschema %oa-circ (%oa-shape)
    (kind (eql :circ) :default :circ)
    (r number))
  (defschema %oa-rect (%oa-shape)
    (kind (eql :rect) :default :rect)
    (w number))
  (let* ((schemas (component-schemas '(%oa-shape)))
         (shape (gethash "%oa-shape" schemas))
         (disc (gethash "discriminator" shape))
         (one-of (gethash "oneOf" shape)))
    (ok (vectorp one-of))
    (ok (equal "kind" (gethash "propertyName" disc)))
    (ok (equal "#/components/schemas/%oa-circ"
               (gethash "circ" (gethash "mapping" disc))))
    (ok (hash-table-p (gethash "%oa-circ" schemas)))
    (ok (hash-table-p (gethash "%oa-rect" schemas)))))

(deftest make-document-paths
  (%ensure-json)
  (defschema %oa-pet ()
    (name string))
  (let* ((op (operation :operation-id "getPet"
                        :responses (list (cons 200 (response :description "ok"
                                                             :schema '%oa-pet)))))
         (doc (make-document :title "Pets"
                             :version "1.0.0"
                             :paths (list (cons "/pets/{id}" (path-item :get op)))
                             :schemas '(%oa-pet)))
         (paths (gethash "paths" doc))
         (get-op (gethash "get" (gethash "/pets/{id}" paths)))
         (resp (gethash "200" (gethash "responses" get-op))))
    (ok (equal "3.1.0" (gethash "openapi" doc)))
    (ok (equal "Pets" (gethash "title" (gethash "info" doc))))
    (ok (equal "getPet" (gethash "operationId" get-op)))
    (ok (equal "#/components/schemas/%oa-pet"
               (gethash "$ref"
                        (gethash "schema"
                                 (gethash "application/json"
                                          (gethash "content" resp))))))
    (ok (hash-table-p (gethash "%oa-pet"
                               (gethash "schemas" (gethash "components" doc)))))))

(deftest unknown-schema-signals
  (ok (signals (component-schema '%oa-missing) 'unknown-schema)))

(deftest unknown-schema-use-value
  (let ((fallback (let ((ht (make-hash-table :test #'equal)))
                    (setf (gethash "type" ht) "object")
                    ht)))
    (handler-bind ((unknown-schema
                    (lambda (c)
                      (use-value fallback c))))
      (let ((js (component-schema '%oa-missing)))
        (ok (eq fallback js))
        (ok (equal "object" (gethash "type" js)))))))
