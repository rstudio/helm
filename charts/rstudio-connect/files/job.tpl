# Version: 2.3.0
# DO NOT MODIFY the "Version: " key
# Helm Version: v1
{{- $templateData := include "rstudio-library.templates.data" nil | mustFromJson }}
apiVersion: batch/v1
kind: Job
metadata:
  annotations:
    {{- with .Job.metadata.job.annotations }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 4 | trimPrefix (repeat 4 " ") }}
    {{- end }}
    {{- end }}
    {{- with $templateData.job.annotations }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 4 | trimPrefix (repeat 4 " ") }}
    {{- end }}
    {{- end }}
  labels:
    app.kubernetes.io/managed-by: "launcher"
    {{- with .Job.metadata.job.labels }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 4 | trimPrefix (repeat 4 " ") }}
    {{- end }}
    {{- end }}
    {{- with $templateData.job.labels }}
    {{- range $key, $val := . }}
    {{ $key }}: {{ toYaml $val | indent 4 | trimPrefix (repeat 4 " ") }}
    {{- end }}
    {{- end }}
  generateName: {{ toYaml .Job.generateName }}
spec:
  backoffLimit: 0
  template:
    metadata:
      annotations:
        {{- if .Job.tags }}
        {{- $i := 0 }}
        {{- range .Job.tags }}
        USER_TAG_{{ $i }}: {{ toYaml . | indent 8 | trimPrefix (repeat 8 " ") }}
        {{- $i = add $i 1 }}
        {{- end }}
        {{- end }}
        stdin: {{ toYaml .Job.stdin | indent 8 | trimPrefix (repeat 8 " ") }}
        user: {{ toYaml .Job.user }}
        name: {{ toYaml .Job.name }}
        service_ports: {{ toYaml .Job.servicePortsJson }}
        {{- if .Job.metadata }}
        user_metadata: {{ toJson .Job.metadata | toYaml | indent 8 | trimPrefix (repeat 8 " ") }}
        {{- end }}
        {{- with .Job.metadata.pod.annotations }}
        {{- range $key, $val := . }}
        {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
        {{- end }}
        {{- end }}
        {{- with $templateData.pod.annotations }}
        {{- range $key, $val := . }}
        {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
        {{- end }}
        {{- end }}
      labels:
        {{- with .Job.metadata.pod.labels }}
        {{- range $key, $val := . }}
        {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
        {{- end }}
        {{- end }}
        {{- with $templateData.pod.labels }}
        {{- range $key, $val := . }}
        {{ $key }}: {{ toYaml $val | indent 8 | trimPrefix (repeat 8 " ") }}
        {{- end }}
        {{- end }}
      generateName: {{ toYaml .Job.generateName }}
    spec:
      {{- if .Job.host }}
      nodeName: {{ toYaml .Job.host }}
      {{- end }}
      restartPolicy: Never
      {{- with $templateData.pod.serviceAccountName }}
      serviceAccountName: {{ . }}
      {{- end }}
      shareProcessNamespace: {{ .Job.shareProcessNamespace }}
      {{- if or (ne (len .Job.volumes) 0) (ne (len $templateData.pod.volumes) 0) }}
      volumes:
        {{- range .Job.volumes }}
        - {{ nindent 10 (toYaml .) | trim -}}
        {{- end }}
        {{- range $templateData.pod.volumes }}
        - {{ nindent 10 (toYaml .) | trim -}}
        {{- end }}
      {{- end }}
      {{- with $templateData.pod.tolerations }}
      tolerations:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- with $templateData.pod.affinity }}
      affinity:
        {{- toYaml . | nindent 8 }}
      {{- end }}
      {{- if ne (len .Job.placementConstraints) 0 }}
      nodeSelector:
        {{- range .Job.placementConstraints }}
        {{ .name }}: {{ toYaml .value }}
        {{- end }}
      {{- end }}
      {{- $securityContext := $templateData.pod.defaultSecurityContext }}
      {{- if .Job.container.runAsUserId }}
        {{- $_ := set $securityContext "runAsUser" .Job.container.runAsUserId }}
      {{- end }}
      {{- if .Job.container.runAsGroupId }}
        {{- $_ := set $securityContext "runAsGroup" .Job.container.runAsGroupId }}
      {{- end }}
      {{- if .Job.container.supplementalGroupIds }}
        {{- $groupIds := list }}
        {{- range .Job.container.supplementalGroupIds }}
          {{- $groupIds = append $groupIds . }}
        {{- end }}
        {{- $_ := set $securityContext "supplementalGroups" (cat "[" ($groupIds | join ", ") "]") }}
        {{- $securityContext := mergeOverwrite $securityContext $templateData.pod.securityContext }}
      {{- end }}
      {{- if $securityContext }}
      securityContext:
        {{- range $key, $val := $securityContext }}
        {{ $key }}: {{ $val }}
        {{- end }}
      {{- end }}
      {{- if .Job.serviceAccountName }}
      serviceAccountName: {{ .Job.serviceAccountName }}
      {{- end }}
      {{- with $templateData.pod.imagePullSecrets }}
      imagePullSecrets: {{ toYaml . | nindent 12 }}
      {{- end }}
      initContainers:
        {{- with .Job.metadata.pod.initContainers }}
        {{- range . }}
        - {{ toYaml . | indent 10 | trimPrefix (repeat 10 " ") }}
        {{- end }}
        {{- end }}
        {{- with $templateData.pod.initContainers }}
          {{- range . }}
        - {{ toYaml . | indent 10 | trimPrefix (repeat 10 " ") }}
          {{- end }}
        {{- end }}
      containers:
        - name: rs-launcher-container
          image: {{ toYaml .Job.container.image }}
          {{- with $templateData.pod.imagePullPolicy }}
          imagePullPolicy: {{- . | nindent 12 }}
          {{- end }}
          {{- $isShell := false }}
          {{- if .Job.command }}
          command: ['/bin/sh']
          {{- $isShell = true }}
          {{- else }}
          command: [{{ toYaml .Job.exe }}]
          {{- $isShell = false }}
          {{- end }}
          {{- if .Job.stdin }}
          stdin: true
          {{- else }}
          stdin: false
          {{- end }}
          stdinOnce: true
          {{- if .Job.workingDirectory }}
          workingDir: {{ toYaml .Job.workingDirectory }}
          {{- end }}
          {{- if or (ne (len .Job.args) 0) $isShell }}
          args:
            {{- if $isShell }}
            - '-c'
            {{- if ne (len .Job.args) 0 }}
            - {{ .Job.args | join " " | cat .Job.command | toYaml | indent 12 | trimPrefix (repeat 12 " ") }}
            {{- else }}
            - {{ .Job.command | toYaml | indent 12 | trimPrefix (repeat 12 " ") }}
            {{- end }}
            {{- else }}
            {{- range .Job.args }}
            - {{ toYaml . | indent 12 | trimPrefix (repeat 12 " ") }}
            {{- end }}
            {{- end }}
          {{- end }}
          {{- $secrets := list }}
          {{- range .Job.config }}
            {{- if eq .name "secret" }}
              {{- $packedSecret := .value }}
              {{- $secret := dict }}
              {{- $_ := set $secret "secret" (splitList ":" $packedSecret | first) }}
              {{- $_ := set $secret "key" (slice (splitList ":" $packedSecret) 1 2 | first) }}
              {{- $_ := set $secret "name" (splitList ":" $packedSecret | last) }}
              {{- $secrets = append $secrets $secret }}
            {{- end }}
          {{- end }}
          {{- if or (ne (len .Job.environment) 0) (ne (len $secrets) 0) }}
          env:
            {{- range .Job.environment }}
            - name: {{ toYaml .name | indent 14 | trimPrefix (repeat 14 " ") }}
              value: {{ toYaml .value | indent 14 | trimPrefix (repeat 14 " ") }}
            {{- end }}
            {{- range $secrets }}
            - name: {{ get . "name"}}
              valueFrom:
                secretKeyRef:
                  name: {{ get . "secret" }}
                  key: {{ get . "key" }}
            {{- end }}
          {{- end }}
          {{- $exposedPorts := list }}
          {{- range .Job.exposedPorts }}
            {{- if .publishedPort }}
              {{- $exposedPorts = append $exposedPorts . }}
            {{- end }}
          {{- end }}
          {{- with $templateData.pod.containerSecurityContext }}
          securityContext:
            {{- toYaml . | nindent 12 }}
          {{- end }}
          {{- if ne (len $exposedPorts) 0 }}
          ports:
            {{- range $exposedPorts }}
            - containerPort: {{ .targetPort }}
              hostPort: {{ .publishedPort }}
            {{- end }}
          {{- end }}
          {{- $limits := dict }}
          {{- $requests := dict }}
          {{- range .Job.resourceLimits }}
            {{- if eq .type "cpuCount" }}
              {{- $_ := set $limits "cpu" .value }}
            {{- else if eq .type "CPU Request" }}
              {{- $_ := set $requests "cpu" .value }}
            {{- else if eq .type "memory" }}
              {{- $_ := set $limits "memory" (printf "%s%s" .value "M") }}
            {{- else if eq .type "Memory Request" }}
              {{- $_ := set $requests "memory" (printf "%s%s" .value "M") }}
            {{- else if eq .type "NVIDIA GPUs" }}
              {{- $val := float64 .value }}
              {{- if ne $val 0.0 }}
                {{- $_ := set $limits "nvidia.com/gpu" $val }}
              {{- end }}
            {{- else if eq .type "AMD GPUs" }}
              {{- $val := float64 .value }}
              {{- if ne $val 0.0 }}
                {{- $_ := set $limits "amd.com/gpu" $val }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if any (ne (len $requests) 0) (ne (len $limits) 0) }}
          resources:
            {{- if ne (len $requests) 0 }}
            requests:
              {{- range $key, $val := $requests }}
              {{ $key }}: {{ toYaml $val }}
              {{- end }}
            {{- end }}
            {{- if ne (len $limits) 0 }}
            limits:
              {{- range $key, $val := $limits }}
              {{ $key }}: {{ toYaml $val }}
              {{- end }}
            {{- end }}
          {{- end }}
          {{- if or (ne (len .Job.volumes) 0) (ne (len $templateData.pod.volumeMounts) 0) }}
          volumeMounts:
            {{- range .Job.volumeMounts }}
            - {{ nindent 14 (toYaml .) | trim -}}
            {{- end }}
            {{- range $templateData.pod.volumeMounts }}
            - {{ nindent 14 (toYaml .) | trim -}}
            {{- end }}
          {{- end }}
        {{- with $templateData.pod.extraContainers }}
          {{- toYaml . | nindent 8 }}
        {{- end }}
