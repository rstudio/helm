{{/* vim: set filetype=mustache: */}}

{{/*
Expand the chart name.
*/}}
{{- define "posit-chronicle.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "posit-chronicle.fullname" -}}
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
{{- define "posit-chronicle.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "posit-chronicle.namespace" -}}
{{- if .Values.namespaceOverride }}
{{- .Values.namespaceOverride }}
{{- else }}
{{- .Release.Namespace }}
{{- end }}
{{- end }}

{{/*
Create the Service Account name
*/}}
{{- define "posit-chronicle.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "posit-chronicle.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "posit-chronicle.selectorLabels" -}}
app.kubernetes.io/name: {{ include "posit-chronicle.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "posit-chronicle.labels" }}
helm.sh/chart: {{ include "posit-chronicle.chart" . }}
app.kubernetes.io/managed-by: {{ .Release.Service | quote }}
app.kubernetes.io/part-of: {{ .Chart.Name | quote }}
app.kubernetes.io/component: server
{{ include "posit-chronicle.selectorLabels" . }}
{{- if or .Chart.AppVersion .Values.image.tag }}
app.kubernetes.io/version: {{ mustRegexReplaceAllLiteral "@sha.*" .Values.image.tag "" | default .Chart.AppVersion | trunc 63 | trimSuffix "-" | quote }}
{{- end }}
{{- with .Values.commonLabels }}
{{ toYaml . }}
{{- end }}
{{- end }}

{{/*
Generate annotations for various resources
*/}}
{{- define "posit-chronicle.pod.annotations" }}
{{- $podAnnotations := merge .Values.pod.annotations .Values.commonAnnotations }}
{{- if .Values.config.Metrics.Enabled }}
{{- $_ := set $podAnnotations "prometheus.io/scrape" "true" }}
{{- if .Values.config.HTTPS.Enabled }}
{{- $_ := set $podAnnotations "prometheus.io/port" "443" }}
{{- else }}
{{- $_ := set $podAnnotations "prometheus.io/port" "5252" }}
{{- end }}
{{- end }}
{{- with $podAnnotations }}
{{- toYaml . }}
{{- end }}
{{- end }}
