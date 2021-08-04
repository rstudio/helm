{{- /*
  Define secrets for license configuration
  Takes a dict:
    "product": "the product, e.g., rstudio-pm"
    "namespace": "the namespace"
    "license": "the license configuration values"
    "fullName": "the fully qualified app name"
*/ -}}
{{- define "rstudio-library.license-secret" -}}
---
{{- if .license.key }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .fullName }}-license
  namespace: {{ .namespace }}
type: Opaque
stringData:
  {{ .product }}: {{ .license.key | quote }}
---
{{- end }}
{{- if .license.file.contents }}
apiVersion: v1
kind: Secret
metadata:
  name: {{ .fullName }}-license-file
  namespace: {{ .namespace }}
type: Opaque
stringData:
  {{ .license.file.secretKey }}: |
{{ .license.file.contents | indent 4 }}
---
{{- end }}

{{- end -}}{{- /* end define template */ -}}
