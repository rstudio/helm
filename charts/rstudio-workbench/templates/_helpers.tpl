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

{{- define "rstudio-workbench.containers" -}}
{{- $useLegacyProfiles := hasKey .Values.config.server "launcher.kubernetes.profiles.conf" }}
containers:
- name: rstudio
  {{- $defaultVersion := .Values.versionOverride | default $.Chart.AppVersion }}
  image: "{{ .Values.image.repository }}:{{ .Values.image.tag | default $defaultVersion }}"
  env:
  {{- if .Values.diagnostics.enabled }}
  - name: DIAGNOSTIC_DIR
    value: "{{ .Values.diagnostics.directory }}"
  - name: DIAGNOSTIC_ONLY
    value: "true"
  - name: DIAGNOSTIC_ENABLE
    value: "true"
  {{- end }}
  {{- if not .Values.launcher.kubernetesHealthCheck.enabled }}
  - name: RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK
    value: disabled
  {{- end }}
  {{- if .Values.launcher.kubernetesHealthCheck.enabled }}
  - name: RSTUDIO_LAUNCHER_STARTUP_HEALTH_CHECK_ARGS
    value: "{{ join " " .Values.launcher.kubernetesHealthCheck.extraCurlArgs }}"
  {{- end }}
  - name: RSTUDIO_LAUNCHER_NAMESPACE
    value: "{{ default $.Release.Namespace .Values.launcher.namespace }}"
  {{- include "rstudio-library.license-env" (dict "license" ( .Values.license ) "product" ("rstudio-workbench") "envVarPrefix" ("RSW") "fullName" (include "rstudio-workbench.fullname" .)) | nindent 2 }}
  - name: RSW_LAUNCHER
    value: "{{ .Values.launcher.enabled }}"
  {{- if .Values.userCreate }}
  - name: RSW_TESTUSER
    value: "{{ .Values.userName }}"
  - name: RSW_TESTUSER_UID
    value: "{{ .Values.userUid }}"
  - name: RSW_TESTUSER_PASSWD
    value: "{{ .Values.userPassword }}"
  {{- else }}
  - name: RSW_TESTUSER
    value: ""
  {{- end }}
  - name: XDG_CONFIG_DIRS
    value: "{{ template "rstudio-workbench.xdg-config-dirs" .}}"
  {{- if .Values.pod.env }}
{{ toYaml .Values.pod.env | indent 2 }}
  {{- end }}
  {{- if .Values.command }}
  command:
{{ toYaml .Values.command | indent 4 }}
 {{- end }}
  {{- if .Values.args }}
  args:
{{ toYaml .Values.args | indent 4 }}
  {{- end }}
  imagePullPolicy: "{{ .Values.image.imagePullPolicy }}"
  ports:
  - containerPort: 8787
  securityContext:
{{ toYaml .Values.securityContext | indent 4 }}
  volumeMounts:
    {{- if or .Values.sharedStorage.create .Values.sharedStorage.mount }}
    - name: rstudio-shared-storage
      mountPath: "{{ .Values.sharedStorage.path }}"
    {{- end }}
    {{- if or .Values.homeStorage.create .Values.homeStorage.mount }}
    - name: rstudio-home-storage
      mountPath: "{{ .Values.homeStorage.path }}"
    {{- end }}
    - name: rstudio-prestart
      mountPath: "/scripts/"
    - name: rstudio-config
      mountPath: "/mnt/configmap/rstudio/"
    - name: rstudio-session-config
      mountPath: "/mnt/session-configmap/rstudio/"
    {{- if .Values.config.sessionSecret }}
    - name: rstudio-session-secret
      mountPath: {{ .Values.session.defaultSecretMountPath }}
    {{- end }}
    - name: rstudio-secret
      mountPath: "/mnt/secret-configmap/rstudio/"
    {{- if .Values.config.userProvisioning }}
    - name: rstudio-user
      mountPath: "/etc/sssd/conf.d/"
    {{- end }}
    - name: etc-rstudio
      mountPath: "/etc/rstudio"
    - name: rstudio-rsw-startup
      mountPath: "/startup/base"
    {{- if .Values.launcher.enabled }}
    - name: rstudio-launcher-startup
      mountPath: "/startup/launcher"
    {{- end }}
    {{- if .Values.config.startupUserProvisioning }}
    - name: rstudio-user-startup
      mountPath: "/startup/user-provisioning"
    {{- end }}
    {{- if .Values.config.startupCustom }}
    - name: rstudio-custom-startup
      mountPath: "/startup/custom"
    {{- end }}
    {{- if .Values.config.pam }}
      {{- range $i, $pamFileName := keys .Values.config.pam }}
    - name: rstudio-pam
      mountPath: "/etc/pam.d/{{ $pamFileName }}"
      subPath: "{{ $pamFileName }}"
      {{- end }}
    {{- end }}
    {{- include "rstudio-library.license-mount" (dict "license" ( .Values.license )) | nindent 4 }}
    {{- /* TODO: path collision problems... would be ideal to not have to maintain both long term */}}
    {{- if .Values.jobJsonOverridesFiles }}
    - name: rstudio-job-overrides-old
      mountPath: "/mnt/job-json-overrides"
    {{- end }}
    {{- if not $useLegacyProfiles }}
    - name: rstudio-job-overrides-new
      mountPath: "/mnt/job-json-overrides-new"
    {{- end }}
    {{- if .Values.pod.volumeMounts }}
    {{- toYaml .Values.pod.volumeMounts | nindent 4 }}
    {{- end }}
  resources:
    {{- if .Values.resources.requests.enabled }}
    requests:
      memory: "{{ .Values.resources.requests.memory }}"
      cpu: "{{ .Values.resources.requests.cpu }}"
      ephemeral-storage: "{{ .Values.resources.requests.ephemeralStorage }}"
    {{- end }}
    limits:
    {{- if .Values.resources.limits.enabled }}
      memory: "{{ .Values.resources.limits.memory }}"
      cpu: "{{ .Values.resources.limits.cpu }}"
      ephemeral-storage: "{{ .Values.resources.limits.ephemeralStorage }}"
    {{- end }}
  {{- if .Values.livenessProbe.enabled }}
  livenessProbe:
    httpGet:
      path: /health-check
      port: 8787
    initialDelaySeconds: {{ .Values.livenessProbe.initialDelaySeconds }}
    periodSeconds: {{ .Values.livenessProbe.periodSeconds }}
    timeoutSeconds: {{ .Values.livenessProbe.timeoutSeconds }}
    failureThreshold: {{ .Values.livenessProbe.failureThreshold }}
  {{- end }}
  {{- if .Values.startupProbe.enabled }}
  startupProbe:
    httpGet:
      path: /health-check
      port: 8787
    initialDelaySeconds: {{ .Values.startupProbe.initialDelaySeconds }}
    periodSeconds: {{ .Values.startupProbe.periodSeconds }}
    timeoutSeconds: {{ .Values.startupProbe.timeoutSeconds }}
    failureThreshold: {{ .Values.startupProbe.failureThreshold }}
  {{- end }}
  {{- if .Values.readinessProbe.enabled }}
  readinessProbe:
    httpGet:
      path: /health-check
      port: 8787
    initialDelaySeconds: {{ .Values.readinessProbe.initialDelaySeconds }}
    periodSeconds: {{ .Values.readinessProbe.periodSeconds }}
    timeoutSeconds: {{ .Values.readinessProbe.timeoutSeconds }}
    successThreshold: {{ .Values.readinessProbe.successThreshold }}
    failureThreshold: {{ .Values.readinessProbe.failureThreshold }}
  {{- end }}
{{- if .Values.prometheusExporter.enabled }}
- name: exporter
  image: "{{ .Values.prometheusExporter.image.repository }}:{{ .Values.prometheusExporter.image.tag }}"
  imagePullPolicy: "{{ .Values.prometheusExporter.image.imagePullPolicy }}"
  args:
    - "--graphite.mapping-config=/mnt/graphite/graphite-mapping.yaml"
  volumeMounts:
    - name: graphite-exporter-config
      mountPath: "/mnt/graphite/"
{{- end }}
{{- if .Values.pod.sidecar }}
{{ toYaml .Values.pod.sidecar }}
{{- end }}
volumes:
{{- if or .Values.sharedStorage.create .Values.sharedStorage.mount }}
- name: rstudio-shared-storage
  persistentVolumeClaim:
    claimName: {{default (print (include "rstudio-workbench.fullname" .) "-shared-storage" ) .Values.sharedStorage.name }}
{{- end }}
{{- if or .Values.homeStorage.create .Values.homeStorage.mount }}
- name: rstudio-home-storage
  persistentVolumeClaim:
    claimName: {{default (print (include "rstudio-workbench.fullname" .) "-home-storage" ) .Values.homeStorage.name }}
{{- end }}
{{- if .Values.jobJsonOverridesFiles }}
- name: rstudio-job-overrides-old
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-overrides-old
    defaultMode: 0644
{{- end }}
{{- if not $useLegacyProfiles }}
- name: rstudio-job-overrides-new
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-overrides-new
    defaultMode: 0644
{{- end }}
- name: etc-rstudio
  emptyDir: {}
- name: rstudio-config
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-config
    defaultMode: 0644
- name: rstudio-session-config
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-session
    defaultMode: 0644
{{- if .Values.config.sessionSecret }}
- name: rstudio-session-secret
  secret:
    secretName: {{ include "rstudio-workbench.fullname" . }}-session-secret
{{- end }}
- name: rstudio-prestart
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-prestart
    defaultMode: 0755
- name: rstudio-rsw-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-rsw
    defaultMode: 0755
{{- if .Values.launcher.enabled }}
- name: rstudio-launcher-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-launcher
    defaultMode: 0755
{{- end }}
{{- if .Values.config.startupUserProvisioning }}
- name: rstudio-user-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-user
    defaultMode: 0755
{{- end }}
{{- if .Values.config.startupCustom }}
- name: rstudio-custom-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-custom
    defaultMode: 0755
{{- end }}
{{- if .Values.config.pam }}
- name: rstudio-pam
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-pam
    defaultMode: 0755
{{- end }}
- name: rstudio-secret
  secret:
    secretName: {{ include "rstudio-workbench.fullname" . }}-secret
    defaultMode: 0600
{{- if .Values.config.userProvisioning }}
- name: rstudio-user
  secret:
    secretName: {{ include "rstudio-workbench.fullname" . }}-user
    defaultMode: 0600
{{- end }}
{{ include "rstudio-library.license-volume" (dict "license" ( .Values.license ) "fullName" (include "rstudio-workbench.fullname" .)) }}
{{- if .Values.prometheusExporter.enabled }}
- name: graphite-exporter-config
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-graphite
    defaultMode: 0755
{{- end }}
{{- if .Values.pod.volumes }}
{{ toYaml .Values.pod.volumes }}
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
{{- range $key,$value := .Values.service.annotations -}}
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
