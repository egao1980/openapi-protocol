(in-package #:openapi-protocol/tests)

(defun %ensure-json ()
  (json-backend-jzon:use-jzon-backend))

(defun %env (path &optional (method :get))
  (list :request-method method :path-info path))

(deftest document-app-json-yaml
  (%ensure-json)
  (let* ((doc (make-document :title "T"))
         (app (document-app doc)))
    (let ((res (funcall app (%env "/openapi.json"))))
      (ok (= 200 (first res)))
      (ok (search "application/json" (format nil "~A" (second res))))
      (ok (search "\"openapi\"" (first (third res)))))
    (let ((res (funcall app (%env "/openapi.yaml"))))
      (ok (= 200 (first res)))
      (ok (search "application/yaml" (format nil "~A" (second res)))))
    (ok (= 404 (first (funcall app (%env "/nope")))))
    (ok (= 405 (first (funcall app (%env "/openapi.json" :post)))))))

(deftest wrap-app-passthrough
  (%ensure-json)
  (let* ((doc (make-document :title "T"))
         (inner (lambda (env)
                  (declare (ignore env))
                  '(200 (:content-type "text/plain") ("ok"))))
         (app (wrap-app inner doc)))
    (ok (equal "ok" (first (third (funcall app (%env "/pets"))))))
    (ok (search "\"openapi\"" (first (third (funcall app (%env "/openapi.json"))))))))
