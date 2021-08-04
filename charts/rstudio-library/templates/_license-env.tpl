{{- /*
  Define environment variables for license configuration
  Takes a dict:
    "product": "the product, e.g., rstudio-pm"
    "envVarPrefix": "the env var prefix, e.g., RSPM"
    "license": "the license configuration values"
    "fullName": "the fully qualified app name"
*/ -}}
{{- define "rstudio-library.license-env" -}}
{{- if .license.key }}
- name: {{ .envVarPrefix }}_LICENSE
  valueFrom:
    secretKeyRef:
      name: {{ .fullName }}-license
      key: {{ .product }}
{{- end }}
{{- if .license.server }}
- name: {{ .envVarPrefix }}_LICENSE_SERVER
  value: {{ .license.server | quote }}
{{- end }}
{{- if or .license.file.contents .license.file.secret }}
- name: {{ .envVarPrefix }}_LICENSE_FILE_PATH
  value: "{{ .license.file.mountPath }}/{{ .license.file.secretKey }}"
{{- end }}
{{- end -}}{{- /* end define template */ -}}
