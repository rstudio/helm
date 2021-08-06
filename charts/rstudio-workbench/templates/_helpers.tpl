{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "rstudio-workbench.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "rstudio-workbench.fullname" -}}
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
{{- define "rstudio-workbench.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "rstudio-workbench.labels" -}}
helm.sh/chart: {{ include "rstudio-workbench.chart" . }}
{{ include "rstudio-workbench.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "rstudio-workbench.selectorLabels" -}}
app.kubernetes.io/name: {{ include "rstudio-workbench.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
    Defines the default launcherMounts (if not defined)
        Precedence:
            - If .Values.config.serverDcf.launcher-mounts is defined, use that verbatim
            - If not, and if homestorage.create is true, provision home storage and launcher-mounts automatically
            - Otherwise use .Values.config.serverDcf.launcher-mounts
*/}}
{{- define "rstudio-workbench.config.launcherMounts" -}}
{{ $currentMounts := index $.Values.config.serverDcf "launcher-mounts"  }}
{{- if and ( empty $currentMounts ) ( or $.Values.homeStorage.create $.Values.homeStorage.mount ) -}}
{{- $claimNameDefault := printf "%s-home-storage" (include "rstudio-workbench.fullname" . ) }}
{{- $claimName := default $claimNameDefault $.Values.homeStorage.name }}
{{- $defaultMounts := (dict "launcher-mounts" (dict "MountType" "KubernetesPersistentVolumeClaim" "MountPath" $.Values.homeStorage.path "ClaimName" $claimName ) ) }}
{{ include "rstudio-library.config.dcf" $defaultMounts }}
{{- else }}
{{ include "rstudio-library.config.dcf" (dict "launcher-mounts" $currentMounts) }}
{{- end }}
{{- end }}

{{/*
    Precedence:
      - .Values.launcherPem
      - auto-generated value
          - we check to see if the secret is already created
          - if it is, we warn and leave it alone
*/}}
{{- define "rstudio-workbench.launcherPem" -}}
{{- $pemVar := $.Values.launcherPem -}}
{{- if eq ($.Values.launcherPem) ("") -}}
{{- $secretName := print (include "rstudio-workbench.fullname" .) "-secret" }}
{{- $currentSecret := lookup "v1" "Secret" $.Release.Namespace $secretName }}
{{- if and $currentSecret (not .Values.dangerRegenerateAutomatedValues) }}
{{- $pemVar = get $currentSecret.data "launcher.pem" | b64dec }}
{{- else }}
{{- $pemVar = genPrivateKey "rsa" -}}
{{- end }}
{{- end -}}
{{ print $pemVar }}
{{ end }}

{{/*
    Precedence:
      - .Values.global.secureCookieKey
      - .Values.secureCookieKey
      - auto-generated value
          - we check to see if the secret is already created
          - if it is, we warn and leave it alone
*/}}
{{- define "rstudio-workbench.secureCookieKey" -}}
{{- $cookieVar := default .Values.secureCookieKey .Values.global.secureCookieKey -}}
{{- if eq ($cookieVar) ("") -}}
{{- $secretName := print (include "rstudio-workbench.fullname" .) "-secret" }}
{{- $currentSecret := lookup "v1" "Secret" $.Release.Namespace $secretName }}
{{- if and $currentSecret (not .Values.dangerRegenerateAutomatedValues ) }}
{{- $cookieVar = get $currentSecret.data "secure-cookie-key" | b64dec }}
{{- else }}
{{- $cookieVar = uuidv4 -}}
{{- end }}
{{- end -}}
{{ print $cookieVar }}
{{ end }}

{{- define "rstudio-workbench.launcherNamespace" -}}
{{- $myvar := $.Release.Namespace -}}
{{- if $.Values.launcherNamespace -}}
{{- $myvar = $.Values.launcherNamespace -}}
{{- end -}}
{{ print $myvar }}
{{ end }}

{{- define "rstudio-workbench.annotations" -}}
{{- range $key,$value := $.Values.service.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}

{{- define "rstudio-workbench.pod.annotations" -}}
{{- range $key,$value := $.Values.pod.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}


{{- define "rstudio-workbench.xdg-config-dirs" -}}
{{  trimSuffix ":" ( join ":" (list .Values.xdgConfigDirs (join ":" .Values.xdgConfigDirsExtra) ) ) }}
{{- end -}}
