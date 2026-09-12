(in-package #:openapi-protocol)

;;; Clack env app — no second router. Compose with the real app via WRAP-APP.

(defun %path-info (env)
  (or (getf env :path-info) (getf env :request-uri) "/"))

(defun %method (env)
  (getf env :request-method :get))

(defun %serve-document (document format content-type)
  (list 200
        (list :content-type content-type)
        (list (encode document :format format))))

(defun document-path-p (env &key (json-path "/openapi.json") (yaml-path "/openapi.yaml"))
  (let ((path (%path-info env))
        (method (%method env)))
    (and (or (eq method :get) (string-equal method "GET"))
         (or (string= path json-path)
             (string= path yaml-path)))))

(defun document-app (document &key (json-path "/openapi.json") (yaml-path "/openapi.yaml"))
  "Clack app that serves DOCUMENT at JSON-PATH / YAML-PATH."
  (lambda (env)
    (let ((path (%path-info env))
          (method (%method env)))
      (cond
        ((not (or (eq method :get) (string-equal method "GET")))
         '(405 (:content-type "text/plain") ("method not allowed")))
        ((string= path json-path)
         (%serve-document document :json "application/json"))
        ((string= path yaml-path)
         (%serve-document document :yaml "application/yaml"))
        (t '(404 (:content-type "text/plain") ("not found")))))))

(defun wrap-app (app document &key (json-path "/openapi.json") (yaml-path "/openapi.yaml"))
  "Serve the OpenAPI document; otherwise call APP (Clack env)."
  (let ((docs (document-app document :json-path json-path :yaml-path yaml-path)))
    (lambda (env)
      (if (document-path-p env :json-path json-path :yaml-path yaml-path)
          (funcall docs env)
          (funcall app env)))))
