{{- define "posit-telemetry.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
If the release name contains the chart name, it's used as the full name.
*/}}
{{- define "posit-telemetry.fullname" -}}
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

{{- define "posit-telemetry.clickhouse.fullname" -}}
{{- printf "%s-clickhouse" (include "posit-telemetry.fullname" .) | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "posit-telemetry.labels" -}}
helm.sh/chart: {{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/version: {{ .Values.image.tag | default .Chart.AppVersion | quote }}
{{- end }}

{{- define "posit-telemetry.selectorLabels" -}}
app.kubernetes.io/name: {{ include "posit-telemetry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: server
{{- end }}

{{- define "posit-telemetry.clickhouse.selectorLabels" -}}
app.kubernetes.io/name: {{ include "posit-telemetry.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/component: clickhouse
{{- end }}

{{- define "posit-telemetry.clickhouse.secretName" -}}
{{- .Values.clickhouse.auth.existingSecret | default (include "posit-telemetry.clickhouse.fullname" .) }}
{{- end }}

{{- define "posit-telemetry.clickhouse.secretKey" -}}
{{- if .Values.clickhouse.auth.existingSecret }}
{{- .Values.clickhouse.auth.existingSecretKey }}
{{- else }}
{{- "password" }}
{{- end }}
{{- end }}

{{/*
The generated password, kept from the existing Secret on upgrade so it doesn't change. `helm template` can't read the
cluster, so it always shows a new one.
*/}}
{{- define "posit-telemetry.clickhouse.password" -}}
{{- $existing := lookup "v1" "Secret" .Release.Namespace (include "posit-telemetry.clickhouse.fullname" .) }}
{{- if and $existing (index $existing.data "password") }}
{{- index $existing.data "password" | b64dec }}
{{- else }}
{{- randAlphaNum 32 }}
{{- end }}
{{- end }}
