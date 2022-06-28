{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rstudio-pm.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rstudio-pm.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "rstudio-pm.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rstudio-pm.labels" -}}
helm.sh/chart: {{ include "rstudio-pm.chart" . }}
{{ include "rstudio-pm.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rstudio-pm.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rstudio-pm.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{- define "rstudio-pm.config" -}}
{{/* generate the configuration, setting remote licensing if applicable */}}
{{- $overrideDict := .Values.config | deepCopy }}
{{- if .Values.license.server }}
  {{- $licenseParam := dict "LicenseType" "remote" }}
  {{- $licenseServerConf := dict "Licensing" $licenseParam }}
  {{- $overrideDict = mergeOverwrite $overrideDict $licenseServerConf }}
{{- end }}
{{- range $section,$keys := $overrideDict -}}
[{{ $section }}]
  {{- range $key, $val := $keys }}
    {{- if kindIs "slice" $val }}
      {{- range $eachval := $val }}
{{ $key }} = {{ $eachval }}
      {{- end }}
    {{- else }}
{{ $key }} = {{ $val }}
    {{- end }}
  {{- end }}

{{ end }}
{{- end -}}

{{- define "rstudio-pm.pod.annotations" -}}
{{- range $key,$value := $.Values.pod.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{/*
Create the name of the ServiceAccount
*/}}
{{- define "rstudio-pm.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "rstudio-pm.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}
