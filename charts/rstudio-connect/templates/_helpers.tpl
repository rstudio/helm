{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rstudio-connect.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rstudio-connect.fullname" -}}
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
{{- define "rstudio-connect.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rstudio-connect.labels" -}}
helm.sh/chart: {{ include "rstudio-connect.chart" . }}
{{ include "rstudio-connect.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rstudio-connect.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rstudio-connect.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
  Generate the configuration
    - set remote licensing if applicable
    - set launcher parameters if applicable
*/}}
{{- define "rstudio-connect.config" -}}
  {{- $defaultConfig := dict }}
  {{- /* default launcher configuration */}}
  {{- if .Values.launcher.enabled }}
    {{- $namespace := default $.Release.Namespace .Values.launcher.namespace }}
    {{- $launcherSettingsDict := dict "Enabled" ("true") "Kubernetes" ("true") "ClusterDefinition" (list "/etc/rstudio-connect/runtime.yaml") "KubernetesNamespace" ($namespace) "KubernetesProfilesConfig" ("/etc/rstudio-connect/launcher/launcher.kubernetes.profiles.conf") }}
    {{- $dataDirPVCName := default (print (include "rstudio-connect.fullname" .) "-shared-storage" ) .Values.sharedStorage.name }}
    {{- if .Values.sharedStorage.mountContent }}
      {{- $_ := set $launcherSettingsDict "DataDirPVCName" $dataDirPVCName }}
    {{- end }}
    {{- $launcherDict := dict "Launcher" ( $launcherSettingsDict ) }}
    {{- $pythonSettingsDict := dict "Enabled" ("true") }}
    {{- $pythonDict := dict "Python" ( $pythonSettingsDict ) }}
    {{- $defaultConfig = merge $defaultConfig $launcherDict $pythonDict }}
  {{- end }}
  {{- /* default licensing configuration */}}
  {{- if .Values.license.server }}
    {{- $licenseDict := dict "Licensing" ( dict "LicenseType" ("Remote") ) }}
    {{- $defaultConfig = merge $defaultConfig $licenseDict }}
  {{- end }}
  {{- include "rstudio-library.config.gcfg" ( mergeOverwrite $defaultConfig .Values.config ) }}
{{- end -}}

{{- define "rstudio-connect.annotations" -}}
{{- range $key,$value := $.Values.service.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{/*
  - Define the runtime.yaml file
    - If not defined (the default), use the included default-runtime.yaml
    - Otherwise, use what is provided verbatim
*/}}
{{- define "rstudio-connect.runtimeYaml" -}}
  {{- $runtimeYaml := .Values.launcher.customRuntimeYaml }}
  {{- if $runtimeYaml }}
    {{- /* Allow verbatim output */ -}}
    {{- if kindIs "string" $runtimeYaml }}
      {{- $runtimeYaml }}
    {{- /* Otherwise presume YAML was passed */ -}}
    {{- else }}
      {{- toYaml $runtimeYaml }}
    {{- end }}
  {{- else }}
    {{- .Files.Get "default-runtime.yaml" }}
  {{- end }}
{{- end -}}

{{- define "rstudio-connect.pod.annotations" -}}
{{- range $key,$value := $.Values.pod.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}
