{{- /*
  Define volume mounts for license configuration
  Takes a dict:
    "license": "the license configuration values"
*/ -}}
{{- define "rstudio-library.license-mount" -}}
{{- if or .license.file.contents .license.file.secret }}
- name: license-file
  mountPath: {{ .license.file.mountPath | quote }}
  {{- if .license.file.mountSubPath }}
  subPath: {{ .license.file.secretKey | quote }}
  {{- end }}
{{- end }}
{{- end -}}{{- /* end define template */ -}}
