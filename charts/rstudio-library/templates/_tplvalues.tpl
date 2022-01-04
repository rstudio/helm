{{/* vim: set filetype=mustache: */}}
{{/* thanks to https://github.com/bitnami/charts/blob/master/bitnami/common/templates/_tplvalues.tpl */}}
{{/*
Renders a value that contains template.
Usage:
{{ include "rstudio-library.tplvalues.render" ( dict "value" .Values.path.to.the.Value "context" $) }}
*/}}
{{- define "rstudio-library.tplvalues.render" -}}
    {{- if typeIs "string" .value }}
        {{- tpl .value .context }}
    {{- else }}
        {{- tpl (.value | toYaml) .context }}
    {{- end }}
{{- end -}}
