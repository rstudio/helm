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

{{- define "rstudio-library.templates.dataOutputPretty" -}}
{{- $trailingDash := ternary "-" "" (default true .trailingDash) -}}
{{- printf "{{- define \"%s\" %s}}" .name $trailingDash -}}
{{- .value | toPrettyJson | nindent 0 }}
{{ printf "{{- end }}" -}}
{{- end }}
