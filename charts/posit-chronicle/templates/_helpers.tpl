{{/* vim: set filetype=mustache: */}}

{{/*
Generate annotations for  various resources
*/}}

{{- define "posit-chronicle.pod.annotations" -}}
{{- range $key,$value := $.Values.pod.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- if .Values.config.metrics.enabled }}
prometheus.io/scrape: "true"
{{- if .Values.config.https.enabled }}
prometheus.io/port: "443"
{{- else}}
prometheus.io/port: "5252"
{{- end }}

{{- end }}
{{- end -}}

{{- define "posit-chronicle.serviceaccount.annotations" -}}
{{- range $key,$value := $.Values.serviceaccount.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{- define "posit-chronicle.service.annotations" -}}
{{- range $key,$value := $.Values.service.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{/*
Generate labels for  various resources
*/}}

{{- define "posit-chronicle.pod.labels" -}}
{{- range $key,$value := $.Values.pod.labels -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{- define "posit-chronicle.serviceaccount.labels" -}}
{{- range $key,$value := $.Values.serviceaccount.labels -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{- define "posit-chronicle.service.labels" -}}
{{- range $key,$value := $.Values.service.labels -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{/*
Generate selector labels for  various resources
*/}}

{{- define "posit-chronicle.pod.selectorLabels" -}}
{{- range $key,$value := $.Values.pod.selectorLabels -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
app: chronicle-server
{{- end -}}

{{- define "posit-chronicle.service.selectorLabels" -}}
{{- range $key,$value := $.Values.service.selectorLabels -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
app: chronicle-server
{{- end -}}

