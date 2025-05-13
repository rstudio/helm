{{- define "chronicle-agent.image" }}
{{- if .Values.chronicleAgent.enabled }}
{{- $registry := required "registry must be specified for the chronicle-agent config.".Values.chronicleAgent.image.registry }}
{{- $repository := required "repository must be specified for the chronicle-agent config.".Values.chronicleAgent.image.repository }}
{{- $version := "default" }}
{{- if not .Values.chronicleAgent.image.tag }}
{{- range $index, $service := (lookup "v1" "Service" .Release.Namespace "").items }}
{{- $name := get $service.metadata.labels "app.kubernetes.io/name" }}
{{- $component := get $service.metadata.labels "app.kubernetes.io/component" }}
{{- if and (contains "posit-chronicle" $name) (eq $component "server") }}
{{- $version = get $service.metadata.labels "app.kubernetes.io/version" }}
{{- end }}
{{- end }}
{{- else }}
{{- $version = .Values.chronicleAgent.image.tag }}
{{- end }}
{{ $registry }}/{{ $repository }}:{{ $version }}
{{- end }}
{{- end }}

{{- define "chronicle-agent.serverAddress" }}
{{- if .Values.chronicleAgent.enabled }}
{{- range $index, $service := (lookup "v1" "Service" .Release.Namespace "").items }}
{{- $name := get $service.metadata.labels "app.kubernetes.io/name "}}
{{- $component := get $service.metadata.labels "app.kubernetes.io/component "}}
{{- if and (contains "posit-chronicle" $name) (eq $component "server") }}
{{ $name }}.{{ $service.metadata.namespace }}
{{- end }}
{{- end }}
{{- end }}
{{- end }}
