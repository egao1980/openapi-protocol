# openapi-protocol

OpenAPI 3.x **document emit** for [cl-stack](https://github.com/egao1980/cl-stack). Dogfoods the stack — no second schema, YAML, or app layer.

| Layer | Use |
|-------|-----|
| Document envelope | [`json-protocol`](https://github.com/egao1980/json-protocol) `:json` / [`yaml-protocol`](https://github.com/egao1980/json-protocol) `:yaml` |
| Components / schemas | [`schema-protocol`](https://github.com/egao1980/schema-protocol) + [`schema-protocol-json`](https://github.com/egao1980/schema-protocol-json) (draft-07; OpenAPI `oneOf` + `discriminator`) |
| App contract | Clack env ([`http-server-protocol`](https://github.com/egao1980/http-server-protocol)) |

| System | Role | OCI |
|--------|------|-----|
| `openapi-protocol` (`stack-openapi`) | `make-document` / `encode` / `document-app` | **0.1.0** |

```lisp
(asdf:load-system "json-backend-jzon")
(asdf:load-system "openapi-protocol")

(schema-protocol:defschema pet ()
  (name string))

(let ((doc (stack-openapi:make-document
             :title "Pets"
             :version "1.0.0"
             :paths (list (cons "/pets/{id}"
                                (stack-openapi:path-item
                                 :get (stack-openapi:operation
                                       :operation-id "getPet"
                                       :responses (list (cons 200 (stack-openapi:response
                                                                   :description "ok"
                                                                   :schema 'pet)))))))
             :schemas '(pet))))
  (stack-openapi:encode doc)              ; JSON
  (stack-openapi:encode doc :format :yaml)
  (stack-http-server:serve (stack-openapi:wrap-app #'your-app doc)))
```

0.1.0 is emit + Clack document endpoints. No codegen, no request validation (that is `schema-protocol`).

## License

MIT — see [LICENSE](LICENSE).
