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
    {{- if and (or .Values.sharedStorage.create .Values.sharedStorage.mount) .Values.sharedStorage.mountContent }}
      {{- $dataDirPVCName := default (print (include "rstudio-connect.fullname" .) "-shared-storage" ) .Values.sharedStorage.name }}
      {{- $_ := set $launcherSettingsDict "DataDirPVCName" $dataDirPVCName }}
    {{- end }}
    {{- if .Values.launcher.useTemplates }}
      {{- $_ := set $launcherSettingsDict "KubernetesUseTemplates" "true" }}
      {{- $_ = set $launcherSettingsDict "ScratchPath" "/var/lib/rstudio-connect-launcher" }}
    {{- else }}
      {{- $_ := set $launcherSettingsDict "KubernetesUseTemplates" "false" }}
    {{- end }}
    {{- $launcherDict := dict "Launcher" ( $launcherSettingsDict ) }}
    {{- $defaultConfig = merge $defaultConfig $launcherDict }}
  {{- end }}
  {{- /* default licensing configuration */}}
  {{- if .Values.license.server }}
    {{- $licenseDict := dict "Licensing" ( dict "LicenseType" ("Remote") ) }}
    {{- $defaultConfig = merge $defaultConfig $licenseDict }}
  {{- end }}
  {{- include "rstudio-library.config.gcfg" ( mergeOverwrite $defaultConfig .Values.config ) }}
{{- end -}}

{{/*
  - Define the runtime.yaml file
    - If a string:
      - if "pro" - use pro runtime.yaml
        - If additionalRuntimeImages is a string, append
      - if "base" - use base runtime.yaml
        - If additionalRuntimeImages is a string, append
      - otherwise use the string verbatim
        - If additionalRuntimeImages is a string, append
    - If a map, pass it to "toYaml"
      - If additionalRuntimeImages is a list, append
    - Otherwise use the base runtime.yaml

    When we append additionalRuntimeImages as a string, we presume that
    the end of the runtimeImages file is still in the context of the "images" key
*/}}
{{- define "rstudio-connect.runtimeYaml" -}}
  {{- $runtimeYaml := deepCopy .Values.launcher.customRuntimeYaml }}
  {{- $additionalImages := deepCopy .Values.launcher.additionalRuntimeImages }}
  {{- if kindIs "string" $runtimeYaml }}
    {{- if eq $runtimeYaml "pro" }}
      {{- .Files.Get "default-runtime-pro.yaml" }}
      {{- include "rstudio-connect.additionalImagesString" $additionalImages }}
    {{- else if eq $runtimeYaml "base" }}
      {{- .Files.Get "default-runtime.yaml" }}
      {{- include "rstudio-connect.additionalImagesString" $additionalImages }}
    {{- else }}
      {{- /* Allow verbatim output */ -}}
      {{- $runtimeYaml }}
      {{- include "rstudio-connect.additionalImagesString" $additionalImages }}
    {{- end }}
  {{- else if kindIs "map" $runtimeYaml }}
    {{- /*
      only include additionalImages if it is a list.
      otherwise it is possible the keys could be mismatched
     */ -}}
    {{- if kindIs "list" $additionalImages }}
      {{- $_ := set $runtimeYaml "images" (append $runtimeYaml.images $additionalImages) }}
    {{- end }}
    {{- toYaml $runtimeYaml }}
  {{- else }}
    {{- /* falsy or catch-all */ -}}
    {{- .Files.Get "default-runtime.yaml" }}
    {{- include "rstudio-connect.additionalImagesString" $additionalImages }}
  {{- end }}
{{- end -}}

{{- define "rstudio-connect.additionalImagesString" }}
  {{- if . }}
    {{- if kindIs "string" . }}
      {{- . | nindent 2 }}
    {{- else }}
      {{- toYaml . | nindent 2 }}
    {{- end }}
  {{- end }}
{{- end }}

{{- define "rstudio-connect.pod.annotations" -}}
{{- range $key,$value := $.Values.pod.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}
