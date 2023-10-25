{{- /*
  Define volume mounts for license configuration
  Takes a dict:
    "license": "the license configuration values"
*/ -}}
{{- define "rstudio-library.license-mount" -}}
{{- if or .license.file.contents .license.file.secret }}
- name: license-file
  {{- if .license.file.mountSubPath }}
  mountPath: "{{ .license.file.mountPath }}/{{ .license.file.secretKey }}"
  subPath: {{ .license.file.secretKey | quote }}
  {{ else }}
  mountPath: {{ .license.file.mountPath | quote }}
  {{- end }}
{{- end }}
{{- end -}}{{- /* end define template */ -}}
