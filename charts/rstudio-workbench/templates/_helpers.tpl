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
{{- $useNewerOverrides := and (not (hasKey .Values.config.server "launcher.kubernetes.profiles.conf")) (not .Values.launcher.useTemplates) }}
containers:
- name: rstudio
  {{- $defaultVersion := .Values.versionOverride | default $.Chart.AppVersion }}
  {{- $imageTag := .Values.image.tag | default (printf "%s%s" .Values.image.tagPrefix $defaultVersion )}}
  image: "{{ .Values.image.repository }}:{{ $imageTag }}"
  {{- with .Values.pod.lifecycle }}
  lifecycle:
    {{- toYaml . | nindent 4 }}
  {{- end }}
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
  {{- if .Values.userPassword.existingSecret }}
  - name: RSW_TESTUSER_PASSWD
    valueFrom:
      secretKeyRef:
        key: password
        name: {{ .Values.userPassword.existingSecret }}
  {{- else if .Values.userPassword.value }}
  - name: RSW_TESTUSER_PASSWD
    value: {{ .Values.userPassword.value }}
  {{- end }}
  {{- else }}
  - name: RSW_TESTUSER
    value: ""
  {{- end }}
  {{- if or (gt (int .Values.replicas) 1) .Values.loadBalancer.forceEnabled }}
  - name: RSW_LOAD_BALANCING
    value: "true"
  {{- end }}
  - name: XDG_CONFIG_DIRS
    value: "{{ template "rstudio-workbench.xdg-config-dirs" .}}"
  {{- if .Values.pod.env }}
  {{- toYaml .Values.pod.env | nindent 2 }}
  {{- end }}
  {{- if .Values.command }}
  command:
    {{- toYaml .Values.command | nindent 4 }}
 {{- end }}
  {{- if .Values.args }}
  args:
    {{- toYaml .Values.args | nindent 4 }}
  {{- end }}
  imagePullPolicy: "{{ .Values.image.imagePullPolicy }}"
  ports:
  - containerPort: {{ .Values.pod.port }}
    name: http
  {{- if and .Values.prometheus.enabled (not .Values.prometheus.legacy) }}
  - containerPort: {{ .Values.prometheus.port }}
    name: metrics
  {{- end}}
  securityContext:
    {{- toYaml .Values.securityContext | nindent 4 }}
  volumeMounts:
    {{- if or .Values.sharedStorage.create .Values.sharedStorage.mount }}
    - name: rstudio-shared-storage
      mountPath: "{{ .Values.sharedStorage.path }}"
      {{- if .Values.sharedStorage.subPath }}
      subPath: "{{ .Values.sharedStorage.subPath }}"
      {{- end }}
    {{- end }}
    {{- if or .Values.homeStorage.create .Values.homeStorage.mount }}
    - name: rstudio-home-storage
      mountPath: "{{ .Values.homeStorage.path }}"
      {{- if .Values.homeStorage.subPath }}
      subPath: "{{ .Values.homeStorage.subPath }}"
      {{- end }}
    {{- end }}
    - name: rstudio-prestart
      mountPath: "/scripts/"
    - name: rstudio-config
      mountPath: "/mnt/configmap/rstudio/"
    - name: rstudio-session-config
      mountPath: "/mnt/session-configmap/rstudio/"
    {{- if hasKey .Values.config.session "pip.conf" }}
    - name: rstudio-session-config
      mountPath: "/etc/pip.conf"
      subPath: "pip.conf"
    {{- end }}
    {{- if .Values.config.sessionSecret }}
    - name: rstudio-session-secret
      mountPath: {{ .Values.session.defaultSecretMountPath }}
    {{- end }}
    {{- /* Mount rstudio-secret volume when any secret content needs to be available in the pod.
           This includes both existingSecret references AND direct .value settings for launcherPem and secureCookieKey. */ -}}
    {{- if or .Values.launcherPem.existingSecret .Values.launcherPem.value .Values.secureCookieKey.existingSecret .Values.secureCookieKey.value .Values.global.secureCookieKey.existingSecret .Values.global.secureCookieKey.value .Values.config.database.conf.existingSecret .Values.config.secret .Values.config.existingSecrets }}
    - name: rstudio-secret
      mountPath: "/mnt/secret-configmap/rstudio/"
    {{- end }}
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
    {{- if $useNewerOverrides }}
    - name: rstudio-job-overrides-new
      mountPath: "/mnt/job-json-overrides-new"
    {{- end }}
    {{- if .Values.launcher.useTemplates }}
    # mount into the default scratch-path... what if it gets changed?
    - name: session-templates
      mountPath: "/var/lib/rstudio-launcher/Kubernetes/rstudio-library-templates-data.tpl"
      subPath: "rstudio-library-templates-data.tpl"
    - name: session-templates
      mountPath: "/var/lib/rstudio-launcher/Kubernetes/job.tpl"
      subPath: "job.tpl"
    - name: session-templates
      mountPath: "/var/lib/rstudio-launcher/Kubernetes/service.tpl"
      subPath: "service.tpl"
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
    {{- if .Values.resources.limits.enabled }}
    limits:
      memory: "{{ .Values.resources.limits.memory }}"
      cpu: "{{ .Values.resources.limits.cpu }}"
      ephemeral-storage: "{{ .Values.resources.limits.ephemeralStorage }}"
    {{- end }}
  {{- if .Values.livenessProbe.enabled }}
    {{- $liveness := omit .Values.livenessProbe "enabled" }}
    {{- with $liveness }}
  livenessProbe:
      {{- toYaml . | nindent 10 }}
    {{- end }}
  {{- end }}
  {{- if .Values.startupProbe.enabled }}
    {{- $startup := omit .Values.startupProbe "enabled" }}
    {{- with $startup}}
  startupProbe:
      {{- toYaml . | nindent 10 }}
    {{- end }}
  {{- end }}
  {{- if .Values.readinessProbe.enabled }}
    {{- $readiness := omit .Values.readinessProbe "enabled" }}
    {{- with $readiness }}
  readinessProbe:
      {{- toYaml . | nindent 10 }}
    {{- end }}
  {{- end }}
{{- if and .Values.prometheus.legacy .Values.prometheusExporter.enabled }}
- name: exporter
  image: "{{ .Values.prometheusExporter.image.repository }}:{{ .Values.prometheusExporter.image.tag }}"
  imagePullPolicy: "{{ .Values.prometheusExporter.image.imagePullPolicy }}"
  args:
    - "--graphite.mapping-config=/mnt/graphite/graphite-mapping.yaml"
  volumeMounts:
    - name: graphite-exporter-config
      mountPath: "/mnt/graphite/"
  ports:
  - containerPort: 9108
    name: metrics
  {{- with .Values.prometheusExporter.resources }}
  resources:
    {{ toYaml . | nindent 10 }}
  {{- end }}
  securityContext:
    {{- toYaml .Values.prometheusExporter.securityContext | nindent 4 }}
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
    defaultMode: {{ .Values.config.defaultMode.jobJsonOverrides }}
{{- end }}
{{- if $useNewerOverrides }}
- name: rstudio-job-overrides-new
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-overrides-new
    defaultMode: {{ .Values.config.defaultMode.jobJsonOverrides }}
{{- end }}
- name: etc-rstudio
  emptyDir: {}
- name: rstudio-config
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-config
    defaultMode: {{ .Values.config.defaultMode.server }}
- name: rstudio-session-config
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-session
    defaultMode: {{ .Values.config.defaultMode.session }}
{{- if .Values.config.sessionSecret }}
- name: rstudio-session-secret
  secret:
    secretName: {{ include "rstudio-workbench.fullname" . }}-session-secret
    defaultMode: {{ .Values.config.defaultMode.sessionSecret }}
{{- end }}
- name: rstudio-prestart
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-prestart
    defaultMode: {{ .Values.config.defaultMode.prestart }}
- name: rstudio-rsw-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-rsw
    defaultMode: {{ .Values.config.defaultMode.startup }}
{{- if .Values.launcher.enabled }}
- name: rstudio-launcher-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-launcher
    defaultMode: {{ .Values.config.defaultMode.startup }}
{{- end }}
{{- if .Values.config.startupUserProvisioning }}
- name: rstudio-user-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-user
    defaultMode: {{ .Values.config.defaultMode.startup }}
{{- end }}
{{- if .Values.config.startupCustom }}
- name: rstudio-custom-startup
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-start-custom
    defaultMode: {{ .Values.config.defaultMode.startup }}
{{- end }}
{{- if .Values.config.pam }}
- name: rstudio-pam
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-pam
    defaultMode: {{ .Values.config.defaultMode.pam }}
{{- end }}
{{- /* Create rstudio-secret volume when any secret content needs to be projected into the pod.
       This includes both existingSecret references AND direct .value settings for launcherPem and secureCookieKey. */ -}}
{{- if or .Values.launcherPem.existingSecret .Values.launcherPem.value .Values.secureCookieKey.existingSecret .Values.secureCookieKey.value .Values.global.secureCookieKey.existingSecret .Values.global.secureCookieKey.value .Values.config.database.conf.existingSecret .Values.config.secret .Values.config.existingSecrets }}
- name: rstudio-secret
  projected:
    sources:
{{- if .Values.config.secret }}
{{- range $key, $value := .Values.config.secret }}
    - secret:
        name: {{ include "rstudio-workbench.fullname" $ }}-secret
        items:
        - key: {{ $key }}
          path: {{ $key }}
          mode: {{ $.Values.config.defaultMode.secret }}
{{- end }}
{{- end }}
{{- if .Values.launcherPem.existingSecret  }}
    - secret:
        name: {{ .Values.launcherPem.existingSecret }}
        items:
        - key: launcher.pem
          path: launcher.pem
          mode: {{ .Values.config.defaultMode.secret }}
{{- end }}
{{- /* Project launcher.pem from chart-managed secret when using .value (not existingSecret). */ -}}
{{- if and .Values.launcherPem.value (not .Values.launcherPem.existingSecret) }}
    - secret:
        name: {{ include "rstudio-workbench.fullname" . }}-secret
        items:
        - key: launcher.pem
          path: launcher.pem
          mode: {{ .Values.config.defaultMode.secret }}
{{- end }}
{{- if and .Values.secureCookieKey.existingSecret (not .Values.global.secureCookieKey.existingSecret) }}
    - secret:
        name: {{ .Values.secureCookieKey.existingSecret }}
        items:
        - key: secure-cookie-key
          path: secure-cookie-key
          mode: {{ .Values.config.defaultMode.secret }}
{{- end }}
{{- if .Values.global.secureCookieKey.existingSecret }}
    - secret:
        name: {{ .Values.global.secureCookieKey.existingSecret }}
        items:
        - key: secure-cookie-key
          path: secure-cookie-key
          mode: {{ .Values.config.defaultMode.secret }}
{{- end }}
{{- /* Project secure-cookie-key from chart-managed secret when using .value (not existingSecret).
       This handles the case where secureCookieKey.value or global.secureCookieKey.value is set directly,
       or when the key is auto-generated. */ -}}
{{- if and (or .Values.secureCookieKey.value .Values.global.secureCookieKey.value) (not (or .Values.secureCookieKey.existingSecret .Values.global.secureCookieKey.existingSecret)) }}
    - secret:
        name: {{ include "rstudio-workbench.fullname" . }}-secret
        items:
        - key: secure-cookie-key
          path: secure-cookie-key
          mode: {{ .Values.config.defaultMode.secret }}
{{- end }}
{{- if .Values.config.database.conf.existingSecret  }}
    - secret:
        name: {{ .Values.config.database.conf.existingSecret }}
        items:
        - key: database.conf
          path: database.conf
          mode: {{ .Values.config.defaultMode.secret }}
{{- end }}
{{- range .Values.config.existingSecrets }}
    - secret:
        name: {{ .name }}
        items:
        {{- range .items }}
        - key: {{ .key }}
          path: {{ .path }}
          mode: {{ $.Values.config.defaultMode.secret }}
        {{- end }}
{{- end }}
{{- end }}
{{- if .Values.config.userProvisioning }}
- name: rstudio-user
  secret:
    secretName: {{ include "rstudio-workbench.fullname" . }}-user
    defaultMode: {{ .Values.config.defaultMode.userProvisioning }}
{{- end }}
{{ include "rstudio-library.license-volume" (dict "license" ( .Values.license ) "fullName" (include "rstudio-workbench.fullname" .)) }}
{{- if and .Values.prometheus.legacy .Values.prometheusExporter.enabled }}
- name: graphite-exporter-config
  configMap:
    name: {{ include "rstudio-workbench.fullname" . }}-graphite
    defaultMode: {{ .Values.config.defaultMode.server }}
{{- end }}
{{- if .Values.launcher.useTemplates }}
- name: session-templates
  configMap:
    name: {{ include "rstudio-workbench.fullname" .}}-templates
    defaultMode: {{ .Values.config.defaultMode.server }}
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
            - If homeStorage.create or homeStorage.mount, then:
                - If config.serverDcf.launcher-mounts is a string, use that
                - If a list or dict, check if the MountPath or ClaimName is already in use
                  - If so, use existing mounts
                  - If not, add homeStorage mount
                - Otherwise use existing mounts
            - Otherwise use .Values.config.serverDcf.launcher-mounts
*/}}
{{- define "rstudio-workbench.config.launcherMounts" -}}
{{- $currentMounts := index $.Values.config.serverDcf "launcher-mounts"  }}
{{- $claimNameDefault := printf "%s-home-storage" (include "rstudio-workbench.fullname" . ) }}
{{- $claimName := default $claimNameDefault $.Values.homeStorage.name }}
{{- $finalMount := list }}
{{- /* only alter things if homeStorage is defined and enabled */ -}}
{{- if and (or $.Values.homeStorage.create $.Values.homeStorage.mount) $.Values.session.defaultHomeMount -}}
    {{- /* preserve strings */ -}}
    {{- if kindIs "string" $currentMounts }}
        {{- $finalMount = $currentMounts }}
    {{- /* for lists and dicts, potentially append */ -}}
    {{- else if or (kindIs "map" $currentMounts) (kindIs "slice" $currentMounts) }}
        {{- $tmpMounts := list }}
        {{- /* ensure $tmpMounts is a list */ -}}
        {{- if kindIs "map" $currentMounts }}
            {{- $tmpMounts = append $tmpMounts $currentMounts }}
        {{- else }}
            {{- $tmpMounts = $currentMounts }}
        {{- end }}

        {{- /* check if the defaultMount (of the homeStorage PVC) is already defined by the user */ -}}
        {{- /* TODO: implement a helper that does this lookup for us... so we can reuse in NOTES */ -}}
        {{- $mountAlreadyDefined := false }}
        {{- range $i, $elt := $tmpMounts }}
            {{- if hasKey $elt "MountPath" }}
              {{- if regexMatch (printf "^%s" (index $elt "MountPath" )) $.Values.homeStorage.path }}
                {{- /* the existing volume is a prefix of the homeStorage path */ -}}
                {{- $mountAlreadyDefined = true }}
              {{- end }}
              {{- if regexMatch (printf "^%s" $.Values.homeStorage.path) (index $elt "MountPath") }}
                {{- /* the existing volume is prefixed by the homeStorage path */ -}}
                {{- $mountAlreadyDefined = true }}
              {{- end }}
            {{- end }}
            {{- if hasKey $elt "ClaimName" }}
              {{- if eq (index $elt "ClaimName") $claimName }}
                {{- /* the existing volume already targets this same claim */ -}}
                {{- $mountAlreadyDefined = true }}
              {{- end }}
            {{- end }}
        {{- end }}

        {{- /* only alter $tmpMounts if claim is not provided by the user */ -}}
        {{- if not $mountAlreadyDefined }}
            {{- $defaultMount := (dict "MountType" "KubernetesPersistentVolumeClaim" "MountPath" $.Values.homeStorage.path "ClaimName" $claimName ) }}
            {{- if .Values.homeStorage.subPath }}
              {{- $defaultMount = merge $defaultMount (dict "SubPath" .Values.homeStorage.subPath )}}
            {{- end }}
            {{- $tmpMounts = append $tmpMounts $defaultMount}}
        {{- end }}

        {{- $finalMount = $tmpMounts }}
    {{- /* otherwise, do nothing */ -}}
    {{- else }}
        {{- /* we do not know how to handle any other types */ -}}
        {{- $finalMount = $currentMounts }}
    {{- end }}
{{- else }}
    {{- $finalMount = $currentMounts }}
{{- end }}
{{- include "rstudio-library.config.dcf" (dict "launcher-mounts" $finalMount ) }}
{{- end }}

{{/*
    Precedence:
      - .Values.launcherPem.existingSecret
      - .Values.launcherPem.value
      - auto-generated value
          - we check to see if the secret is already created
          - if it is, we warn and leave it alone
*/}}
{{- define "rstudio-workbench.launcherPem" -}}
{{- $pemVar := "" }}
{{- if $.Values.launcherPem.existingSecret -}}
{{- $currentSecret := lookup "v1" "Secret" $.Release.Namespace $.Values.launcherPem.existingSecret -}}
{{- if $currentSecret }}
{{- $pemVar = get $currentSecret.data "launcher.pem" | b64dec }}
{{- else -}}
{{- fail (print "Launcher PEM existing secret " $.Values.launcherPem.existingSecret " not found in namespace " $.Release.Namespace) -}}
{{- end -}}
{{- else if ne $.Values.launcherPem.value "" -}}
{{- $pemVar = $.Values.launcherPem.value -}}
{{- else if and (eq $.Values.launcherPem.value "") (eq $.Values.launcherPem.existingSecret "") -}}
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
      - .Values.global.secureCookieKey.existingSecret
      - .Values.global.secureCookieKey.value
      - .Values.secureCookieKey.existingSecret
      - .Values.secureCookieKey.value
      - auto-generated value
          - we check to see if the secret is already created
          - if it is, we warn and leave it alone
*/}}
{{- define "rstudio-workbench.secureCookieKey" -}}
{{- $cookieVar := "" }}
{{- if ne $.Values.global.secureCookieKey.existingSecret "" -}}
{{- $currentSecret := lookup "v1" "Secret" $.Release.Namespace $.Values.global.secureCookieKey.existingSecret -}}
{{- if $currentSecret }}
{{- $cookieVar = get $currentSecret.data "secure-cookie-key" | b64dec }}
{{- else -}}
{{- fail (print "Global secureCookieKey existing secret " $.Values.global.secureCookieKey.existingSecret " not found in namespace " $.Release.Namespace) -}}
{{- end -}}
{{- else if ne $.Values.global.secureCookieKey.value "" -}}
{{- $cookieVar = $.Values.global.secureCookieKey.value -}}
{{- else if ne $.Values.secureCookieKey.existingSecret "" -}}
{{- $currentSecret := lookup "v1" "Secret" $.Release.Namespace $.Values.secureCookieKey.existingSecret -}}
{{- if $currentSecret }}
{{- $cookieVar = get $currentSecret.data "secure-cookie-key" | b64dec }}
{{- else -}}
{{- fail (print "SecureCookieKey existing secret " $.Values.secureCookieKey.existingSecret " not found in namespace " $.Release.Namespace) -}}
{{- end -}}
{{- else if ne $.Values.secureCookieKey.value "" -}}
{{- $cookieVar = $.Values.secureCookieKey.value -}}
{{- else if eq ($cookieVar) ("") -}}
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

{{- define "rstudio-workbench.pod.annotations" -}}
{{- range $key,$value := $.Values.pod.annotations -}}
{{ $key }}: {{ $value | quote }}
{{ end }}
{{- end -}}


{{- define "rstudio-workbench.xdg-config-dirs" -}}
{{  trimSuffix ":" ( join ":" (list .Values.xdgConfigDirs (join ":" .Values.xdgConfigDirsExtra) ) ) }}
{{- end -}}
