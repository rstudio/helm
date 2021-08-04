{{- /*
  Define volume for license configuration
  Takes a dict:
    "license": "the license configuration values"
    "fullName": "the fully qualified app name"
*/ -}}
{{- define "rstudio-library.license-volume" -}}
{{- if or .license.file.contents .license.file.secret }}
- name: license-file
  secret:
    {{- if .license.file.secret }}
    secretName: {{ .license.file.secret }}
    {{- else }}
    secretName: {{ .fullName }}-license-file
    {{- end }}
{{- end }}
{{- end -}}{{- /* end define template */ -}}
