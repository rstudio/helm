{{- define "rstudio-library.templates.job" -}}
  {{- include "rstudio-library.templates.b64.base.job" nil | b64dec }}
{{- end }}

{{- define "rstudio-library.templates.service" }}
  {{- include "rstudio-library.templates.b64.base.service" nil | b64dec }}
{{- end }}

{{- define "rstudio-library.templates.configmap" -}}
job.tpl: |
{{- include (printf "rstudio-library.templates.b64.%s.job" . ) nil | b64dec | nindent 2 }}
service.tpl: |
{{- include (printf "rstudio-library.templates.b64.%s.service" . ) nil | b64dec | nindent 2 }}
{{- end }}

{{- define "rstudio-library.templates.skeleton" -}}
{{- $trailingDash := ternary "-" "" (default true .trailingDash) -}}
{{- printf "{{- define \"%s\" %s}}" .name $trailingDash -}}
{{- .value | toYaml | nindent 0 }}
{{ printf "{{- end }}" -}}
{{- end }}

{{- define "rstudio-library.templates.dataOutput" -}}
{{- $trailingDash := ternary "-" "" (default true .trailingDash) -}}
{{- printf "{{- define \"%s\" %s}}" .name $trailingDash -}}
{{- .value | toJson | nindent 0 }}
{{ printf "{{- end }}" -}}
{{- end }}

{{- define "rstudio-library.templates.test" }}
  {{- range $path, $_ :=  .Files.Glob  "**" }}
    {{- $path }}
  {{- end }}
{{- end }}
