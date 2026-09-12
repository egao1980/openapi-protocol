(in-package #:openapi-protocol/tests)

(defun %ensure-json ()
  (json-backend-jzon:use-jzon-backend))

(defun %lisp= (a b)
  (cond
    ((and (hash-table-p a) (hash-table-p b))
     (and (= (hash-table-count a) (hash-table-count b))
          (loop for k being the hash-keys of a using (hash-value v)
                always (and (nth-value 1 (gethash k b))
                            (%lisp= v (gethash k b))))))
    ((and (vectorp a) (not (stringp a))
          (vectorp b) (not (stringp b)))
     (and (= (length a) (length b))
          (loop for i from 0 below (length a)
                always (%lisp= (aref a i) (aref b i)))))
    (t (equal a b))))

(deftest encode-json-yaml-roundtrip
  (%ensure-json)
  (defschema %oa-enc ()
    (name string))
  (let* ((doc (make-document :title "T" :schemas '(%oa-enc)))
         (json (encode doc :format :json))
         (yaml (encode doc :format :yaml)))
    (ok (search "\"openapi\"" json))
    (ok (%lisp= doc (decode json :format :json)))
    (ok (%lisp= doc (decode yaml :format :yaml)))
    (ok (%lisp= doc (decode json :format :auto)))))

(deftest unknown-format-signals
  (ok (signals (encode (make-hash-table) :format :xml) 'unknown-format))
  (ok (signals (decode "{}" :format :xml) 'unknown-format)))
